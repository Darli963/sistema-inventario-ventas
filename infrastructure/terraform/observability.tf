# Observabilidad: CloudWatch Logs, Métricas, Dashboard y Grafana

# Variables opcionales
variable "alb_load_balancer_arn" {
  description = "ARN del ALB para métricas (opcional). Si se define, se creará la alarma de 5xx y se incluirá en el dashboard."
  type        = string
  default     = ""
}

variable "enable_grafana" {
  description = "Habilita la creación de Amazon Managed Grafana y su API key."
  type        = bool
  default     = false
}

# Derivar el nombre de dimensión para ALB (LoadBalancer)
locals {
  alb_dimension_name = var.alb_load_balancer_arn != "" ? regexreplace(var.alb_load_balancer_arn, "arn:aws:elasticloadbalancing:[^:]+:[^:]+:loadbalancer/", "") : "app/${local.prefix}-${var.environment}-alb"

  dashboard_metrics = var.alb_load_balancer_arn != "" ? [
    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.rds_primary.id],
    ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_dimension_name]
    ] : [
    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.rds_primary.id]
  ]
}

# 1️⃣ CloudWatch Log Groups
# Log group para Lambdas (nota: cada Lambda crea su propio log group, este sirve para búsquedas con prefijo)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.prefix}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 14
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-lambda-logs"
    }
  )
}

# Log group para ALB (solo métrico; ALB access logs van a S3. Este grupo puede servir para aplicaciones relacionadas al ALB.)
resource "aws_cloudwatch_log_group" "alb_logs" {
  count             = var.alb_load_balancer_arn != "" ? 1 : 0
  name              = "/aws/elasticloadbalancing/${local.prefix}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-alb-logs"
    }
  )
}

# 2️⃣ Métricas y Alarmas
# Alarma para RDS: CPU alta
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.prefix}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alerta cuando la CPU del RDS excede el 80%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_primary.id
  }

  alarm_actions = []

  tags = local.common_tags
}

# Alarma opcional para ALB: errores 5xx
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.alb_load_balancer_arn != "" ? 1 : 0
  alarm_name          = "${local.prefix}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alerta cuando hay más de 5 errores 5xx en 5 min"

  dimensions = {
    LoadBalancer = local.alb_dimension_name
  }

  alarm_actions = []

  tags = local.common_tags
}

# 3️⃣ CloudWatch Dashboard (visualización general)
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "${local.prefix}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = local.dashboard_metrics
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "RDS y ALB - Métricas principales"
        }
      }
    ]
  })
}

# B. Grafana (Integrado con CloudWatch)
resource "aws_grafana_workspace" "main" {
  count                    = var.enable_grafana ? 1 : 0
  name                     = "${local.prefix}-${var.environment}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH"]

  tags = local.common_tags
}

resource "aws_grafana_workspace_api_key" "grafana_api" {
  count           = var.enable_grafana ? 1 : 0
  key_name        = "grafana-api-access"
  key_role        = "ADMIN"
  seconds_to_live = 3600
  workspace_id    = aws_grafana_workspace.main[0].id
}

# Outputs útiles
output "cloudwatch_dashboard_name" {
  description = "Nombre del dashboard principal de CloudWatch"
  value       = aws_cloudwatch_dashboard.main_dashboard.dashboard_name
}

output "lambda_log_group_name" {
  description = "Log group base para Lambdas"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "alb_log_group_name" {
  description = "Log group base para ALB (para usos relacionados)"
  value       = length(aws_cloudwatch_log_group.alb_logs) > 0 ? aws_cloudwatch_log_group.alb_logs[0].name : ""
}

output "grafana_workspace_endpoint" {
  description = "Endpoint del workspace de Grafana (si está habilitado)"
  value       = length(aws_grafana_workspace.main) > 0 ? aws_grafana_workspace.main[0].endpoint : ""
}
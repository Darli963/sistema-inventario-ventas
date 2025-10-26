# Observabilidad CloudFront/S3: CloudWatch Logs, Alarma 5xx y Dashboard

# 1️⃣ CloudWatch Log Groups
# Grupo de logs para CloudFront (placeholder para futuros procesamientos)
resource "aws_cloudwatch_log_group" "cloudfront_logs" {
  name              = "/aws/${local.prefix}/${var.environment}/cloudfront"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-cloudfront-logs"
  })
}

# Grupo de logs para S3 (placeholder; S3 Access Logs van a S3, no CloudWatch)
resource "aws_cloudwatch_log_group" "s3_logs" {
  name              = "/aws/${local.prefix}/${var.environment}/s3"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-s3-logs"
  })
}

# 2️⃣ Métricas y Alarmas (CloudFront 5xx Error Rate)
resource "aws_sns_topic" "observability_alerts" {
  name              = "${local.prefix}-${var.environment}-observability-alerts"
  kms_master_key_id = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-observability-alerts"
    Type = "Alerts"
  })
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "${local.prefix}-${var.environment}-cloudfront-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alerta cuando 5xxErrorRate supera 1% en 5 minutos (Global)"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.frontend_distribution.id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# 3️⃣ CloudWatch Dashboard (CloudFront Global)
resource "aws_cloudwatch_dashboard" "market_dashboard" {
  dashboard_name = "MarketCarmensita-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.frontend_distribution.id],
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", aws_cloudfront_distribution.frontend_distribution.id],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", aws_cloudfront_distribution.frontend_distribution.id]
          ],
          period = 300,
          stat   = "Average",
          title  = "CloudFront Requests and Error Rates",
          region = var.aws_region
        }
      }
    ]
  })
}

# 4️⃣ Outputs (evitar colisiones con outputs existentes)
output "market_dashboard_name" {
  description = "Nombre del dashboard de CloudFront Global"
  value       = aws_cloudwatch_dashboard.market_dashboard.dashboard_name
}

output "cloudwatch_log_groups_cloudfront_s3" {
  description = "Grupos de logs de CloudWatch para CloudFront y S3"
  value = [
    aws_cloudwatch_log_group.cloudfront_logs.name,
    aws_cloudwatch_log_group.s3_logs.name
  ]
}

output "cloudfront_5xx_alarm_name" {
  description = "Nombre de la alarma de CloudFront 5xx"
  value       = aws_cloudwatch_metric_alarm.cloudfront_5xx_errors.alarm_name
}

# Log groups para RDS (error/general/slowquery) con retención y cifrado
resource "aws_cloudwatch_log_group" "rds_error_logs" {
  name              = "/aws/rds/instance/${aws_db_instance.rds_primary.id}/error"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-rds-error-logs" })
}

resource "aws_cloudwatch_log_group" "rds_general_logs" {
  name              = "/aws/rds/instance/${aws_db_instance.rds_primary.id}/general"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-rds-general-logs" })
}

resource "aws_cloudwatch_log_group" "rds_slowquery_logs" {
  name              = "/aws/rds/instance/${aws_db_instance.rds_primary.id}/slowquery"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-rds-slowquery-logs" })
}
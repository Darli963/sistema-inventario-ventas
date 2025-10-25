# Monitoreo: Logs ya configurados en lambdas.tf y observability*.tf
# Aquí definimos alarmas para Lambdas y métricas adicionales de RDS.

locals {
  lambda_alarm_period    = 300
  lambda_error_threshold = 1
}

# Alarma por errores en cada Lambda (Errors > 0 en 5 min)
resource "aws_cloudwatch_metric_alarm" "lambda_errors_productos" {
  alarm_name          = "${local.prefix}-${var.environment}-lambda-productos-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = local.lambda_alarm_period
  statistic           = "Sum"
  threshold           = local.lambda_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.productos_lambda.function_name
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_inventario" {
  alarm_name          = "${local.prefix}-${var.environment}-lambda-inventario-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = local.lambda_alarm_period
  statistic           = "Sum"
  threshold           = local.lambda_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.inventario_lambda.function_name
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_ventas" {
  alarm_name          = "${local.prefix}-${var.environment}-lambda-ventas-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = local.lambda_alarm_period
  statistic           = "Sum"
  threshold           = local.lambda_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.ventas_lambda.function_name
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_reportes" {
  alarm_name          = "${local.prefix}-${var.environment}-lambda-reportes-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = local.lambda_alarm_period
  statistic           = "Sum"
  threshold           = local.lambda_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.reportes_lambda.function_name
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# RDS: métricas adicionales
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.prefix}-${var.environment}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.environment == "prod" ? 10 * 1024 * 1024 * 1024 : 2 * 1024 * 1024 * 1024
  alarm_description   = "Alerta cuando el espacio libre del RDS es bajo"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_primary.id
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${local.prefix}-${var.environment}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.environment == "prod" ? 150 : 50
  alarm_description   = "Alerta cuando las conexiones al RDS superan el umbral"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_primary.id
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# Outputs útiles
output "lambda_error_alarm_names" {
  description = "Alarmas de errores por Lambda"
  value = [
    aws_cloudwatch_metric_alarm.lambda_errors_productos.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors_inventario.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors_ventas.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors_reportes.alarm_name
  ]
}
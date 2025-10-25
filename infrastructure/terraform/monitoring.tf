# Monitoreo: Alarmas para Lambdas, RDS, API Gateway y CloudFront

# Alarmas para Lambdas (Errors, Throttles, Duration)
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each            = local.lambda_names
  alarm_name          = "${local.prefix}-${var.environment}-${each.key}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Errores detectados en Lambda ${each.key}"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each            = local.lambda_names
  alarm_name          = "${local.prefix}-${var.environment}-${each.key}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "Throttles detectados en Lambda ${each.key}"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each            = local.lambda_names
  alarm_name          = "${local.prefix}-${var.environment}-${each.key}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 5000
  treat_missing_data  = "notBreaching"
  alarm_description   = "Duración promedio alta en Lambda ${each.key} (>5s)"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# Métrica y alarma de 5xx de API Gateway basada en logs JSON
resource "aws_cloudwatch_log_metric_filter" "api_5xx_filter" {
  name           = "${local.prefix}-${var.environment}-api-5xx-filter"
  log_group_name = aws_cloudwatch_log_group.api_gateway_logs.name
  pattern        = "{ $.status >= 500 }"

  metric_transformation {
    name      = "Api5xxCount"
    namespace = "Custom/ApiGateway"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_alarm" {
  alarm_name          = "${local.prefix}-${var.environment}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.api_5xx_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.api_5xx_filter.metric_transformation[0].namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Errores 5xx detectados en API Gateway"

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# Alarmas adicionales para RDS
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.prefix}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GB
  treat_missing_data  = "notBreaching"
  alarm_description   = "Espacio libre bajo en RDS (<2GB)"

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
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  treat_missing_data  = "notBreaching"
  alarm_description   = "Conexiones de base de datos altas en RDS (>100)"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_primary.id
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}

# Alarma CloudFront 4xx (complementa la de 5xx)
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "${local.prefix}-${var.environment}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alerta cuando 4xxErrorRate supera 5% en 5 minutos (Global)"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.frontend_distribution.id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.observability_alerts.arn]
  ok_actions    = [aws_sns_topic.observability_alerts.arn]

  tags = local.common_tags
}
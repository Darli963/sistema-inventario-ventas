# DLQ (SQS) y configuración de reintentos para Lambdas

# Productos
resource "aws_sqs_queue" "productos_dlq" {
  name                       = "${local.prefix}-${var.environment}-dlq-productos"
  visibility_timeout_seconds = 300
  message_retention_seconds  = var.environment == "prod" ? 1209600 : 345600
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-dlq-productos", Type = "DLQ" })
}

resource "aws_sqs_queue_policy" "productos_dlq_policy" {
  queue_url = aws_sqs_queue.productos_dlq.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaSendMessage",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sqs:SendMessage"],
        Resource  = aws_sqs_queue.productos_dlq.arn,
        Condition = { ArnEquals = { "aws:SourceArn" = aws_lambda_function.productos_lambda.arn } }
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "productos_invoke_config" {
  function_name                = aws_lambda_function.productos_lambda.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600
  destination_config {
    on_failure {
      destination = aws_sqs_queue.productos_dlq.arn
    }
  }
  depends_on = [aws_sqs_queue_policy.productos_dlq_policy]
}

# Inventario
resource "aws_sqs_queue" "inventario_dlq" {
  name                       = "${local.prefix}-${var.environment}-dlq-inventario"
  visibility_timeout_seconds = 300
  message_retention_seconds  = var.environment == "prod" ? 1209600 : 345600
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-dlq-inventario", Type = "DLQ" })
}

resource "aws_sqs_queue_policy" "inventario_dlq_policy" {
  queue_url = aws_sqs_queue.inventario_dlq.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaSendMessage",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sqs:SendMessage"],
        Resource  = aws_sqs_queue.inventario_dlq.arn,
        Condition = { ArnEquals = { "aws:SourceArn" = aws_lambda_function.inventario_lambda.arn } }
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "inventario_invoke_config" {
  function_name                = aws_lambda_function.inventario_lambda.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600
  destination_config {
    on_failure {
      destination = aws_sqs_queue.inventario_dlq.arn
    }
  }
  depends_on = [aws_sqs_queue_policy.inventario_dlq_policy]
}

# Ventas
resource "aws_sqs_queue" "ventas_dlq" {
  name                       = "${local.prefix}-${var.environment}-dlq-ventas"
  visibility_timeout_seconds = 300
  message_retention_seconds  = var.environment == "prod" ? 1209600 : 345600
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-dlq-ventas", Type = "DLQ" })
}

resource "aws_sqs_queue_policy" "ventas_dlq_policy" {
  queue_url = aws_sqs_queue.ventas_dlq.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaSendMessage",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sqs:SendMessage"],
        Resource  = aws_sqs_queue.ventas_dlq.arn,
        Condition = { ArnEquals = { "aws:SourceArn" = aws_lambda_function.ventas_lambda.arn } }
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "ventas_invoke_config" {
  function_name                = aws_lambda_function.ventas_lambda.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600
  destination_config {
    on_failure {
      destination = aws_sqs_queue.ventas_dlq.arn
    }
  }
  depends_on = [aws_sqs_queue_policy.ventas_dlq_policy]
}

# Reportes
resource "aws_sqs_queue" "reportes_dlq" {
  name                       = "${local.prefix}-${var.environment}-dlq-reportes"
  visibility_timeout_seconds = 300
  message_retention_seconds  = var.environment == "prod" ? 1209600 : 345600
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-dlq-reportes", Type = "DLQ" })
}

resource "aws_sqs_queue_policy" "reportes_dlq_policy" {
  queue_url = aws_sqs_queue.reportes_dlq.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaSendMessage",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sqs:SendMessage"],
        Resource  = aws_sqs_queue.reportes_dlq.arn,
        Condition = { ArnEquals = { "aws:SourceArn" = aws_lambda_function.reportes_lambda.arn } }
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "reportes_invoke_config" {
  function_name                = aws_lambda_function.reportes_lambda.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600
  destination_config {
    on_failure {
      destination = aws_sqs_queue.reportes_dlq.arn
    }
  }
  depends_on = [aws_sqs_queue_policy.reportes_dlq_policy]
}

# Health (por consistencia)
resource "aws_sqs_queue" "health_dlq" {
  name                       = "${local.prefix}-${var.environment}-dlq-health"
  visibility_timeout_seconds = 60
  message_retention_seconds  = var.environment == "prod" ? 604800 : 172800
  sqs_managed_sse_enabled    = true

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-dlq-health", Type = "DLQ" })
}

resource "aws_sqs_queue_policy" "health_dlq_policy" {
  queue_url = aws_sqs_queue.health_dlq.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaSendMessage",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = ["sqs:SendMessage"],
        Resource  = aws_sqs_queue.health_dlq.arn,
        Condition = { ArnEquals = { "aws:SourceArn" = aws_lambda_function.health_lambda.arn } }
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "health_invoke_config" {
  function_name                = aws_lambda_function.health_lambda.function_name
  maximum_retry_attempts       = 1
  maximum_event_age_in_seconds = 900
  destination_config {
    on_failure {
      destination = aws_sqs_queue.health_dlq.arn
    }
  }
  depends_on = [aws_sqs_queue_policy.health_dlq_policy]
}
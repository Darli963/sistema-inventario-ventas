# Lambdas para módulos del backend y empaquetado del código

locals {
  lambda_names = {
    productos  = "${local.prefix}-${var.environment}-productos-lambda"
    inventario = "${local.prefix}-${var.environment}-inventario-lambda"
    ventas     = "${local.prefix}-${var.environment}-ventas-lambda"
    reportes   = "${local.prefix}-${var.environment}-reportes-lambda"
    health     = "${local.prefix}-${var.environment}-health-lambda"
  }
}

# Empaquetar el backend completo para incluir utils y handlers
# Esto crea un zip reutilizable para todas las lambdas
data "archive_file" "backend_zip" {
  type        = "zip"
  source_dir  = abspath("${path.module}/../../src/backend")
  output_path = "${path.module}/build/backend.zip"
}

# Log groups por función para controlar retención
resource "aws_cloudwatch_log_group" "lambda_logs_productos" {
  name              = "/aws/lambda/${local.lambda_names.productos}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.kms_logs.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs_inventario" {
  name              = "/aws/lambda/${local.lambda_names.inventario}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.kms_logs.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs_ventas" {
  name              = "/aws/lambda/${local.lambda_names.ventas}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.kms_logs.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs_reportes" {
  name              = "/aws/lambda/${local.lambda_names.reportes}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.kms_logs.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs_health" {
  name              = "/aws/lambda/${local.lambda_names.health}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.kms_logs.arn
}

# Función Lambda: Productos
resource "aws_lambda_function" "productos_lambda" {
  function_name = local.lambda_names.productos
  description   = "CRUD de productos"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role_productos.arn
  handler       = "lambdas/productos/handler.handler"

  filename         = data.archive_file.backend_zip.output_path
  source_code_hash = data.archive_file.backend_zip.output_base64sha256

  memory_size = 512
  timeout     = 30
  ephemeral_storage {
    size = var.environment == "prod" ? 10240 : 512
  }

  environment {
    variables = {
      DB_SECRET_ARN     = aws_db_instance.rds_primary.master_user_secret[0].secret_arn
      DB_HOST           = aws_db_proxy.db_proxy.endpoint
      DB_PORT           = aws_db_instance.rds_primary.port
      DB_NAME           = aws_db_instance.rds_primary.db_name
      S3_PRIVATE_BUCKET = aws_s3_bucket.private_bucket.bucket
      NODE_ENV          = var.environment
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.common_tags, { Module = "productos" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_attach_productos,
    aws_iam_role_policy_attachment.lambda_vpc_attach_productos,
    aws_iam_role_policy_attachment.lambda_secrets_attach_productos,
    aws_iam_role_policy_attachment.lambda_s3_attach_productos,
    aws_iam_role_policy_attachment.lambda_kms_s3_attach_productos,
    aws_iam_role_policy_attachment.lambda_xray_attach_productos
  ]
}

# Función Lambda: Inventario
resource "aws_lambda_function" "inventario_lambda" {
  function_name = local.lambda_names.inventario
  description   = "Gestión de inventario"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role_inventario.arn
  handler       = "lambdas/inventario/handler.handler"

  filename         = data.archive_file.backend_zip.output_path
  source_code_hash = data.archive_file.backend_zip.output_base64sha256

  memory_size = 512
  timeout     = 30
  ephemeral_storage {
    size = var.environment == "prod" ? 10240 : 512
  }

  environment {
    variables = {
      DB_SECRET_ARN     = aws_db_instance.rds_primary.master_user_secret[0].secret_arn
      DB_HOST           = aws_db_proxy.db_proxy.endpoint
      DB_PORT           = aws_db_instance.rds_primary.port
      DB_NAME           = aws_db_instance.rds_primary.db_name
      S3_PRIVATE_BUCKET = aws_s3_bucket.private_bucket.bucket
      NODE_ENV          = var.environment
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.common_tags, { Module = "inventario" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_attach_inventario,
    aws_iam_role_policy_attachment.lambda_vpc_attach_inventario,
    aws_iam_role_policy_attachment.lambda_secrets_attach_inventario,
    aws_iam_role_policy_attachment.lambda_s3_attach_inventario,
    aws_iam_role_policy_attachment.lambda_kms_s3_attach_inventario,
    aws_iam_role_policy_attachment.lambda_xray_attach_inventario
  ]
}

# Función Lambda: Ventas
resource "aws_lambda_function" "ventas_lambda" {
  function_name = local.lambda_names.ventas
  description   = "Registro de ventas"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role_ventas.arn
  handler       = "lambdas/ventas/handler.handler"

  filename         = data.archive_file.backend_zip.output_path
  source_code_hash = data.archive_file.backend_zip.output_base64sha256

  memory_size = 512
  timeout     = 30
  ephemeral_storage {
    size = var.environment == "prod" ? 10240 : 512
  }

  environment {
    variables = {
      DB_SECRET_ARN     = aws_db_instance.rds_primary.master_user_secret[0].secret_arn
      DB_HOST           = aws_db_proxy.db_proxy.endpoint
      DB_PORT           = aws_db_instance.rds_primary.port
      DB_NAME           = aws_db_instance.rds_primary.db_name
      S3_PRIVATE_BUCKET = aws_s3_bucket.private_bucket.bucket
      NODE_ENV          = var.environment
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.common_tags, { Module = "ventas" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_attach_ventas,
    aws_iam_role_policy_attachment.lambda_vpc_attach_ventas,
    aws_iam_role_policy_attachment.lambda_secrets_attach_ventas,
    aws_iam_role_policy_attachment.lambda_s3_attach_ventas,
    aws_iam_role_policy_attachment.lambda_kms_s3_attach_ventas,
    aws_iam_role_policy_attachment.lambda_xray_attach_ventas
  ]
}

# Función Lambda: Reportes
resource "aws_lambda_function" "reportes_lambda" {
  function_name = local.lambda_names.reportes
  description   = "Consultas de reportes"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role_reportes.arn
  handler       = "lambdas/reportes/handler.handler"

  filename         = data.archive_file.backend_zip.output_path
  source_code_hash = data.archive_file.backend_zip.output_base64sha256

  memory_size = 512
  timeout     = 30
  ephemeral_storage {
    size = var.environment == "prod" ? 10240 : 512
  }

  environment {
    variables = {
      DB_SECRET_ARN     = aws_db_instance.rds_primary.master_user_secret[0].secret_arn
      DB_HOST           = aws_db_proxy.db_proxy.endpoint
      DB_PORT           = aws_db_instance.rds_primary.port
      DB_NAME           = aws_db_instance.rds_primary.db_name
      S3_PRIVATE_BUCKET = aws_s3_bucket.private_bucket.bucket
      NODE_ENV          = var.environment
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.common_tags, { Module = "reportes" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_attach_reportes,
    aws_iam_role_policy_attachment.lambda_vpc_attach_reportes,
    aws_iam_role_policy_attachment.lambda_secrets_attach_reportes,
    aws_iam_role_policy_attachment.lambda_s3_attach_reportes,
    aws_iam_role_policy_attachment.lambda_kms_s3_attach_reportes,
    aws_iam_role_policy_attachment.lambda_xray_attach_reportes
  ]
}

# Función Lambda: Health
resource "aws_lambda_function" "health_lambda" {
  function_name = local.lambda_names.health
  description   = "Health check simple"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role_health.arn
  handler       = "lambdas/health/handler.handler"

  filename         = data.archive_file.backend_zip.output_path
  source_code_hash = data.archive_file.backend_zip.output_base64sha256

  memory_size = 128
  timeout     = 5

  environment {
    variables = {
      NODE_ENV = var.environment
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(local.common_tags, { Module = "health" })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_attach_health,
    aws_iam_role_policy_attachment.lambda_xray_attach_health
  ]
}

# Permisos para invocación desde API Gateway HTTP v2
resource "aws_lambda_permission" "apigw_productos" {
  statement_id  = "AllowInvokeByAPIGatewayProductos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.productos_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_inventario" {
  statement_id  = "AllowInvokeByAPIGatewayInventario"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventario_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_ventas" {
  statement_id  = "AllowInvokeByAPIGatewayVentas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ventas_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_reportes" {
  statement_id  = "AllowInvokeByAPIGatewayReportes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reportes_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_health" {
  statement_id  = "AllowInvokeByAPIGatewayHealth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}
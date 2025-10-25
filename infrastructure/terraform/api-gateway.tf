# Configuración de API Gateway v2 HTTP para el sistema de inventario y ventas
# Versión del proveedor AWS: ~> 5.0
# API Gateway v2 (HTTP API) - Más eficiente y económico que REST API

# API Gateway HTTP
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${local.prefix}-${var.environment}-api"
  protocol_type = "HTTP"
  version       = "1.0"
  description   = "API Gateway para sistema de inventario y ventas"

  # Configuración de CORS
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins     = var.environment == "prod" ? ["https://${var.domain_name != null && trimspace(var.domain_name) != "" ? var.domain_name : "localhost"}"] : ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }


  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-api"
      Type = "API"
    }
  )
}

# Stage para el API Gateway
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = var.environment
  auto_deploy = true
  description = "Stage ${var.environment} para API Gateway"

  # Configuración de logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
    })
  }

  # Configuración de throttling por stage
  default_route_settings {
    throttling_burst_limit = var.environment == "prod" ? 1000 : 200
    throttling_rate_limit  = var.environment == "prod" ? 500 : 100
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-api-stage"
    }
  )
}

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${local.prefix}-${var.environment}-api"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.data_key.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-api-logs"
    }
  )
}

# Dominio personalizado (opcional para producción)
resource "aws_apigatewayv2_domain_name" "api_domain" {
  count       = var.environment == "prod" && var.api_domain_name != "" ? 1 : 0
  domain_name = var.api_domain_name

  domain_name_configuration {
    certificate_arn = var.api_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-api-domain"
    }
  )
}

# Mapeo del dominio al stage
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  count       = var.environment == "prod" && var.api_domain_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.api_gateway.id
  domain_name = aws_apigatewayv2_domain_name.api_domain[0].id
  stage       = aws_apigatewayv2_stage.api_stage.id
}

# Autorización JWT (preparado para futuro uso)
resource "aws_apigatewayv2_authorizer" "jwt_authorizer" {
  count            = var.environment == "prod" ? 1 : 0
  api_id           = aws_apigatewayv2_api.api_gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.prefix}-${var.environment}-jwt-authorizer"

  jwt_configuration {
    audience = [var.jwt_audience]
    issuer   = var.jwt_issuer
  }
}

# Integración de ejemplo para health check
# Integración Lambda para health
resource "aws_apigatewayv2_integration" "health_lambda" {
  api_id                 = aws_apigatewayv2_api.api_gateway.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
  description            = "Integración Lambda Health"
  integration_uri        = aws_lambda_function.health_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "health_check" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health_lambda.id}"
}

# Integraciones Lambda (AWS_PROXY) para módulos
resource "aws_apigatewayv2_integration" "productos_lambda" {
  api_id                  = aws_apigatewayv2_api.api_gateway.id
  integration_type        = "AWS_PROXY"
  integration_method      = "POST"
  payload_format_version  = "2.0"
  description             = "Integración Lambda Productos"
  integration_uri         = aws_lambda_function.productos_lambda.invoke_arn
}

resource "aws_apigatewayv2_integration" "inventario_lambda" {
  api_id                  = aws_apigatewayv2_api.api_gateway.id
  integration_type        = "AWS_PROXY"
  integration_method      = "POST"
  payload_format_version  = "2.0"
  description             = "Integración Lambda Inventario"
  integration_uri         = aws_lambda_function.inventario_lambda.invoke_arn
}

resource "aws_apigatewayv2_integration" "ventas_lambda" {
  api_id                  = aws_apigatewayv2_api.api_gateway.id
  integration_type        = "AWS_PROXY"
  integration_method      = "POST"
  payload_format_version  = "2.0"
  description             = "Integración Lambda Ventas"
  integration_uri         = aws_lambda_function.ventas_lambda.invoke_arn
}

resource "aws_apigatewayv2_integration" "reportes_lambda" {
  api_id                  = aws_apigatewayv2_api.api_gateway.id
  integration_type        = "AWS_PROXY"
  integration_method      = "POST"
  payload_format_version  = "2.0"
  description             = "Integración Lambda Reportes"
  integration_uri         = aws_lambda_function.reportes_lambda.invoke_arn
}

# Rutas y métodos por módulo
# Productos
resource "aws_apigatewayv2_route" "productos_get" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_lambda.id}"
}
resource "aws_apigatewayv2_route" "productos_post" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_lambda.id}"
}
resource "aws_apigatewayv2_route" "productos_put" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "PUT /productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_lambda.id}"
}
resource "aws_apigatewayv2_route" "productos_delete" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "DELETE /productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_lambda.id}"
}

# Inventario
resource "aws_apigatewayv2_route" "inventario_get" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /inventario"
  target    = "integrations/${aws_apigatewayv2_integration.inventario_lambda.id}"
}
resource "aws_apigatewayv2_route" "inventario_post" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /inventario"
  target    = "integrations/${aws_apigatewayv2_integration.inventario_lambda.id}"
}
resource "aws_apigatewayv2_route" "inventario_put" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "PUT /inventario"
  target    = "integrations/${aws_apigatewayv2_integration.inventario_lambda.id}"
}

# Ventas
resource "aws_apigatewayv2_route" "ventas_get" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /ventas"
  target    = "integrations/${aws_apigatewayv2_integration.ventas_lambda.id}"
}
resource "aws_apigatewayv2_route" "ventas_post" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /ventas"
  target    = "integrations/${aws_apigatewayv2_integration.ventas_lambda.id}"
}

# Reportes
resource "aws_apigatewayv2_route" "reportes_get" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /reportes"
  target    = "integrations/${aws_apigatewayv2_integration.reportes_lambda.id}"
}
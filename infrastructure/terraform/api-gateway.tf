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
    allow_origins     = var.environment == "prod" ? ["https://${aws_cloudfront_distribution.frontend_cdn.domain_name}"] : ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }

  # Configuración de throttling
  throttle_config {
    burst_limit = var.environment == "prod" ? 2000 : 500
    rate_limit  = var.environment == "prod" ? 1000 : 200
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
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
      responseTime  = "$context.responseTime"
      error         = "$context.error.message"
      integrationError = "$context.integration.error"
    })
  }

  # Configuración de throttling por stage
  throttle_settings {
    burst_limit = var.environment == "prod" ? 1000 : 200
    rate_limit  = var.environment == "prod" ? 500 : 100
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
resource "aws_apigatewayv2_integration" "health_check" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "MOCK"
  description      = "Health check endpoint"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }

  template_selection_expression = "200"
}

# Ruta para health check
resource "aws_apigatewayv2_route" "health_check" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health_check.id}"
}

# Response para health check
resource "aws_apigatewayv2_integration_response" "health_check" {
  api_id                   = aws_apigatewayv2_api.api_gateway.id
  integration_id           = aws_apigatewayv2_integration.health_check.id
  integration_response_key = "/200/"

  response_templates = {
    "application/json" = jsonencode({
      status    = "healthy"
      timestamp = "$context.requestTime"
      version   = "1.0"
    })
  }
}

# Route response para health check
resource "aws_apigatewayv2_route_response" "health_check" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_id           = aws_apigatewayv2_route.health_check.id
  route_response_key = "$default"
}
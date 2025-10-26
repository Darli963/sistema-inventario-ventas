# DNS y TLS para el frontend (opcional)
# - Crea certificado ACM en us-east-1 para CloudFront cuando se solicita
# - Crea alias en Route53 apuntando a la distribución de CloudFront

# Certificado ACM para el dominio del frontend (us-east-1)
resource "aws_acm_certificate" "app_cert" {
  count    = var.create_app_certificate && var.domain_name != null && trimspace(var.domain_name) != "" ? 1 : 0
  provider = aws.global

  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-app-certificate"
    Type = "TLS"
  })
}

# Registros DNS para validación del certificado (uno por cada DVO)
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_app_certificate && var.domain_name != null && trimspace(var.domain_name) != "" && var.hosted_zone_id != "" ? { for dvo in aws_acm_certificate.app_cert[0].domain_validation_options : dvo.domain_name => {
    name  = dvo.resource_record_name
    type  = dvo.resource_record_type
    value = dvo.resource_record_value
  } } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

# Validación del certificado ACM
resource "aws_acm_certificate_validation" "app_cert_validation" {
  count                   = var.create_app_certificate && var.domain_name != null && trimspace(var.domain_name) != "" ? 1 : 0
  provider                = aws.global
  certificate_arn         = aws_acm_certificate.app_cert[0].arn
  validation_record_fqdns = var.hosted_zone_id != "" ? [for rec in aws_route53_record.cert_validation : rec.fqdn] : []
}

# Alias A/AAAA para el dominio del frontend apuntando a CloudFront
resource "aws_route53_record" "app_alias" {
  count   = var.domain_name != null && trimspace(var.domain_name) != "" && var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Alias A/AAAA para el dominio de la API (solo prod) apuntando a API Gateway
resource "aws_route53_record" "api_alias" {
  count   = var.environment == "prod" && var.api_domain_name != "" && var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
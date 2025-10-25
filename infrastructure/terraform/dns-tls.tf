# DNS y TLS: ACM y Route 53 para frontend (CloudFront) y API

# Zona de Route 53
data "aws_route53_zone" "primary" {
  name         = var.hosted_zone_name
  private_zone = false
}

locals {
  app_domain_enabled = var.domain_name != null && trimspace(var.domain_name) != ""
  api_domain_enabled = trimspace(var.api_domain_name) != ""
}

# Certificado ACM para CloudFront (us-east-1)
resource "aws_acm_certificate" "app_cert" {
  provider          = aws.us_east_1
  count             = local.app_domain_enabled ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-app-cert"
    Type = "TLS"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Registros DNS para validar el certificado de CloudFront
resource "aws_route53_record" "app_cert_validation" {
  for_each = local.app_domain_enabled ? { for dvo in aws_acm_certificate.app_cert[0].domain_validation_options : dvo.domain_name => {
    name  = dvo.resource_record_name
    type  = dvo.resource_record_type
    value = dvo.resource_record_value
  } } : {}

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "app_cert_validation" {
  provider                = aws.us_east_1
  count                   = local.app_domain_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.app_cert[0].arn
  validation_record_fqdns = [for rec in aws_route53_record.app_cert_validation : rec.fqdn]
}

# Alias A/AAAA hacia CloudFront para app.dominio
resource "aws_route53_record" "app_alias_A" {
  count   = local.app_domain_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_alias_AAAA" {
  count   = local.app_domain_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Certificado ACM regional para API (usando la región del provider principal)
resource "aws_acm_certificate" "api_cert" {
  count             = local.api_domain_enabled ? 1 : 0
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-api-cert"
    Type = "TLS"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Registros DNS para validar el certificado de la API
resource "aws_route53_record" "api_cert_validation" {
  for_each = local.api_domain_enabled ? { for dvo in aws_acm_certificate.api_cert[0].domain_validation_options : dvo.domain_name => {
    name  = dvo.resource_record_name
    type  = dvo.resource_record_type
    value = dvo.resource_record_value
  } } : {}

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  count                   = local.api_domain_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.api_cert[0].arn
  validation_record_fqdns = [for rec in aws_route53_record.api_cert_validation : rec.fqdn]
}

# Alias A/AAAA para api.dominio apuntando al dominio regional de API Gateway (si se crea dominio custom)
# Se crearán en api-gateway.tf junto al dominio custom. Aquí sólo dejamos los certificados y validación.
# Registros Alias para API Gateway custom domain
resource "aws_route53_record" "api_alias_A" {
  count   = local.api_domain_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_alias_AAAA" {
  count   = local.api_domain_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.api_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
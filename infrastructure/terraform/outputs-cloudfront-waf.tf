# Outputs para CloudFront y WAF
# Información importante para el despliegue y monitoreo

# CloudFront Distribution
output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.frontend_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.frontend_distribution.arn
}

output "cloudfront_domain_name" {
  description = "Nombre de dominio de CloudFront"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront para Route53"
  value       = aws_cloudfront_distribution.frontend_distribution.hosted_zone_id
}

output "cloudfront_status" {
  description = "Estado de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.frontend_distribution.status
}

# WAF v2
output "waf_web_acl_id" {
  description = "ID del Web ACL de WAF v2"
  value       = aws_wafv2_web_acl.frontend_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del Web ACL de WAF v2"
  value       = aws_wafv2_web_acl.frontend_waf.arn
}

output "waf_web_acl_name" {
  description = "Nombre del Web ACL de WAF v2"
  value       = aws_wafv2_web_acl.frontend_waf.name
}

# CloudFront Functions
output "cloudfront_function_security_headers_arn" {
  description = "ARN de la función de CloudFront para headers de seguridad"
  value       = aws_cloudfront_function.security_headers.arn
}

output "cloudfront_function_spa_routing_arn" {
  description = "ARN de la función de CloudFront para routing de SPA"
  value       = aws_cloudfront_function.spa_routing.arn
}

output "cloudfront_function_cache_control_arn" {
  description = "ARN de la función de CloudFront para control de cache"
  value       = aws_cloudfront_function.cache_control.arn
}

# Logging
output "waf_log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch para WAF"
  value       = aws_cloudwatch_log_group.waf_log_group.name
}

output "waf_log_group_arn" {
  description = "ARN del grupo de logs de CloudWatch para WAF"
  value       = aws_cloudwatch_log_group.waf_log_group.arn
}

# CloudFront Logs Bucket (solo en producción)
output "cloudfront_logs_bucket_name" {
  description = "Nombre del bucket de logs de CloudFront"
  value       = var.environment == "prod" ? aws_s3_bucket.cloudfront_logs[0].bucket : null
}

output "cloudfront_logs_bucket_arn" {
  description = "ARN del bucket de logs de CloudFront"
  value       = var.environment == "prod" ? aws_s3_bucket.cloudfront_logs[0].arn : null
}

# Alertas (solo en producción)
output "security_alerts_topic_arn" {
  description = "ARN del topic SNS para alertas de seguridad"
  value       = var.environment == "prod" ? aws_sns_topic.alerts[0].arn : null
}

# URLs importantes
output "frontend_url" {
  description = "URL del frontend a través de CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}

output "api_url" {
  description = "URL de la API a través de CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}/api"
}

# Información de configuración
output "waf_configuration_summary" {
  description = "Resumen de la configuración de WAF"
  value = {
    geo_blocking_enabled = var.enable_geo_blocking
    blocked_countries    = var.blocked_countries
    allowed_countries    = var.allowed_countries
    rate_limit          = var.environment == "prod" ? 2000 : 1000
    environment         = var.environment
  }
}
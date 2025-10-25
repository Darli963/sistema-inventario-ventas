# Outputs mínimos requeridos para CI/CD del frontend

output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.frontend_distribution.id
}

output "frontend_bucket_name" {
  description = "Nombre del bucket S3 público del frontend"
  value       = aws_s3_bucket.frontend_bucket.bucket
}

output "frontend_url" {
  description = "Dominio de CloudFront para el frontend"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}
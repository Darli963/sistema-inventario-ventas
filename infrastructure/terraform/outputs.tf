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

output "rds_primary_endpoint" {
  description = "Endpoint de la base de datos RDS primaria"
  value       = aws_db_instance.rds_primary.address
}

output "rds_replica_endpoint" {
  description = "Endpoint de la réplica RDS (solo prod)"
  value       = try(aws_db_instance.rds_replica[0].address, null)
}

output "rds_port" {
  description = "Puerto de la base de datos RDS"
  value       = aws_db_instance.rds_primary.port
}
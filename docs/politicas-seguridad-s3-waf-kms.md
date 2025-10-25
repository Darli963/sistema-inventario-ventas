# Políticas de Seguridad: S3, WAF y KMS

Resumen de controles implementados en Terraform y cómo auditarlos.

## S3
### Buckets y cifrado
- `s3_private_bucket` (datos sensibles)
  - Cifrado SSE-KMS con la clave `kms_s3_private`.
  - Bloqueo de acceso público activado.
  - Enforce bucket owner: ownership controls y ACLs deshabilitadas.
  - Versioning activo y políticas de ciclo de vida.
  - Política de transporte seguro: denegar `aws:SecureTransport = false`.
  - Política de cifrado estricto: exigir `x-amz-server-side-encryption = aws:kms` y `x-amz-server-side-encryption-aws-kms-key-id = <kms_s3_private>`.
- `frontend_bucket` (assets estáticos)
  - Cifrado SSE-AES256 por defecto.
  - Bloqueo de acceso público activado.
  - Propiedad del bucket y políticas para OAI de CloudFront (solo lectura mediante `aws_cloudfront_origin_access_identity`).
  - Sitio estático y contenido versionado + lifecycle.

### Auditoría rápida
- Ver política: `aws s3api get-bucket-policy --bucket <nombre>`.
- Comprobar cifrado: `aws s3api get-bucket-encryption --bucket <nombre>`.
- Listar flags de acceso público: `aws s3api get-public-access-block --bucket <nombre>`.

## CloudFront
- Orígenes
  - S3 frontend con OAI.
  - API Gateway como segundo origen para `/api/*`.
- Comportamientos
  - Default cache behavior para estáticos; `viewer_protocol_policy = redirect-to-https`.
  - `ordered_cache_behavior` para `/api/*` con `cache_policy_id` e integración API.
- Seguridad
  - TLS mínimo y certificado gestionado (ARN configurable).
  - Funciones/Headers de seguridad en respuestas (HSTS, CSP si aplicadas).
  - Invalidation tras despliegues para evitar contenido obsoleto.
- Logging (prod)
  - Bucket de logs dedicado con lifecycle.

## WAF v2 (Web ACL)
- Asociado a CloudFront.
- Reglas
  - AWS Managed Rules: Common, Known Bad Inputs, SQLi.
  - Amazon IP Reputation y Anonymous IP List.
  - Bot Control (activado en producción).
  - Rate limiting con límites por entorno y geo-matching opcional.
  - Geo-blocking opcional según `enable_geo_blocking`, `allowed_countries`/`blocked_countries`.
- Monitoreo
  - Métricas por regla y logging a CloudWatch.
- Alivio controlado
  - Modo `count`, allowlists temporales, desactivar geoblocking vía variables.

### Auditoría rápida
- Obtener Web ACL: `aws wafv2 get-web-acl --name <name> --scope CLOUDFRONT --id <id>`.
- Métricas y logs en CloudWatch.

## KMS
- Claves
  - `kms_data_key`: datos generales (rotación habilitada).
  - `kms_rds`: cifrado de RDS (rotación habilitada; acceso a `rds.amazonaws.com`).
  - `kms_s3_private`: cifrado de S3 privado (acceso a `s3.amazonaws.com`).
  - `kms_logs`: cifrado de CloudWatch Logs (acceso a `logs.<region>.amazonaws.com`).
- Políticas
  - Permiten uso por servicios respectivos y administradores de la cuenta.
  - Rotación anual activada.

### Auditoría rápida
- Describir clave: `aws kms describe-key --key-id <arn>`.
- Política: `aws kms get-key-policy --key-id <arn> --policy-name default`.
- Rotación: `aws kms get-key-rotation-status --key-id <arn>`.

## Variables de seguridad relevantes (Terraform)
- `enable_geo_blocking`, `allowed_countries`, `blocked_countries`.
- `enable_shield_advanced`.
- Certificados: `api_domain_name`, `app_domain_name`, `api_certificate_arn`, `app_certificate_arn`.
- JWT: `jwt_audience`, `jwt_issuer` (para servicios que lo usen).

## Comandos de verificación post-despliegue
- `terraform validate` y `terraform plan` con salida revisada.
- `bash ci-cd/smoke-tests.sh` (CDN raíz, `index.html`, `API /health`).
- AWS CLI para políticas y cifrado como arriba.
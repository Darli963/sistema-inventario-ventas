# Infraestructura IaC con Terraform

Este proyecto utiliza Terraform para gestionar infraestructura en AWS. A continuación se detalla el backend remoto, separación de entornos y el orden recomendado de despliegue.

## Backend remoto de Terraform (S3 + DynamoDB)

1. Bootstrap del backend (crear recursos):
   - Asegúrate de tener credenciales AWS configuradas.
   - Ejecuta:
     - `terraform init`
     - `terraform apply -target=aws_s3_bucket.tfstate -target=aws_dynamodb_table.tf_locks`
   - Esto creará:
     - Bucket S3 con versioning y cifrado SSE-S3 para `tfstate`.
     - Tabla DynamoDB `terraform-locks` para bloqueo del estado.

2. Configurar el backend y reconfigurar:
   - `terraform init -reconfigure \
     -backend-config="bucket=<nombre-del-bucket>" \
     -backend-config="region=<aws-region>" \
     -backend-config="dynamodb_table=terraform-locks" \
     -backend-config="key=env/${terraform.workspace}/terraform.tfstate"`
   - Recomendado usar un bucket único por cuenta y separar por workspace en `key`.

## Entornos con Workspaces y tfvars

- Crear workspaces:
  - `terraform workspace new dev`
  - `terraform workspace new staging`
  - `terraform workspace new prod`
- Seleccionar workspace:
  - `terraform workspace select dev`
- Aplicar por entorno usando tfvars:
  - `terraform plan   -var-file=env/dev.tfvars`
  - `terraform apply  -var-file=env/dev.tfvars`

## Outputs normalizados

- `api_url`: URL de la API servida vía CloudFront.
- `cloudfront_domain`: dominio de la distribución del frontend.
- `s3_frontend_bucket`: nombre del bucket del frontend.
- `rds_endpoint`: endpoint principal de la base de datos.

## Orden de despliegue y dependencias

Orden recomendado (las dependencias se resuelven por Terraform, pero es útil conocerlas):

1. Red y seguridad base:
   - `VPC`, `Subnets`, `Internet/NAT Gateways`, `Route Tables`.
   - `Security Groups` y `NACLs`.
2. Criptografía y registros:
   - `KMS keys` (ej. `kms_logs`) para cifrado de logs/buckets.
   - `CloudWatch Log Groups` base.
3. Datos:
   - `RDS` (depende de `VPC` y `Security Groups`).
   - Backups (`AWS Backup`) hacia `Vault` y seleccionando `RDS` y `S3`.
4. Aplicación:
   - `IAM roles/policies` para Lambdas y servicios.
   - `Lambdas` y `API Gateway`.
5. Frontend y seguridad perimetral:
   - `S3 frontend bucket` y `CloudFront`.
   - `WAF v2` (asociado a CloudFront) y Firehose para logging.
6. Observabilidad:
   - `CloudWatch Alarms`, `Dashboards`, `Metric Filters`.
   - Logging centralizado (`Kinesis Firehose` a `S3` para WAF).

Notas de dependencia:
- `CloudFront` depende del bucket `S3` del frontend.
- `WAF` se asocia a la distribución de `CloudFront`.
- `Observabilidad` usa `kms_logs` y los nombres de `Log Groups` de API/Lambda.
- `Backup` requiere `IAM Role` con permisos de backup y acceso a KMS si aplica.

## Ejemplo rápido de despliegue

```bash
# Inicializar backend remoto (una sola vez por cuenta)
terraform init
terraform apply -target=aws_s3_bucket.tfstate -target=aws_dynamodb_table.tf_locks
terraform init -reconfigure -backend-config="bucket=tfstate-<account-id>" -backend-config="region=us-east-1" -backend-config="dynamodb_table=terraform-locks" -backend-config="key=env/${terraform.workspace}/terraform.tfstate"

# Crear y seleccionar entorno
echo "Creando workspaces..."
terraform workspace new dev || true
terraform workspace select dev

# Plan y apply con variables del entorno
terraform plan  -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars
```
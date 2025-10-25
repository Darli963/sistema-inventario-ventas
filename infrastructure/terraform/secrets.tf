# Configuración de AWS Secrets Manager para credenciales de base de datos
# Versión del proveedor AWS: ~> 5.0

# Generar contraseña aleatoria para RDS
resource "random_password" "rds_password" {
  length  = 32
  special = true
  # Excluir caracteres que pueden causar problemas en URLs o conexiones
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret para credenciales de RDS principal
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${local.prefix}-${var.environment}-rds-credentials"
  description             = "Credenciales para la base de datos RDS principal"
  recovery_window_in_days = 7

  # Habilitar rotación automática

  tags = merge(
    local.common_tags,
    {
      Name        = "${local.prefix}-${var.environment}-rds-credentials"
      Type        = "Database"
      Environment = var.environment
    }
  )
}

# Versión del secret con las credenciales
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds_password.result
    engine   = "mysql"
    host     = aws_db_instance.rds_primary.endpoint
    port     = aws_db_instance.rds_primary.port
    dbname   = aws_db_instance.rds_primary.db_name
  })

  # Asegurar que se cree después de la instancia RDS
  depends_on = [aws_db_instance.rds_primary]
}

# Política IAM para acceso al secret desde Lambda/EC2
resource "aws_iam_policy" "secrets_access" {
  name        = "${local.prefix}-${var.environment}-secrets-access"
  description = "Política para acceder a secrets de RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_credentials.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.data_key.arn
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Configuración de rotación automática (opcional para producción)
resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  count               = var.environment == "prod" && var.enable_secret_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.rds_credentials.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
}
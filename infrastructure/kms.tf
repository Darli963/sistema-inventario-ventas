# KMS para cifrado de datos sensibles en el sistema de inventario y ventas

# Clave KMS principal para cifrado de datos
resource "aws_kms_key" "data_key" {
  description         = "KMS Key para cifrado de datos sensibles"
  enable_key_rotation = true

  # Política que permite a los servicios usar la clave
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow RDS Service",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-kms-data"
    }
  )
}

# Alias para facilitar la referencia a la clave KMS
resource "aws_kms_alias" "data_key_alias" {
  name          = "alias/${local.prefix}-${var.environment}-data-key"
  target_key_id = aws_kms_key.data_key.id
}
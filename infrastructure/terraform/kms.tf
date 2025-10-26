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
      },
      {
        Sid    = "Allow CloudWatch Logs Service",
        Effect = "Allow",
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
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


resource "aws_kms_alias" "data_key_alias" {
  name          = "alias/${local.prefix}-${var.environment}-data-key"
  target_key_id = aws_kms_key.data_key.id
}

# Clave KMS específica para RDS
resource "aws_kms_key" "kms_rds" {
  description         = "KMS Key para cifrado de RDS y Secrets vinculados"
  enable_key_rotation = true

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
        Sid    = "Allow Secrets Manager",
        Effect = "Allow",
        Principal = {
          Service = "secretsmanager.amazonaws.com"
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

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-kms-rds" })
}

resource "aws_kms_alias" "kms_rds_alias" {
  name          = "alias/${local.prefix}-${var.environment}-kms-rds"
  target_key_id = aws_kms_key.kms_rds.id
}

# Clave KMS específica para S3 privado
resource "aws_kms_key" "kms_s3_private" {
  description         = "KMS Key para cifrado de bucket S3 privado"
  enable_key_rotation = true

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

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-kms-s3-private" })
}

resource "aws_kms_alias" "kms_s3_private_alias" {
  name          = "alias/${local.prefix}-${var.environment}-kms-s3-private"
  target_key_id = aws_kms_key.kms_s3_private.id
}

# Clave KMS específica para CloudWatch Logs
resource "aws_kms_key" "kms_logs" {
  description         = "KMS Key para cifrado de CloudWatch Logs"
  enable_key_rotation = true

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
        Sid    = "Allow CloudWatch Logs Service",
        Effect = "Allow",
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
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

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-kms-logs" })
}

resource "aws_kms_alias" "kms_logs_alias" {
  name          = "alias/${local.prefix}-${var.environment}-kms-logs"
  target_key_id = aws_kms_key.kms_logs.id
}
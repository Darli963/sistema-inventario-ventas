# IAM Roles y Policies para el sistema de inventario y ventas
# Version: 1.0.0

# 1️⃣ Rol para Lambda con permisos básicos y adicionales para S3, RDS y CloudWatch
resource "aws_iam_role" "lambda_role" {
  name        = "${local.prefix}-${local.environment}-lambda-role"
  description = "Role for Lambda functions with permissions for S3, RDS and CloudWatch"

  # Política de confianza para permitir que Lambda asuma este rol
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  # Prevenir eliminación accidental
  force_detach_policies = true

  # Etiquetas consistentes
  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-lambda-role"
    }
  )
}

# Adjuntar política básica de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política personalizada para acceso a S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${local.prefix}-${local.environment}-lambda-s3-policy"
  description = "Policy for Lambda to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.prefix}-${local.environment}-*/*",
          "arn:aws:s3:::${local.prefix}-${local.environment}-*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Adjuntar política S3 al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Política personalizada para acceso a RDS
resource "aws_iam_policy" "lambda_rds_policy" {
  name        = "${local.prefix}-${local.environment}-lambda-rds-policy"
  description = "Policy for Lambda to access RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:*/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Adjuntar política RDS al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_rds_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_rds_policy.arn
}

# Política personalizada para CloudWatch Logs extendida
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name        = "${local.prefix}-${local.environment}-lambda-cloudwatch-policy"
  description = "Extended CloudWatch policy for Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Adjuntar política CloudWatch extendida al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}

# 2️⃣ Roles de administración para DevOps
resource "aws_iam_role" "devops_role" {
  name        = "${local.prefix}-${local.environment}-devops-role"
  description = "Role for DevOps engineers with Terraform/CLI permissions"

  # Política de confianza - Usar variable para el ID de cuenta
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:PrincipalTag/Role" : "DevOps"
        }
      }
    }]
  })

  # Prevenir eliminación accidental
  force_detach_policies = true

  # Etiquetas consistentes
  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-devops-role"
    }
  )
}

# Adjuntar política según el entorno
resource "aws_iam_role_policy_attachment" "devops_attach" {
  role       = aws_iam_role.devops_role.name
  policy_arn = local.environment == "prod" ? aws_iam_policy.restricted_admin_policy[0].arn : "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Política restringida para producción
resource "aws_iam_policy" "restricted_admin_policy" {
  count       = local.environment == "prod" ? 1 : 0
  name        = "${local.prefix}-${local.environment}-restricted-admin-policy"
  description = "Restricted admin policy for production environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "s3:*",
          "lambda:*",
          "apigateway:*",
          "cloudfront:*",
          "cloudwatch:*",
          "logs:*",
          "iam:Get*",
          "iam:List*",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "iam:Delete*",
          "iam:Create*",
          "iam:Update*",
          "iam:Attach*",
          "iam:Detach*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Obtener información de la cuenta actual
data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Adjuntar política de escritura en X-Ray al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_xray_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
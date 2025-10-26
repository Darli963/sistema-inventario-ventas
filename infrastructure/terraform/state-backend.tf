# Bootstrap de backend remoto para Terraform (S3 + DynamoDB locks)

# Identidad de la cuenta para nombrar recursos de forma única
# data "aws_caller_identity" "current" {}

locals {
  tfstate_bucket_name = length(var.tfstate_bucket_name) > 0 ? var.tfstate_bucket_name : "tfstate-${data.aws_caller_identity.current.account_id}"
  dynamodb_table_name = length(var.tfstate_dynamodb_table_name) > 0 ? var.tfstate_dynamodb_table_name : "terraform-locks"
}

variable "tfstate_bucket_name" {
  description = "Nombre del bucket S3 para almacenar el tfstate (opcional, se genera por defecto)"
  type        = string
  default     = ""
}

variable "tfstate_dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locks (opcional, se genera por defecto)"
  type        = string
  default     = ""
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.tfstate_bucket_name

  tags = merge(local.common_tags, {
    Name      = local.tfstate_bucket_name
    component = "terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce HTTPS-only
resource "aws_s3_bucket_policy" "tfstate_secure_transport" {
  bucket = aws_s3_bucket.tfstate.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = false
          }
        }
      }
    ]
  })
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name      = local.dynamodb_table_name
    component = "terraform-locks"
  })
}
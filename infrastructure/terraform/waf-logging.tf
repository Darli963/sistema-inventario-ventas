# WAF Logging a S3 via Kinesis Firehose

# Rol para Kinesis Firehose
resource "aws_iam_role" "firehose_waf_role" {
  name = "${local.prefix}-${var.environment}-firehose-waf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "firehose.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# Permisos mínimos para escribir en el bucket S3 destino
resource "aws_iam_role_policy" "firehose_waf_s3_policy" {
  name = "${local.prefix}-${var.environment}-firehose-waf-s3-policy"
  role = aws_iam_role.firehose_waf_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.private_bucket.arn,
          "${aws_s3_bucket.private_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Stream de Firehose que entrega logs WAF a S3 (prefijo logs/waf/)
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "${local.prefix}-${var.environment}-waf-logs"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_waf_role.arn
    bucket_arn          = aws_s3_bucket.private_bucket.arn
    prefix              = "logs/waf/"
    error_output_prefix = "logs/waf-errors/"
    buffering_size      = 5
    buffering_interval  = 300
    compression_format  = "GZIP"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-waf-logs"
  })
}

# Configuración de logging en WAFv2 hacia Firehose
resource "aws_wafv2_web_acl_logging_configuration" "frontend_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.frontend_waf.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  redacted_fields {
    single_header { name = "authorization" }
  }
}
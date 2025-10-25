# Configuración de S3 y CloudFront para el sistema de inventario y ventas
# Versión del proveedor AWS: ~> 5.0

# Generar sufijo único para nombres de buckets
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket S3 privado para datos sensibles con cifrado KMS
resource "aws_s3_bucket" "private_bucket" {
  bucket = "${local.prefix}-${var.environment}-private-${random_id.bucket_suffix.hex}"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.prefix}-${var.environment}-private"
      Type    = "Storage"
      Purpose = "Private Data"
    }
  )
}

# Controles de propiedad y bloqueo de acceso público (bucket privado)
resource "aws_s3_bucket_ownership_controls" "private_ownership" {
  bucket = aws_s3_bucket.private_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "private_block" {
  bucket                  = aws_s3_bucket.private_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Configuración de versionado para bucket privado
resource "aws_s3_bucket_versioning" "private_versioning" {
  bucket = aws_s3_bucket.private_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuración de cifrado con KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket_encryption" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data_key.arn
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy para bucket privado
resource "aws_s3_bucket_lifecycle_configuration" "private_lifecycle" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    id     = "private_data_lifecycle"
    status = "Enabled"
    filter {
      prefix = ""
    }

    # Transición a IA después de 30 días
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transición a Glacier después de 90 días
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transición a Deep Archive después de 365 días
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Eliminar versiones no actuales después de 90 días
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.environment == "prod" ? 2555 : 120 # 7 años en prod, 120 días en dev (mayor que 90)
    }

    # Eliminar uploads incompletos después de 7 días
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket S3 público para frontend
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${local.prefix}-${var.environment}-frontend-${random_id.bucket_suffix.hex}"

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.prefix}-${var.environment}-frontend"
      Type    = "Storage"
      Purpose = "Frontend Assets"
    }
  )
}

# Controles de propiedad y bloqueo de acceso público (frontend)
resource "aws_s3_bucket_ownership_controls" "frontend_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_block" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Configuración de versionado para bucket frontend
resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuración de cifrado para bucket frontend (AES256 para mejor rendimiento)
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy para bucket frontend
resource "aws_s3_bucket_lifecycle_configuration" "frontend_lifecycle" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    id     = "frontend_assets_lifecycle"
    status = "Enabled"
    filter {
      prefix = ""
    }

    # Eliminar versiones no actuales después de 30 días
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Eliminar uploads incompletos después de 1 día
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Configuración para sitio web estático
resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


# Identidad de acceso de origen de CloudFront (OAI)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${local.prefix}-${var.environment}-frontend"
}

# Política de acceso para el bucket frontend (permitir acceso solo a OAI)
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontOAIRead",
        Effect = "Allow",
        Principal = {
          CanonicalUser = aws_cloudfront_origin_access_identity.oai.s3_canonical_user_id
        },
        Action   = ["s3:GetObject"],
        Resource = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront para distribución del frontend
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Origen adicional para API Gateway
  origin {
    domain_name = replace(aws_apigatewayv2_api.api_gateway.api_endpoint, "https://", "")
    origin_id   = "API-Gateway"
    origin_path = "/${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.environment == "prod" ? "PriceClass_All" : "PriceClass_100"
  http_version        = "http2and3"
  web_acl_id          = aws_wafv2_web_acl.frontend_waf.arn

  # Configuración de cache optimizada
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1 día
    max_ttl                = 31536000 # 1 año

    # Funciones de CloudFront
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_routing.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Cache behavior para archivos estáticos
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000 # 1 año
    default_ttl            = 31536000 # 1 año
    max_ttl                = 31536000 # 1 año

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000 # 1 año
    default_ttl            = 31536000 # 1 año
    max_ttl                = 31536000 # 1 año

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Cache behavior para API calls
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "API-Gateway"
    compress         = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Authorization", "Content-Type", "Accept", "Origin", "Referer", "User-Agent"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Páginas de error personalizadas para SPA
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 500
    response_code         = 500
    response_page_path    = "/error.html"
    error_caching_min_ttl = 60
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Logging (solo en producción)
  dynamic "logging_config" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      include_cookies = false
      bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
      prefix          = "cloudfront-logs/"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-cf-distribution"
      Type = "CDN"
    }
  )

  depends_on = [
    aws_wafv2_web_acl.frontend_waf,
    aws_cloudfront_function.security_headers,
    aws_cloudfront_function.spa_routing,
    aws_apigatewayv2_api.api_gateway
  ]
}

# Bucket para logs de CloudFront (solo en producción)
resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = "${local.prefix}-${var.environment}-cloudfront-logs-${random_id.bucket_suffix.hex}"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-cloudfront-logs"
      Type = "Logs"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_ownership" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs_lifecycle" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    id     = "cloudfront_logs_lifecycle"
    status = "Enabled"
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
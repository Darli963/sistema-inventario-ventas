# Protección opcional con AWS Shield Advanced
resource "aws_shield_protection" "cloudfront_protection" {
  count      = var.environment == "prod" && var.enable_shield_advanced ? 1 : 0
  provider   = aws.global
  name       = "${local.prefix}-${var.environment}-cloudfront-protection"
  resource_arn = aws_cloudfront_distribution.frontend_distribution.arn
}
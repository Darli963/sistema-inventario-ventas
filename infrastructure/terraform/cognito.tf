# Cognito User Pool y Client para autenticación JWT
# Provee el User Pool y Client mínimos para integrar Authorizer JWT en API Gateway HTTP v2

resource "aws_cognito_user_pool" "user_pool" {
  name = "${local.prefix}-${var.environment}-users"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-${var.environment}-cognito" })
}

resource "aws_cognito_user_pool_client" "app_client" {
  name         = "${local.prefix}-${var.environment}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  supported_identity_providers  = ["COGNITO"]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

}
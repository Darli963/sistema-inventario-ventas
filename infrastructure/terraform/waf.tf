# Configuración de AWS WAF v2 para protección de CloudFront
# Versión del proveedor AWS: ~> 5.0
# WAF v2 con reglas administradas por AWS y reglas personalizadas

# WAF Web ACL para CloudFront
resource "aws_wafv2_web_acl" "frontend_waf" {
  name        = "${local.prefix}-${var.environment}-waf"
  description = "WAF para proteger CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla 1: AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Excluir reglas específicas si es necesario
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "GenericRFI_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 2: AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 3: AWS Managed Rules - SQL Injection
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 4: Rate Limiting
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.environment == "prod" ? 2000 : 1000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            # Permitir solo ciertos países (opcional)
            country_codes = var.allowed_countries
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Regla 5: Geo Blocking (opcional)
  rule {
    count = var.enable_geo_blocking ? 1 : 0
    name     = "GeoBlockingRule"
    priority = 5

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockingRule"
      sampled_requests_enabled   = true
    }
  }

  # Regla 6: IP Reputation List
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 7: Anonymous IP List
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 7

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AnonymousIpListMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 8: Bot Control (solo para producción)
  dynamic "rule" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name     = "AWS-AWSManagedRulesBotControlRuleSet"
      priority = 8

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"

          managed_rule_group_configs {
            aws_managed_rules_bot_control_rule_set {
              inspection_level = "COMMON"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BotControlRuleSetMetric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Configuración de visibilidad global
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.prefix}-${var.environment}-waf-metric"
    sampled_requests_enabled   = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-waf"
      Type = "Security"
    }
  )
}

# Asociar WAF con CloudFront Distribution
resource "aws_wafv2_web_acl_association" "frontend_waf_association" {
  resource_arn = aws_cloudfront_distribution.frontend_distribution.arn
  web_acl_arn  = aws_wafv2_web_acl.frontend_waf.arn
}

# CloudWatch Log Group para WAF
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "/aws/wafv2/${local.prefix}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7
  kms_key_id        = aws_kms_key.data_key.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-waf-logs"
    }
  )
}

# Configuración de logging para WAF
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  resource_arn            = aws_wafv2_web_acl.frontend_waf.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]

  # Filtros de logging
  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "DROP"
      condition {
        action_condition {
          action = "ALLOW"
        }
      }
      requirement = "MEETS_ALL"
    }
  }

  # Campos redactados por privacidad
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# Alarma de CloudWatch para WAF
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  count = var.environment == "prod" ? 1 : 0
  
  alarm_name          = "${local.prefix}-${var.environment}-waf-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors blocked requests by WAF"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.frontend_waf.name
    Region = var.aws_region
    Rule   = "ALL"
  }

  tags = local.common_tags
}

# SNS Topic para alertas (solo en producción)
resource "aws_sns_topic" "alerts" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${local.prefix}-${var.environment}-security-alerts"
  
  kms_master_key_id = aws_kms_key.data_key.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-alerts"
    }
  )
}
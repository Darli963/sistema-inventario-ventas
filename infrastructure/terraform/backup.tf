# AWS Backup: Vault, Plan y Selección para RDS y S3 privado

resource "aws_backup_vault" "main" {
  name        = "${local.prefix}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.kms_logs.arn

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-backup-vault"
  })
}

# Plan de backup: diario a las 05:00 UTC, retención 30 días
resource "aws_backup_plan" "main" {
  name = "${local.prefix}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }

  tags = local.common_tags
}

# Rol IAM para AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${local.prefix}-${var.environment}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "backup.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup_role_backup" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_role_restore" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Selección de recursos: RDS primario y bucket S3 privado
resource "aws_backup_selection" "main" {
  name         = "${local.prefix}-${var.environment}-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_db_instance.rds_primary.arn,
    aws_s3_bucket.private_bucket.arn
  ]
}
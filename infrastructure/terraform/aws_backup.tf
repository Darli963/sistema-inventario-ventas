# AWS Backup: Vault, Plan y Selecciones para RDS y S3 privado

# Vault con cifrado KMS
resource "aws_backup_vault" "main" {
  name        = "${local.prefix}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.data_key.arn

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-backup-vault"
    Type = "Backup"
  })
}

# Rol para que AWS Backup gestione respaldos y restauraciones
resource "aws_iam_role" "backup_role" {
  name = "${local.prefix}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "backup.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Plan diario a las 5 AM UTC, retención 30 días
resource "aws_backup_plan" "inventory_backup" {
  name = "${local.prefix}-${var.environment}-inventory-backup"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * * *)" # Todos los días a 5 AM UTC

    lifecycle {
      delete_after = 30 # Retención de 30 días
    }
  }

  tags = local.common_tags
}

# Selección: RDS primaria
resource "aws_backup_selection" "rds_primary" {
  name         = "${local.prefix}-${var.environment}-rds-primary-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.inventory_backup.id
  resources    = [aws_db_instance.rds_primary.arn]
}

# Selección: RDS réplica (si existe)
resource "aws_backup_selection" "rds_replica" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "${local.prefix}-${var.environment}-rds-replica-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.inventory_backup.id
  resources    = [aws_db_instance.rds_replica[0].arn]
}

# Selección: S3 privado
resource "aws_backup_selection" "s3_private" {
  name         = "${local.prefix}-${var.environment}-s3-private-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.inventory_backup.id
  resources    = ["arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}"]
}

# Outputs
output "backup_plan_id" {
  description = "ID del plan de backup"
  value       = aws_backup_plan.inventory_backup.id
}

output "backup_vault_name" {
  description = "Nombre del backup vault"
  value       = aws_backup_vault.main.name
}
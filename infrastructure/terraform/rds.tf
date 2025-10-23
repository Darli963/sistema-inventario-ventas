# Configuración de RDS para el sistema de inventario y ventas
# Versión del proveedor AWS: ~> 5.0
# MySQL versión: 8.0.35 (LTS)

# Grupo de subredes para RDS
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${local.prefix}-${var.environment}-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  description = "Subnet group para instancias RDS"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-subnet-group"
      Type = "Database"
    }
  )
}

# Grupo de parámetros personalizado para MySQL 8.0
resource "aws_db_parameter_group" "mysql_params" {
  family = "mysql8.0"
  name   = "${local.prefix}-${var.environment}-mysql-params"
  description = "Parámetros personalizados para MySQL 8.0"

  # Optimizaciones para rendimiento
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = local.common_tags
}

# Instancia RDS principal con cifrado KMS
resource "aws_db_instance" "rds_primary" {
  identifier     = "${local.prefix}-${var.environment}-rds-primary"
  engine         = "mysql"
  engine_version = "8.0.35"  # Versión específica LTS
  instance_class = var.environment == "prod" ? "db.t3.small" : "db.t3.micro"
  
  # Configuración de almacenamiento
  allocated_storage     = 20
  max_allocated_storage = var.environment == "prod" ? 200 : 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.data_key.arn
  
  # Configuración de red y seguridad
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  
  # Credenciales desde Secrets Manager
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.data_key.arn
  username = "admin"
  db_name  = "inventario"
  
  # Configuración de alta disponibilidad
  multi_az = var.environment == "prod" ? true : false
  
  # Configuración de backup
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:30-Mon:05:30"
  copy_tags_to_snapshot  = true
  delete_automated_backups = var.environment != "prod"
  
  # Configuración de parámetros
  parameter_group_name = aws_db_parameter_group.mysql_params.name
  
  # Configuración de monitoreo
  performance_insights_enabled = var.environment == "prod" ? true : false
  performance_insights_retention_period = var.environment == "prod" ? 7 : 0
  monitoring_interval = var.environment == "prod" ? 60 : 0
  monitoring_role_arn = var.environment == "prod" ? aws_iam_role.rds_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]
  
  # Configuración de seguridad
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.prefix}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  # Timeouts personalizados
  timeouts {
    create = "60m"
    update = "80m"
    delete = "60m"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-rds-primary"
      Type = "Database"
      Role = "Primary"
    }
  )
}

# RDS réplica de lectura (solo para producción)
resource "aws_db_instance" "rds_replica" {
  count = var.environment == "prod" ? 1 : 0
  
  identifier               = "${local.prefix}-${var.environment}-rds-replica"
  replicate_source_db      = aws_db_instance.rds_primary.identifier
  instance_class           = "db.t3.small"
  
  # Configuración de red
  vpc_security_group_ids   = [aws_security_group.rds_sg.id]
  publicly_accessible      = false
  
  # Configuración de almacenamiento (heredada de la principal)
  storage_encrypted        = true
  kms_key_id              = aws_kms_key.data_key.arn
  
  # Configuración de monitoreo
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring[0].arn
  
  # Configuración de seguridad
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${local.prefix}-${var.environment}-replica-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Timeouts personalizados
  timeouts {
    create = "60m"
    update = "80m"
    delete = "60m"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${var.environment}-rds-replica"
      Type = "Database"
      Role = "ReadReplica"
    }
  )
}

# Rol IAM para monitoreo de RDS (solo para producción)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  name = "${local.prefix}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Política para el rol de monitoreo
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
# Security Groups para la infraestructura del sistema de inventario y ventas
# Version: 1.0.0

# 1️⃣ Security Group para Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${local.prefix}-${local.environment}-sg-alb"
  description = "Security Group para Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico HTTP from Internet
  ingress {
    description      = "HTTP desde Internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Permitir trafico HTTPS desde Internet
  ingress {
    description      = "HTTPS from Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Permitir todo el trafico saliente
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-sg-alb"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 2️⃣ Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name        = "${local.prefix}-${local.environment}-sg-rds"
  description = "Security Group para RDS"
  vpc_id      = aws_vpc.main.id

  # Permitir trafico MySQL/PostgreSQL desde Lambda SG
  ingress {
    description     = "Database access from Lambdas"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  # Permitir todo el trafico saliente
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-sg-rds"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 3️⃣ Security Group para Lambdas
resource "aws_security_group" "lambda_sg" {
  name        = "${local.prefix}-${local.environment}-sg-lambda"
  description = "Security Group para Lambdas"
  vpc_id      = aws_vpc.main.id

  # Permitir trafico entrante desde ALB
  ingress {
    description     = "Traffic from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Permitir todo el trafico saliente
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-sg-lambda"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 4️⃣ Security Group para Bastion Host (opcional)
resource "aws_security_group" "bastion_sg" {
  count       = var.create_bastion ? 1 : 0
  name        = "${local.prefix}-${local.environment}-sg-bastion"
  description = "Security Group para Bastion Host"
  vpc_id      = aws_vpc.main.id

  # Permitir SSH desde IPs autorizadas
  ingress {
    description = "SSH from authorized IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Permitir todo el trafico saliente
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-sg-bastion"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
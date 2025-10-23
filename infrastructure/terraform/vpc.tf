terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Definición de variables locales para convenciones de nombres
locals {
  prefix      = "mc"
  environment = var.environment

  # Tags comunes para todos los recursos
  common_tags = {
    Project     = "sistema-inventario-ventas"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "DevOps"
  }
}

# 1️⃣ VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-vpc"
    }
  )
}

# 2️⃣ Subnets Públicas
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-subnet-public-${var.availability_zone_suffixes[count.index]}"
    }
  )
}

# 3️⃣ Subnets Privadas
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-subnet-private-${var.availability_zone_suffixes[count.index]}"
    }
  )
}

# 4️⃣ Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-igw"
    }
  )
}

# 5️⃣ NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-eip-nat"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-nat"
    }
  )

  # Buena práctica: esperar a que el Internet Gateway esté completamente creado
  depends_on = [aws_internet_gateway.igw]
}

# 6️⃣ Route Table para subnets públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-rt-public"
    }
  )
}

# Asociaciones de Route Table para subnets públicas
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 7️⃣ Route Table para subnets privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-${local.environment}-rt-private"
    }
  )
}

# Asociaciones de Route Table para subnets privadas
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
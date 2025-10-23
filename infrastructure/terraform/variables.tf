variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (dev, test, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Lista de CIDR blocks para subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Lista de CIDR blocks para subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "availability_zone_suffixes" {
  description = "Sufijos para las zonas de disponibilidad (para nombrar recursos)"
  type        = list(string)
  default     = ["a", "b"]
}

# Variables para Security Groups
variable "db_port" {
  description = "Puerto para la base de datos RDS"
  type        = number
  default     = 3306 # Puerto por defecto para MySQL, usar 5432 para PostgreSQL
}

variable "create_bastion" {
  description = "Indica si se debe crear un Bastion Host"
  type        = bool
  default     = false
}

variable "allowed_ssh_ips" {
  description = "Lista de IPs permitidas para acceso SSH al Bastion Host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Por defecto permite desde cualquier IP, cambiar en producción
}

# Variables para IAM
variable "aws_account_id" {
  description = "ID de la cuenta de AWS para políticas IAM"
  type        = string
  default     = "123456789012" # Reemplazar con el ID de cuenta real
}

# Variables para WAF y CloudFront
variable "enable_geo_blocking" {
  description = "Habilitar bloqueo geográfico en WAF"
  type        = bool
  default     = false
}

variable "blocked_countries" {
  description = "Lista de códigos de países bloqueados (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = ["CN", "RU", "KP"] # China, Rusia, Corea del Norte como ejemplo
}

variable "allowed_countries" {
  description = "Lista de códigos de países permitidos para rate limiting"
  type        = list(string)
  default     = ["US", "CA", "MX", "BR", "AR", "CL", "CO", "PE", "EC", "VE", "UY", "PY", "BO", "GY", "SR", "GF"]
}

variable "domain_name" {
  description = "Nombre de dominio para la aplicación (opcional)"
  type        = string
  default     = null
}
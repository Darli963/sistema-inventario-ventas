// Proveedor por defecto para recursos regionales
provider "aws" {
  region = var.aws_region
}

// Proveedor global para recursos con alcance global (CloudFront/Shield)
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}
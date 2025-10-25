// Proveedor global para recursos con alcance global (CloudFront/Shield)
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}
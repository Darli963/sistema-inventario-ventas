terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }

  # Backend remoto en S3 con locking de DynamoDB.
  # Los valores concretos (bucket, key, region, dynamodb_table) se pasan en CI
  # via `terraform init -backend-config=...` para soportar múltiples entornos.
  backend "s3" {}
}
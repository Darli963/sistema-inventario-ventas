# Convenciones de Nombres para Recursos AWS

Este documento establece las convenciones de nombres para los recursos de AWS utilizados en el proyecto de sistema de inventario y ventas. Seguir estas convenciones es esencial para mantener una infraestructura organizada y facilitar la gestión de recursos.

## Formato General

La convención general sigue el formato:

```
mc-{env}-{tipo}-{nombre}
```

Donde:
- **mc**: Prefijo del proyecto (puede modificarse según el nombre del proyecto)
- **env**: Entorno de despliegue (dev, test, staging, prod)
- **tipo**: Tipo de recurso AWS
- **nombre**: Nombre descriptivo del recurso (opcional para algunos recursos)

## Convenciones por Tipo de Recurso

### S3 Buckets

```
mc-{env}-{tipo}
```

Ejemplos:
- `mc-prod-frontend` - Bucket para el frontend en producción
- `mc-dev-frontend` - Bucket para el frontend en desarrollo
- `mc-prod-logs` - Bucket para logs en producción
- `mc-prod-assets` - Bucket para assets estáticos en producción

### RDS (Relational Database Service)

```
mc-{env}-rds-{rol}
```

Ejemplos:
- `mc-prod-rds-primary` - Base de datos principal en producción
- `mc-prod-rds-replica` - Réplica de base de datos en producción
- `mc-dev-rds-primary` - Base de datos principal en desarrollo

### Lambdas

```
mc-{env}-lambda-{nombre_funcion}
```

Ejemplos:
- `mc-prod-lambda-auth` - Lambda de autenticación en producción
- `mc-prod-lambda-inventory` - Lambda de gestión de inventario en producción
- `mc-dev-lambda-sales` - Lambda de ventas en desarrollo

### API Gateway

```
mc-{env}-api-{nombre}
```

Ejemplos:
- `mc-prod-api-main` - API principal en producción
- `mc-dev-api-main` - API principal en desarrollo
- `mc-prod-api-admin` - API para administradores en producción

### CloudFront

```
mc-{env}-cf
```

Ejemplos:
- `mc-prod-cf` - Distribución CloudFront en producción
- `mc-dev-cf` - Distribución CloudFront en desarrollo

### Security Groups

```
mc-{env}-sg-{nombre}
```

Ejemplos:
- `mc-prod-sg-rds` - Grupo de seguridad para RDS en producción
- `mc-prod-sg-lambda` - Grupo de seguridad para Lambdas en producción
- `mc-dev-sg-alb` - Grupo de seguridad para Application Load Balancer en desarrollo

## Recursos Adicionales

### VPC (Virtual Private Cloud)

```
mc-{env}-vpc
```

Ejemplos:
- `mc-prod-vpc` - VPC en producción
- `mc-dev-vpc` - VPC en desarrollo

### Subnets

```
mc-{env}-subnet-{tipo}-{az}
```

Ejemplos:
- `mc-prod-subnet-public-a` - Subnet pública en la zona de disponibilidad a en producción
- `mc-prod-subnet-private-b` - Subnet privada en la zona de disponibilidad b en producción

### IAM Roles

```
mc-{env}-role-{servicio}
```

Ejemplos:
- `mc-prod-role-lambda` - Rol IAM para Lambdas en producción
- `mc-dev-role-ec2` - Rol IAM para EC2 en desarrollo

### Application Load Balancer (ALB)

```
mc-{env}-alb
```

Ejemplos:
- `mc-prod-alb` - ALB en producción
- `mc-dev-alb` - ALB en desarrollo

## Etiquetas (Tags)

Además de las convenciones de nombres, todos los recursos deben incluir las siguientes etiquetas:

- **Project**: `sistema-inventario-ventas`
- **Environment**: `dev`, `test`, `staging`, `prod`
- **ManagedBy**: `terraform`
- **Owner**: Equipo o persona responsable

## Uso en Terraform

En los archivos de Terraform, se recomienda utilizar variables para construir los nombres de recursos:

```hcl
locals {
  prefix = "mc"
  environment = var.environment
}

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.prefix}-${local.environment}-frontend"
  # ...
}
```

Esto facilita la reutilización de código entre diferentes entornos y mantiene la consistencia en las convenciones de nombres.
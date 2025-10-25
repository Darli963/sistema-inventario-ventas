# Playbooks de Failover

Objetivo: describir pasos de contingencia para mantener el servicio ante fallas en CDN, API y Base de Datos, alineados con la infraestructura Terraform existente.

## CDN/Frontend (CloudFront + S3)
- Escenario: origen S3 inaccesible o contenido inconsistente.
- Pasos
  1. Activar página de mantenimiento:
     - Subir `maintenance.html` al bucket frontend.
     - Opcional: ajustar `custom_error_response` en CloudFront para mapear 500/503 a `/maintenance.html` (vía Terraform).
  2. Despliegue rápido del frontend: `bash ci-cd/deploy-frontend.sh` y invalidar `/*`.
  3. Verificación: `ENVIRONMENT=<ws> bash ci-cd/smoke-tests.sh`.

## API Gateway origen alternativo (con ALB)
- Escenario: API Gateway/Lambdas con degradación severa.
- Estrategia: añadir un origen alternativo (ALB) y reencaminar `/api/*` temporalmente.
- Pasos (Terraform)
  1. Crear/identificar ALB y target group saludables; obtener `alb_dns_name`.
  2. En `s3-cloudfront.tf`, añadir origen CloudFront para ALB y comportamiento ordenado:
     - Nuevo origen `domain_name = <alb_dns_name>`, `origin_id = "api-alb"`.
     - En `ordered_cache_behavior` de `/api/*`, poner `target_origin_id = "api-alb"`.
  3. `terraform plan` y `terraform apply` en el workspace afectado.
  4. Invalidar caché `/*`.
  5. Revertir cuando API Gateway se estabilice.

## Base de Datos (RDS) failover
- Escenario: caída de AZ primaria o saturación prolongada.
- Modelo actual
  - Prod: Multi-AZ habilitado y réplica de lectura.
  - RDS Proxy configurado para estabilizar conexiones.
- Pasos
  1. Evaluar estado: `aws rds describe-db-instances` y métricas.
  2. Failover manual (prod):
     - Multi-AZ: `aws rds reboot-db-instance --db-instance-identifier <primary-id> --force-failover`.
     - Réplica: promover si aplica: `aws rds promote-read-replica --db-instance-identifier <replica-id>`.
  3. Verificar endpoint activo: `terraform output -raw rds_primary_endpoint` (o el nuevo) y probar aplicación.
  4. Ajustar clase de instancia si necesario; aplicar vía Terraform.

## WAF alivio de emergencia
- Escenario: bloqueo masivo a legítimos por regla/geo.
- Pasos
  1. Pausar geoblocking: `enable_geo_blocking = false` en variables y aplicar.
  2. Bajar sensibilidad de reglas (usar modo `count` en reglas afectadas) o añadir allowlist temporal.
  3. Registrar cambios y revertir tras estabilización.

## KMS
- Escenario: claves deshabilitadas o políticas restringen servicios.
- Pasos
  1. Ver clave: `aws kms describe-key --key-id <arn>` y políticas.
  2. Rehabilitar clave si está deshabilitada; restaurar política base (ver documento de políticas).
  3. Validar RDS/S3/Logs vuelven a operar.

## Procedimiento de cambio y comunicación
- Todos los cambios de failover pasan por `terraform plan` + aprobación manual (GitHub environment/Jenkins input si está habilitado).
- Comunicar ventana, riesgo y rollback plan antes de aplicar.
- Ejecutar smoke tests y documentar resultados.
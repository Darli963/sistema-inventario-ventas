# Runbooks de Incidentes

Propósito: guiar la respuesta rápida y ordenada ante fallas o degradaciones en CDN (CloudFront), API (API Gateway/Lambdas), base de datos (RDS), cifrado (KMS), WAF y S3.

## Reglas de oro
- Priorizar disponibilidad y comunicación clara; seguridad se mantiene salvo riesgo mayor.
- Capturar cronología, decisiones y evidencias para postmortem.
- Usar entornos/variables de Terraform para cambios controlados; evitar parches manuales irreversibles.

## Herramientas clave
- `terraform output -raw <nombre>` para obtener endpoints y IDs.
- `ci-cd/smoke-tests.sh` para validar CDN y API tras cambios.
- AWS CLI para ver estado de recursos: `aws cloudfront get-distribution`, `aws apigatewayv2`, `aws rds describe-db-instances`, `aws kms describe-key`, `aws wafv2 get-web-acl`.
- CloudWatch Logs y Métricas para Lambdas, WAF y RDS.

## Incidente: CDN degradado o errores 4xx/5xx
1. Detección
   - Ejecutar `ENVIRONMENT=<ws> bash ci-cd/smoke-tests.sh`.
   - Obtener dominio: `terraform output -raw cloudfront_domain`.
2. Triage
   - Revisar estado de distribución: `aws cloudfront get-distribution --id $(terraform output -raw cloudfront_distribution_id)`.
   - Validar origen S3: `aws s3 ls s3://$(terraform output -raw frontend_bucket_name)` y existencia de `index.html`.
   - Ver WAF métricas; detectar bloqueos por reglas o geoblocking.
3. Mitigación
   - Si es caché obsoleta: invalidar `aws cloudfront create-invalidation --distribution-id <id> --paths "/*"`.
   - Si falta contenido: reconstruir y desplegar `bash ci-cd/deploy-frontend.sh`.
   - Si WAF bloquea legítimos: ver sección WAF abajo; aplicar alivio temporal (whitelist/ajuste de reglas/pausar geoblocking).
4. Verificación
   - Re-ejecutar smoke tests y validar navegación.
5. Comunicación y cierre
   - Informar impacto, causa, acciones y prevención.

## Incidente: API 5xx / timeouts
1. Detección
   - `API_URL=$(terraform output -raw api_url)`; probar `curl -fsS "$API_URL/health"`.
2. Triage
   - Revisar logs de Lambdas (CloudWatch) y métricas de latencia/errores.
   - Verificar conectividad a RDS: seguridad de SG, `rds:DescribeDBInstances`, credenciales de Secrets Manager.
   - Confirmar que KMS no esté denegando (errores `AccessDeniedException`).
   - Chequear WAF por falsos positivos en `/api/*`.
3. Mitigación
   - Ajustar timeouts/reintentos si hay picos.
   - Corregir integración Lambda/RDS (DB Proxy configurado; revisar saturación de conexiones).
   - Si API Gateway degradado: considerar failover a ALB (ver playbooks de failover).
4. Verificación
   - `curl "$API_URL/health"` y smoke tests.

## Incidente: Base de datos (conexión fallida, performance, failover)
1. Detección
   - Alarmas en CloudWatch; errores en Lambdas por conexión.
2. Triage
   - Ver estado: `aws rds describe-db-instances --db-instance-identifier <primary-id>`.
   - En prod, Multi-AZ activo; existe réplica de lectura.
   - Revisar métricas de conexiones, CPU, IOPS.
3. Mitigación
   - Usar RDS Proxy para estabilizar conexiones (ya configurado).
   - Aumentar clase de instancia vía Terraform si sostenido.
   - En failover manual (prod): `aws rds reboot-db-instance --db-instance-identifier <primary-id> --force-failover`.
4. Verificación
   - Confirmar endpoint activo: `terraform output -raw rds_primary_endpoint`.
   - Validar app funciona.

## Incidente: KMS (denegaciones de cifrado/descifrado)
1. Triage
   - `aws kms describe-key --key-id <arn>` y `get-key-policy`.
   - Validar que el servicio (`rds.amazonaws.com`, `s3.amazonaws.com`, `logs.<region>.amazonaws.com`) esté permitido.
2. Mitigación
   - Restaurar política base (ver políticas documentadas) y re-habilitar key si está deshabilitada.
3. Verificación
   - Operaciones vuelven a funcionar (RDS, S3, Logs).

## Incidente: WAF falsos positivos / bloqueo geográfico
1. Triage
   - Revisar métricas y muestras; identificar regla que bloquea.
2. Mitigación
   - Temporal: agregar IP allowlist o overrides de regla (count), pausar `enable_geo_blocking`.
   - Permanente: ajustar lista de países `allowed_countries`/`blocked_countries` y reglas.
3. Verificación
   - Métricas normalizadas y tráfico legítimo permitido.

## Incidente: S3 (403 AccessDenied / objetos faltantes)
1. Triage
   - Validar política del bucket frontend (OAI) y objetos presentes.
   - Verificar que despliegue subió `index.html` y assets.
2. Mitigación
   - Desplegar de nuevo y invalidar CloudFront.
   - Si la OAI cambió, actualizar política del bucket.

## Comunicación y postmortem
- Notas de impacto, RCA, acciones correctivas y preventivas.
- Documentar variables/flags cambiados y confirmar rollback.
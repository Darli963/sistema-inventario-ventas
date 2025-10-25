#!/usr/bin/env bash
# Smoke tests para CDN (CloudFront) y API detrás de CDN
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
TF_DIR="$REPO_ROOT/infrastructure/terraform"

ENVIRONMENT="${ENVIRONMENT:-}" # opcional

pushd "$TF_DIR" >/dev/null
if [ -n "$ENVIRONMENT" ]; then
  terraform workspace select "$ENVIRONMENT" >/dev/null 2>&1 || true
fi

# Obtener outputs
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain 2>/dev/null || terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")
API_URL=$(terraform output -raw api_url 2>/dev/null || echo "")
popd >/dev/null

if [ -z "$CLOUDFRONT_DOMAIN" ]; then
  echo "❌ No se pudo obtener cloudfront_domain desde Terraform outputs" >&2
  exit 1
fi

echo "🌐 CDN: https://$CLOUDFRONT_DOMAIN"
# Probar raíz (SPA)
if curl -fsS --max-time 20 "https://$CLOUDFRONT_DOMAIN/" -o /dev/null; then
  echo "✅ CDN OK (root)"
else
  echo "❌ CDN fallo al cargar raíz" >&2
  exit 1
fi

# Probar asset principal si existe
if curl -fsS --max-time 20 "https://$CLOUDFRONT_DOMAIN/index.html" -o /dev/null; then
  echo "✅ CDN OK (index.html)"
else
  echo "⚠️ CDN no encontró index.html (puede ser SPA con router)"
fi

if [ -n "$API_URL" ]; then
  echo "🔗 API: $API_URL/health"
  if curl -fsS --max-time 20 "$API_URL/health" -o /dev/null; then
    echo "✅ API OK (health)"
  else
    echo "❌ API fallo en health" >&2
    exit 1
  fi
else
  echo "⚠️ No se encontró api_url; omitiendo prueba de API"
fi
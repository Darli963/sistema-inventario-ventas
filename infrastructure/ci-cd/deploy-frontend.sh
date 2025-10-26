#!/usr/bin/env bash
# Despliega el build del frontend al bucket S3 público y limpia cache de CloudFront

set -e

# Obtener variables desde Terraform outputs
pushd "$(dirname "$0")" >/dev/null
# Estamos en ci-cd/, saltar a infraestructura/terraform
pushd ../infrastructure/terraform >/dev/null
CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
API_URL=$(terraform output -raw api_url || echo "")
popd >/dev/null
popd >/dev/null

echo "📦 Construyendo frontend..."
# Usa npm ci si está disponible; si falla, usa npm install
if command -v npm >/dev/null 2>&1; then
  npm ci || npm install
  npm run build
else
  echo "❌ npm no está instalado en el entorno. Instalalo o ejecuta esta script en un workspace con Node.js."
  exit 1
fi

# Inyectar configuración de API en el build si está disponible
if [ -n "$API_URL" ]; then
  cat > build/config.js <<EOF
// Generado por CI/CD
window.CONFIG = {
  API_BASE_URL: '$API_URL'
};
EOF
  echo "⚙️ API_BASE_URL inyectado en build/config.js: $API_URL"
else
  echo "⚠️ No se pudo obtener api_url de Terraform outputs; se usará localStorage o src/config.js"
fi

echo "☁️ Subiendo a S3: ${FRONTEND_BUCKET}"
# Sin --acl public-read porque el bucket bloquea ACLs públicas y CloudFront (OAI) lee el contenido
aws s3 sync ./build "s3://${FRONTEND_BUCKET}" --delete

echo "🧹 Invalidando cache de CloudFront: ${CLOUDFRONT_DISTRIBUTION_ID}"
aws cloudfront create-invalidation --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" --paths "/*"

echo "✅ Despliegue completado"
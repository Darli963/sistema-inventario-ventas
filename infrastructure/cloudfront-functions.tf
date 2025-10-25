# Funciones de CloudFront para mejoras de seguridad
# Versión del proveedor AWS: ~> 5.0

# Función para agregar headers de seguridad
resource "aws_cloudfront_function" "security_headers" {
  name    = "${local.prefix}-${var.environment}-security-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Función para agregar headers de seguridad a las respuestas"
  publish = true
  code    = <<-EOT
function handler(event) {
    var response = event.response;
    var headers = response.headers;

    // Agregar headers de seguridad
    headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubdomains; preload' };
    headers['content-type-options'] = { value: 'nosniff' };
    headers['x-frame-options'] = { value: 'DENY' };
    headers['x-content-type-options'] = { value: 'nosniff' };
    headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
    headers['permissions-policy'] = { value: 'camera=(), microphone=(), geolocation=()' };
    
    // CSP para aplicaciones React/SPA
    headers['content-security-policy'] = { 
        value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://api.${var.domain_name != null ? (trimspace(var.domain_name) != "" ? var.domain_name : "localhost") : "localhost"}; frame-ancestors 'none';" 
    };

    return response;
}
EOT
}

# Función para redirección de rutas SPA
resource "aws_cloudfront_function" "spa_routing" {
  name    = "${local.prefix}-${var.environment}-spa-routing"
  runtime = "cloudfront-js-1.0"
  comment = "Función para manejar rutas de SPA"
  publish = true
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Si la URI no tiene extensión y no es la raíz, redirigir a index.html
    if (!uri.includes('.') && uri !== '/') {
        request.uri = '/index.html';
    }
    
    // Si es la raíz, asegurar que termine en /
    if (uri === '') {
        request.uri = '/';
    }
    
    return request;
}
EOT
}

# Función para cache busting de assets
resource "aws_cloudfront_function" "cache_control" {
  name    = "${local.prefix}-${var.environment}-cache-control"
  runtime = "cloudfront-js-1.0"
  comment = "Función para optimizar cache de assets"
  publish = true
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Para archivos con hash en el nombre, agregar cache largo
    if (uri.match(/\.[a-f0-9]{8,}\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
        request.headers['cache-control'] = { value: 'public, max-age=31536000, immutable' };
    }
    
    // Para archivos HTML, no cache
    if (uri.match(/\.html?$/)) {
        request.headers['cache-control'] = { value: 'no-cache, no-store, must-revalidate' };
    }
    
    return request;
}
EOT
}
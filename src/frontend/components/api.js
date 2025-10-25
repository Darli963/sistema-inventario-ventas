const getBaseUrl = () => {
  const fromConfig = (typeof window !== 'undefined' && window.CONFIG && window.CONFIG.API_BASE_URL) ? window.CONFIG.API_BASE_URL : '';
  const fromStorage = (typeof localStorage !== 'undefined') ? localStorage.getItem('apiBaseUrl') : '';
  const base = fromConfig || fromStorage || '';
  if (!base) throw new Error('Configura la URL base del API en Configuración');
  return base.replace(/\/$/, '');
};

const jsonHeaders = { 'Content-Type': 'application/json' };

const handle = async (res) => {
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`HTTP ${res.status}: ${text}`);
  }
  const contentType = res.headers.get('content-type') || '';
  if (contentType.includes('application/json')) return res.json();
  return res.text();
};

export const api = {
  // Productos
  getProductos: async () => handle(await fetch(`${getBaseUrl()}/productos`, { method: 'GET' })),
  createProducto: async (producto) => handle(await fetch(`${getBaseUrl()}/productos`, { method: 'POST', headers: jsonHeaders, body: JSON.stringify(producto) })),
  updateProducto: async (id, producto) => handle(await fetch(`${getBaseUrl()}/productos/${encodeURIComponent(id)}`, { method: 'PUT', headers: jsonHeaders, body: JSON.stringify(producto) })),
  deleteProducto: async (id) => handle(await fetch(`${getBaseUrl()}/productos/${encodeURIComponent(id)}`, { method: 'DELETE' })),

  // Inventario
  getInventario: async () => handle(await fetch(`${getBaseUrl()}/inventario`, { method: 'GET' })),

  // Ventas
  createVenta: async (venta) => handle(await fetch(`${getBaseUrl()}/ventas`, { method: 'POST', headers: jsonHeaders, body: JSON.stringify(venta) })),

  // Reportes
  getReportes: async () => handle(await fetch(`${getBaseUrl()}/reportes`, { method: 'GET' })),

  // Health
  getHealth: async () => handle(await fetch(`${getBaseUrl()}/health`, { method: 'GET' })),
};
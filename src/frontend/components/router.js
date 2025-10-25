const mount = (component) => {
  const el = document.getElementById('app');
  el.innerHTML = '';
  component(el);
};

const routes = {
  '/productos': () => import('./productos.js').then(m => m.default),
  '/inventario': () => import('./inventario.js').then(m => m.default),
  '/ventas': () => import('./ventas.js').then(m => m.default),
  '/reportes': () => import('./reportes.js').then(m => m.default),
  '/health': () => import('./health.js').then(m => m.default),
  '/config': () => import('./settings.js').then(m => m.default),
};

const resolveRoute = () => {
  const hash = window.location.hash || '#/productos';
  const path = hash.replace('#', '');
  return routes[path] || routes['/productos'];
};

const render = async () => {
  try {
    const loader = resolveRoute();
    const component = await loader();
    mount(component);
  } catch (e) {
    const el = document.getElementById('app');
    el.innerHTML = `<div class="card alert error">Error cargando la vista: ${e?.message || e}</div>`;
  }
};

window.addEventListener('hashchange', render);
window.addEventListener('DOMContentLoaded', render);
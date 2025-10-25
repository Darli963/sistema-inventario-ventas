import { api } from './api.js';

export default function render(el) {
  el.innerHTML = `
    <div class="card">
      <h2>Estado del sistema</h2>
      <div id="status">Verificando estado...</div>
      <div id="details"></div>
    </div>
  `;

  api.getHealth().then((data) => {
    const ok = typeof data === 'string' ? data : (data?.status || 'OK');
    el.querySelector('#status').innerHTML = `<div class="alert success">${ok}</div>`;
    el.querySelector('#details').innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
  }).catch((err) => {
    el.querySelector('#status').innerHTML = `<div class="alert error">${err.message}</div>`;
  });
}
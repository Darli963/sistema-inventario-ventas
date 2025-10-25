import { api } from './api.js';

export default function render(el) {
  el.innerHTML = `
    <div class="card">
      <h2>Inventario</h2>
      <div class="alert" id="msg"></div>
      <div id="list">Cargando inventario...</div>
    </div>
  `;

  const msg = el.querySelector('#msg');

  api.getInventario().then(items => {
    const data = Array.isArray(items) ? items : items?.data || [];
    const rows = data.map(i => `<tr>
      <td>${i.producto_id ?? ''}</td>
      <td>${i.nombre ?? ''}</td>
      <td>${i.stock ?? ''}</td>
    </tr>`).join('');
    el.querySelector('#list').innerHTML = `<table class="table">
      <thead><tr><th>Producto ID</th><th>Nombre</th><th>Stock</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`;
  }).catch(err => {
    msg.className = 'alert error';
    msg.innerHTML = `Error: ${err.message}`;
    el.querySelector('#list').innerHTML = '';
  });
}
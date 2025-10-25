import { api } from './api.js';

function renderList(el, items) {
  const rows = (items || []).map(p => `<tr>
    <td>${p.id ?? ''}</td>
    <td>${p.nombre ?? ''}</td>
    <td>${p.precio ?? ''}</td>
    <td>${p.categoria ?? ''}</td>
  </tr>`).join('');
  el.querySelector('#list').innerHTML = `<table class="table">
    <thead><tr><th>ID</th><th>Nombre</th><th>Precio</th><th>Categoría</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

export default function render(el) {
  el.innerHTML = `
    <div class="card">
      <h2>Productos</h2>
      <div class="alert" id="msg"></div>
      <div id="list">Cargando productos...</div>
    </div>
    <div class="card">
      <h2>Crear producto</h2>
      <form id="create-form">
        <div style="display:grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap:12px;">
          <label>Nombre<br /><input name="nombre" required /></label>
          <label>Precio<br /><input name="precio" type="number" step="0.01" required /></label>
          <label>Categoría<br /><input name="categoria" /></label>
          <label>Descripción<br /><input name="descripcion" /></label>
        </div>
        <div style="margin-top:12px"><button type="submit">Crear</button></div>
      </form>
    </div>
  `;

  const msg = el.querySelector('#msg');

  const load = () => {
    api.getProductos().then(items => {
      renderList(el, Array.isArray(items) ? items : items?.data || []);
      msg.innerHTML = '';
    }).catch(err => {
      msg.className = 'alert error';
      msg.innerHTML = `Error: ${err.message}`;
      el.querySelector('#list').innerHTML = '';
    });
  };

  load();

  const form = el.querySelector('#create-form');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const producto = Object.fromEntries(fd.entries());
    producto.precio = Number(producto.precio);
    api.createProducto(producto).then(() => {
      msg.className = 'alert success';
      msg.innerHTML = 'Producto creado';
      form.reset();
      load();
    }).catch(err => {
      msg.className = 'alert error';
      msg.innerHTML = `Error: ${err.message}`;
    });
  });
}
import { api } from './api.js';

export default function render(el) {
  el.innerHTML = `
    <div class="card">
      <h2>Registrar venta</h2>
      <div class="alert" id="msg"></div>
      <form id="venta-form">
        <div style="display:grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap:12px;">
          <label>ID Producto<br /><input name="producto_id" required /></label>
          <label>Cantidad<br /><input name="cantidad" type="number" min="1" required /></label>
          <label>Precio unitario<br /><input name="precio" type="number" step="0.01" required /></label>
          <label>Cliente (opcional)<br /><input name="cliente" /></label>
        </div>
        <div style="margin-top:12px"><button type="submit">Registrar</button></div>
      </form>
    </div>
  `;

  const msg = el.querySelector('#msg');
  const form = el.querySelector('#venta-form');

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const venta = Object.fromEntries(fd.entries());
    venta.cantidad = Number(venta.cantidad);
    venta.precio = Number(venta.precio);
    api.createVenta(venta).then(() => {
      msg.className = 'alert success';
      msg.innerHTML = 'Venta registrada correctamente';
      form.reset();
    }).catch(err => {
      msg.className = 'alert error';
      msg.innerHTML = `Error: ${err.message}`;
    });
  });
}
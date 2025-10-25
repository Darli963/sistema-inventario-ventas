import { api } from './api.js';

export default function render(el) {
  el.innerHTML = `
    <div class="card">
      <h2>Reportes</h2>
      <div class="alert" id="msg"></div>
      <div id="content">Cargando reportes...</div>
    </div>
  `;

  const msg = el.querySelector('#msg');

  api.getReportes().then(data => {
    const pretty = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
    el.querySelector('#content').innerHTML = pretty;
  }).catch(err => {
    msg.className = 'alert error';
    msg.innerHTML = `Error: ${err.message}`;
    el.querySelector('#content').innerHTML = '';
  });
}
export default function render(el) {
  const fromConfig = (typeof window !== 'undefined' && window.CONFIG && window.CONFIG.API_BASE_URL) ? window.CONFIG.API_BASE_URL : '';
  const fromStorage = (typeof localStorage !== 'undefined') ? localStorage.getItem('apiBaseUrl') : '';
  const current = fromConfig || fromStorage || '';
  el.innerHTML = `
    <div class="card">
      <h2>Configuración</h2>
      <p>Define la URL base del API (API Gateway o ALB) para las llamadas del frontend.</p>
      <form id="cfg-form">
        <label for="baseUrl">API Base URL</label><br />
        <input id="baseUrl" type="url" placeholder="https://..." value="${current}" style="width:100%" />
        <div style="margin-top:12px; display:flex; gap:8px;">
          <button type="submit">Guardar</button>
          <button type="button" class="secondary" id="clear">Limpiar</button>
        </div>
      </form>
      <div id="msg" style="margin-top:12px;"></div>
    </div>
  `;

  const form = el.querySelector('#cfg-form');
  const msg = el.querySelector('#msg');
  const clearBtn = el.querySelector('#clear');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const v = el.querySelector('#baseUrl').value.trim();
    if (!v) {
      msg.innerHTML = '<div class="alert error">Debe ingresar una URL válida</div>';
      return;
    }
    localStorage.setItem('apiBaseUrl', v);
    msg.innerHTML = '<div class="alert success">Configuración guardada</div>';
  });
  clearBtn.addEventListener('click', () => {
    localStorage.removeItem('apiBaseUrl');
    el.querySelector('#baseUrl').value = fromConfig || '';
    msg.innerHTML = '<div class="alert success">Configuración eliminada; se usará config.js si está definido</div>';
  });
}
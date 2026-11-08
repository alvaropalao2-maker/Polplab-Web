/* ── Polplab · medición (Google Analytics 4) ──────────────────────────────
 *
 * El ID de medición de GA4 vive solo aquí; todas las páginas cargan este
 * archivo, así que para cambiar de propiedad basta con tocar la línea de GA_ID.
 *
 * La guarda de abajo evita cargar nada si el ID vuelve a quedar como marcador.
 * ─────────────────────────────────────────────────────────────────────── */

(function () {
  var GA_ID = 'G-8XTS444KNZ';

  if (GA_ID.indexOf('XXXX') !== -1) return; // aún sin configurar

  var s = document.createElement('script');
  s.async = true;
  s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
  document.head.appendChild(s);

  window.dataLayer = window.dataLayer || [];
  function gtag() { window.dataLayer.push(arguments); }
  window.gtag = gtag;

  gtag('js', new Date());
  gtag('config', GA_ID);

  /* ── Eventos propios ───────────────────────────────────────────────────
   * click_whatsapp  → clic en cualquier enlace a WhatsApp
   * click_demo      → clic en "Ver demo en vivo" / "Ver la tienda en vivo"
   * generate_lead   → envío del formulario de contacto (lo dispara index.html)
   *
   * Para que aparezcan en "Eventos clave" hay que marcarlos como tales en
   * GA4 → Administrar → Eventos. No se envían datos personales.
   * ─────────────────────────────────────────────────────────────────── */
  var DEMOS = {
    'cubo.polplab.com': 'cubo',
    'pisaditas.polplab.com': 'pisaditas',
    'dashboard.polplab.com': 'dashboard',
    'pulenta-frontend.pages.dev': 'pajaza'
  };

  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href]');
    if (!a) return;
    var host = a.hostname;
    var base = { page_path: location.pathname, transport_type: 'beacon' };

    if (host === 'wa.me' || host === 'api.whatsapp.com') {
      base.link_location = a.classList.contains('whatsapp-fab') ? 'boton_flotante' : 'enlace';
      gtag('event', 'click_whatsapp', base);
    } else if (DEMOS[host]) {
      base.project = DEMOS[host];
      gtag('event', 'click_demo', base);
    }
  });
})();

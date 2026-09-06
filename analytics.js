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
})();

# Notas de SEO — Polplab-Web

> Documento de continuidad para retomar el trabajo de SEO desde cualquier máquina,
> sin depender del historial de una conversación concreta de Claude Code.
> Última actualización: **2026-09-06**.

## Contexto del proyecto
- Sitio estático (HTML/CSS/JS plano, sin build step) para **Polplab**, estudio de
  desarrollo de software a medida (Perú / LATAM, remoto).
- Repo: `github.com/alvaropalao2-maker/Polplab-Web`, rama `main`.
- **Hosting: Hostinger, con auto-despliegue conectado al repo.** Un `git push`
  a `main` publica solo — no hace falta subir nada a mano por FTP/panel.
- Identidad de git en este repo (no la global): `Alvaro <alvaropalao2@gmail.com>`,
  coherente con el resto del historial. Si `git commit` falla por "Author identity
  unknown" en una laptop nueva, correr:
  ```
  git config user.name "Alvaro"
  git config user.email "alvaropalao2@gmail.com"
  ```
- La red hacia GitHub ha sido intermitente durante el trabajo (`Empty reply from
  server`, timeouts). Si un `git push` falla así, reintentar — normalmente no llegó
  a aplicarse; comparar `git rev-parse main` (local) con `git ls-remote origin main`
  (remoto) para confirmar antes de asumir que se perdió el commit.

## Punto de partida (auditoría inicial)
El SEO on-page ya estaba muy bien resuelto antes de tocar nada: title/description
únicos por página, canonical, OG/Twitter completos, JSON-LD rico (`ProfessionalService`
+ `WebSite` + `FAQPage` en home; `BlogPosting` + `BreadcrumbList` en cada artículo del
blog; `CreativeWork` en los casos de proyecto), `sitemap.xml`/`robots.txt` correctos,
`.htaccess` con HTTPS+no-www en un salto. Los gaps reales eran de **medición y
rendimiento**, no de contenido.

## Qué se implementó (en orden cronológico)

1. **Medición GA4** — [analytics.js](analytics.js) nuevo, cargado con `defer` desde
   las 9 páginas (`../analytics.js` desde `blog/`). El ID vive en una sola constante
   con una guarda que no carga nada si queda como marcador. **Ya tiene el ID real
   del usuario puesto: `G-8XTS444KNZ`.**
2. **LCP del logo** — se quitó `loading="lazy"` del logo del **navbar** (era
   candidato a LCP) y se añadió `fetchpriority="high"`, en las 9 páginas. Los logos
   del **footer** conservan `loading="lazy"` a propósito.
3. **Capturas de proyecto a WebP** — las 8 imágenes de `capturas/cubo/` y
   `capturas/pisaditas/` se sirven vía `<picture>` con `<source type="image/webp">`
   + fallback `.jpg` (1,79 MB → 0,98 MB, −45%). `og:image`/`twitter:image`/JSON-LD
   siguen apuntando al `.jpg` a propósito (compatibilidad con crawlers sociales).
4. **Favicon corregido** — regenerado a 96×96 con fondo blanco opaco (antes: 64×64
   con transparencia real), recortado sobre el pulpo del logo. `sizes="64x64"` →
   `sizes="96x96"` en las 9 páginas. Causa: Google recomienda favicon cuadrado,
   sólido, múltiplo de 48px — con eso en contra estaba cayendo al icono de globo
   por defecto en resultados de búsqueda en vez de mostrar el logo.
5. **Google Business Profile (GBP) creado y verificado** — categoría "Empresa de
   servicios" (service-area business, sin dirección pública, área Perú/LATAM).
   Verificación instantánea (ya se tenía Search Console verificado por el mismo
   dominio/cuenta). Descripción y fotos (logo, `og-image.png`, `card.jpg` de cada
   proyecto) ya subidas por el usuario.
6. **Número de contacto unificado (NAP)** — el GBP se creó con un teléfono distinto
   al que tenía la web. Se corrigió: **todo el sitio y el GBP usan ahora
   `+51 965 485 460`** (antes era `980 857 382`) — botón flotante de WhatsApp en las
   9 páginas, `telephone` + `url` (wa.me) del JSON-LD en `index.html`, y el enlace
   de contacto en `privacidad.html`.
7. **`sameAs` del schema enlazado al GBP** — se añadió
   `https://share.google/kCPjcK9ywGg0JKCAN` (link de "Compartir" del Perfil de
   Empresa) al array `sameAs` del `ProfessionalService` en `index.html`, junto a
   Instagram/LinkedIn/YouTube/TikTok. Ese link resuelve a un **Knowledge Graph ID
   propio para "Polplab"**: `kgmid=/g/11zfkk6qmd` — confirma que Google ya la
   reconoce como entidad distinta.

Cada punto de esta lista quedó **commiteado, pusheado y verificado en vivo en
`polplab.com`** (no solo en local) antes de darlo por cerrado.

## Hallazgo relevante sin acción de código posible
Buscar "polplab" en Google mostraba primero **POPLab** (poplab.mx, medio de
periodismo mexicano con más autoridad) con corrección ortográfica automática, antes
que el sitio de Polplab. No es un fallo técnico de la web ni cosa que se arregle con
código: es que Google todavía no tenía suficiente confianza en "Polplab" como
entidad propia. Los pasos 5-7 de arriba (GBP + NAP + `sameAs`) son exactamente la
respuesta a esto — construir señales de entidad — y son la explicación de por qué
se hizo esa serie de cambios.

## Pendiente / próximos pasos
- [ ] **Pedir reseñas a los clientes reales** (Cubo, Pisaditas) para el GBP — ya
      tienen testimonios en la propia home, es cuestión de convertirlos en reseñas
      de Google. Es lo que más rápido suma confianza visible en el resultado de
      búsqueda.
- [ ] **Confirmar en Search Console → Sitemaps** que `sitemap.xml` está enviado y
      sin errores (nunca se verificó el estado exacto dentro de la cuenta, solo que
      el archivo es accesible y está declarado en `robots.txt`).
- [ ] **Pedir indexación manual de la home** en Search Console → Inspección de URLs,
      para acelerar que Google recoja el favicon nuevo y las señales de entidad
      reforzadas.
- [ ] **Medir con PageSpeed Insights** (home y `proyecto-cubo.html`, la página con
      más peso de imágenes) ahora que WebP + fix del logo están en producción, para
      confirmar la mejora real de Core Web Vitals.
- [ ] **Backlinks/citaciones de marca**: perfiles en directorios de agencias de
      software (Clutch, GoodFirms) con el nombre exacto "Polplab", mismo patrón que
      el GBP — cada mención consistente ayuda más a la entidad.
- [ ] **Mantener cadencia del blog** (hoy: 3 artículos, buena profundidad cada uno)
      — es lo que sostiene tráfico orgánico a medio plazo.
- [ ] Si el usuario vuelve a cambiar el ID de GA4 en el futuro: `analytics.js` se
      cachea 1 día (`max-age=86400` en `.htaccess`); añadir `?v=2` al `<script src>`
      en las 9 páginas para forzar la actualización si hace falta que sea inmediata.

## Cómo retomar esto en una sesión/laptop nueva
1. `git clone https://github.com/alvaropalao2-maker/Polplab-Web.git` (o `git pull`
   si ya está clonado) — trae todo el código ya al día.
2. Pedirle a Claude que lea este archivo (`SEO-NOTES.md`) para tener el contexto
   completo sin necesitar el historial de chat original.
3. Los cambios se publican solos al hacer `push` a `main` (auto-deploy de
   Hostinger) — no hace falta subir nada manualmente.

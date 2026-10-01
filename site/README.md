# Cronos — sitio web

Landing + descarga + términos de [Cronos](../README.md), en [Astro](https://astro.build), lista para Vercel.

```bash
cd site
npm install
npm run dev      # http://localhost:4321
npm run build
```

## Páginas

| Ruta | Qué es |
|---|---|
| `/` | Landing (hero con video, capas, funciones, galería, privacidad, newsletter, otros productos) |
| `/descargar` | Descarga directa del APK + pasos de instalación |
| `/terminos` | Términos y condiciones, privacidad, cookies y newsletter |
| `/api/newsletter` | Función serverless (POST) que envía el correo de bienvenida por SMTP |

## Descarga del APK

`src/data/downloads.ts` apunta a `https://github.com/ale-fcastro/cronos/releases/latest/download/app-release.apk`.
Publicar un release nuevo en GitHub actualiza el botón **sin redeploy**. Solo el texto de versión/tamaño
(`release.version`, `release.size`) es manual. El asset del release se tiene que seguir llamando `app-release.apk`.

## Newsletter (variables de entorno)

Configurar en Vercel → Settings → Environment Variables (ver `.env.example`):

| Variable | Requerida | Ejemplo |
|---|---|---|
| `EMAIL_HOST` | sí | `smtp.tu-proveedor.com` |
| `EMAIL_PORT` | no (587) | `587` o `465` |
| `EMAIL_USE_TLS` | no (true) | `true` |
| `EMAIL_HOST_USER` | sí | usuario SMTP |
| `EMAIL_HOST_PASSWORD` | sí | contraseña SMTP |
| `DEFAULT_FROM_EMAIL` | no | `Cronos <hola@tu-dominio>` (por defecto = usuario) |
| `NEWSLETTER_NOTIFY_TO` | no | tu correo: te llega un aviso por cada suscripción |

Sin `EMAIL_HOST`/`USER`/`PASSWORD` el formulario responde 503 con un mensaje amable. El endpoint tiene honeypot,
validación, consentimiento obligatorio y rate limit básico. No hay base de datos: la lista de suscriptores son
los avisos que llegan a `NEWSLETTER_NOTIFY_TO`.

## Contenido y diseño

- Textos: `src/data/content.ts` · redes/autor/otros productos: `src/data/social.ts`
- Colores = `lib/shared/theme/app_colors.dart` (en `src/styles/global.css`), tipografía IBM Plex
- Logo: `src/components/Logo.astro` · Croni (SVG animado, port de `cronos_mascot.dart`): `src/components/Croni.astro`
- Capturas y video reales del emulador: `public/media/` · imagen social: `public/og.png`

## Deploy en Vercel

Importar el repo, **Root Directory = `site`**, framework Astro (autodetectado). Cambiar `site` en
`astro.config.mjs` si el dominio final no es `cronos-fcastro.vercel.app`.

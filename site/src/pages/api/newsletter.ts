import type { APIRoute } from 'astro';
import { mailConfig, normalizeEmail, transport, welcomeEmail } from '../../lib/mail';

export const prerender = false;

// Throttle por instancia (best-effort; las funciones serverless viven poco).
const hits = new Map<string, number[]>();
function limited(key: string, max = 5, windowMs = 10 * 60_000) {
  const now = Date.now();
  const recent = (hits.get(key) ?? []).filter((t) => now - t < windowMs);
  recent.push(now);
  hits.set(key, recent);
  return recent.length > max;
}

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
  });

export const POST: APIRoute = async ({ request, clientAddress, site }) => {
  let data: Record<string, unknown>;
  try {
    data = await request.json();
  } catch {
    return json(400, { ok: false, error: 'Solicitud inválida.' });
  }

  // Honeypot: las personas nunca llenan el campo oculto "company".
  if (typeof data.company === 'string' && data.company.length > 0) return json(200, { ok: true });

  const email = normalizeEmail(data.email);
  if (!email) return json(422, { ok: false, error: 'Escribe un correo válido.' });
  if (data.consent !== true) return json(422, { ok: false, error: 'Acepta recibir correos para suscribirte.' });

  let ip = 'unknown';
  try {
    ip = clientAddress;
  } catch {
    // no disponible en algunos runtimes
  }
  if (limited(ip)) return json(429, { ok: false, error: 'Demasiados intentos. Prueba de nuevo en unos minutos.' });

  const config = mailConfig();
  if (!config) {
    console.error('newsletter: SMTP no configurado (faltan variables EMAIL_*)');
    return json(503, { ok: false, error: 'Las suscripciones no están disponibles ahora. Prueba más tarde.' });
  }

  const siteUrl = (site?.toString() ?? new URL(request.url).origin).replace(/\/$/, '');
  const mailer = transport(config);
  try {
    await mailer.sendMail({ from: config.from, to: email, ...welcomeEmail(siteUrl) });
    if (config.notifyTo) {
      await mailer.sendMail({
        from: config.from,
        to: config.notifyTo,
        replyTo: email,
        subject: `Cronos newsletter: ${email}`,
        text: `Nueva suscripción\n\nEmail: ${email}\nCuándo: ${new Date().toISOString()}\nUser agent: ${request.headers.get('user-agent') ?? '-'}`,
      });
    }
    return json(200, { ok: true });
  } catch (err) {
    console.error('newsletter: fallo al enviar', err);
    return json(502, { ok: false, error: 'No pudimos enviar el correo de confirmación. Prueba más tarde.' });
  } finally {
    mailer.close();
  }
};

export const ALL: APIRoute = () => json(405, { ok: false, error: 'Método no permitido.' });

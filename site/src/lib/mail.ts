import nodemailer from 'nodemailer';

export interface MailConfig {
  host: string;
  port: number;
  secure: boolean;
  requireTLS: boolean;
  user: string;
  pass: string;
  from: string;
  notifyTo?: string;
}

type Env = Record<string, string | undefined>;

/** Lee las variables EMAIL_* (estilo Django). Devuelve null si el SMTP no está configurado. */
export function mailConfig(env: Env = process.env): MailConfig | null {
  const host = env.EMAIL_HOST;
  const user = env.EMAIL_HOST_USER;
  const pass = env.EMAIL_HOST_PASSWORD;
  if (!host || !user || !pass) return null;
  const port = Number(env.EMAIL_PORT ?? 587);
  const tls = /^(1|true|yes)$/i.test(env.EMAIL_USE_TLS ?? 'true');
  return {
    host,
    port,
    secure: port === 465, // TLS implícito; 587 sube con STARTTLS
    requireTLS: tls && port !== 465,
    user,
    pass,
    from: env.DEFAULT_FROM_EMAIL || user,
    notifyTo: env.NEWSLETTER_NOTIFY_TO || undefined,
  };
}

export function transport(c: MailConfig) {
  return nodemailer.createTransport({
    host: c.host,
    port: c.port,
    secure: c.secure,
    requireTLS: c.requireTLS,
    auth: { user: c.user, pass: c.pass },
    connectionTimeout: 10_000,
    greetingTimeout: 10_000,
    socketTimeout: 15_000,
  });
}

const EMAIL_RE = /^[^\s@<>()[\]\\,;:"]+@[^\s@<>()[\]\\,;:"]+\.[a-z]{2,}$/i;

export function normalizeEmail(input: unknown): string | null {
  if (typeof input !== 'string') return null;
  const email = input.trim().toLowerCase();
  if (email.length > 254 || !EMAIL_RE.test(email)) return null;
  return email;
}

const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);

export function welcomeEmail(siteUrl: string) {
  const subject = 'Ya estás en el newsletter de Cronos';
  const text = [
    '¡Gracias por suscribirte al newsletter de Cronos!',
    '',
    'Te escribiremos solo cuando salga una versión nueva o algo que valga la pena contar.',
    '',
    `Descarga la app: ${siteUrl}/descargar`,
    '',
    'Recibiste este correo porque esta dirección se ingresó en el sitio de Cronos.',
    'Si no fuiste tú, ignóralo y no volverás a saber de nosotros.',
  ].join('\n');
  const html = `<!doctype html><html><body style="margin:0;background:#121316;font-family:'IBM Plex Sans',system-ui,-apple-system,Segoe UI,sans-serif;color:#e8e9ed">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:40px 16px">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#1b1d21;border:1px solid #2c2e34;border-radius:12px">
<tr><td style="padding:32px 32px 8px"><p style="margin:0;font-family:'IBM Plex Mono',monospace;font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#9db1f5">Cronos · Newsletter</p>
<h1 style="margin:12px 0 0;font-size:26px;line-height:1.2;font-weight:600;color:#e8e9ed">Ya estás en la lista.</h1></td></tr>
<tr><td style="padding:16px 32px;font-size:15px;line-height:1.6;color:#9aa0ab">
<p style="margin:0 0 16px">Croni te escribirá solo cuando salga una versión nueva o algo que valga la pena contar. Nada de spam.</p>
<p style="margin:0">Tus datos de Cronos siguen en tu teléfono. Este correo es lo único que guardamos, y solo para avisarte.</p></td></tr>
<tr><td style="padding:8px 32px 32px"><a href="${esc(siteUrl)}/descargar" style="display:inline-block;padding:12px 22px;border-radius:6px;background:#9db1f5;color:#121316;text-decoration:none;font-family:'IBM Plex Mono',monospace;font-size:13px;text-transform:uppercase">Descargar Cronos</a></td></tr>
</table>
<p style="max-width:560px;margin:16px auto 0;font-size:12px;line-height:1.5;color:#6a6f79">Recibiste este correo porque esta dirección se ingresó en el sitio de Cronos. Si no fuiste tú, ignóralo y no volverás a saber de nosotros.</p>
</td></tr></table></body></html>`;
  return { subject, text, html };
}

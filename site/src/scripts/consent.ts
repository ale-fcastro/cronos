// Estado del consentimiento de cookies. Cualquier script de analítica futuro
// debe revisar readConsent() o escuchar el evento "cronos:consent" antes de cargar.

export interface Consent {
  v: 1;
  necessary: true;
  analytics: boolean;
  at: string;
}

const KEY = 'cronos-consent';

export function readConsent(): Consent | null {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Consent;
    return parsed?.v === 1 ? parsed : null;
  } catch {
    return null;
  }
}

export function writeConsent(analytics: boolean): Consent {
  const consent: Consent = { v: 1, necessary: true, analytics, at: new Date().toISOString() };
  try {
    localStorage.setItem(KEY, JSON.stringify(consent));
  } catch {
    // almacenamiento bloqueado: la elección aplica solo a esta vista
  }
  window.dispatchEvent(new CustomEvent<Consent>('cronos:consent', { detail: consent }));
  return consent;
}

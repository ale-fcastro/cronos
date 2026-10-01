// Fuente única de descargas. El botón apunta a /releases/latest/download/<asset>,
// así que publicar un release nuevo en GitHub actualiza el sitio sin redeploy.
// Mantener sincronizado con `version` de pubspec.yaml solo para el texto.

export const REPO_URL = 'https://github.com/ale-fcastro/cronos';
export const RELEASES_URL = `${REPO_URL}/releases`;
export const APK_ASSET = 'app-release.apk';
export const APK_URL = `${RELEASES_URL}/latest/download/${APK_ASSET}`;
export const GUIDE_URL = `${REPO_URL}/raw/main/Guia_de_Uso_Cronos.pdf`;

export const release = {
  version: 'v0.13.0',
  size: '74 MB',
  minAndroid: 'Android 7.0+',
};

export const platforms = [
  { id: 'android', name: 'Android', detail: 'Teléfono · APK firmado', available: true, status: 'Disponible' },
  { id: 'wear', name: 'Wear OS', detail: 'Reloj · se instala desde el teléfono', available: false, status: 'En desarrollo' },
  { id: 'ios', name: 'iOS', detail: 'iPhone', available: false, status: 'Aún no disponible' },
];

export const installSteps = [
  ['Descarga el APK', 'Toca el botón de descarga. El archivo baja directo desde GitHub Releases.'],
  ['Permite la instalación', 'Android te pedirá permitir “instalar apps desconocidas” para tu navegador. Es normal para apps fuera de Play Store.'],
  ['Abre Cronos', 'Croni te recibe con un tour corto. Sin cuenta, sin registro.'],
  ['Actualizaciones', 'Cronos revisa solo si hay versión nueva y se actualiza sin salir de la app.'],
];

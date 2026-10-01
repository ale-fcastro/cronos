// Contenido de la landing de Cronos. Copy real basado en README.md y la app.

export const site = {
  name: 'Cronos',
  title: 'Cronos — El sistema operativo personal de tu tiempo',
  description:
    'Cronos mide qué haces con tu tiempo: tareas con cronómetro, agenda, actividades y un score diario. Gratis para Android, sin cuenta y con tus datos solo en tu teléfono.',
};

export const nav = [
  { label: 'Cómo funciona', href: '/#como-funciona' },
  { label: 'Funciones', href: '/#funciones' },
  { label: 'Privacidad', href: '/#privacidad' },
  { label: 'Novedades', href: '/#newsletter' },
];

export const shots = {
  hoy: '/media/hoy.webp',
  agenda: '/media/agenda.webp',
  mes: '/media/mes.webp',
  tareas: '/media/tareas.webp',
  detalle: '/media/detalle.webp',
  registrar: '/media/registrar.webp',
  analizar: '/media/analizar.webp',
  analizar2: '/media/analizar2.webp',
  onboarding: '/media/onboarding.webp',
};

// Franja de "principios" (en lugar de logos de clientes).
export const principles = [
  { k: 'Sin cuenta', v: 'Abres y usas. Nada de registros.' },
  { k: 'Sin servidor', v: 'Todo vive en SQLite, en tu teléfono.' },
  { k: 'Sin IA propia', v: 'Tú decides a qué IA darle tus datos.' },
  { k: 'Sin anuncios', v: 'Gratis, sin publicidad ni rastreo.' },
  { k: 'Exportable', v: 'CSV, JSON, PDF o backup completo.' },
];

// Capas de la pila isométrica (sección scroll-driven).
export const layers = [
  {
    n: '01', label: 'REGISTRAR', title: 'Registra en 2 toques',
    text: 'Tareas, actividades e imprevistos desde un solo botón, con sugerencias de tu historial.',
    color: 'var(--accent)', ann: ['BOTÓN +', 'SUGERENCIAS'], shot: 'registrar',
  },
  {
    n: '02', label: 'MEDIR', title: 'Mide lo real',
    text: 'Cronómetro por tarea, estimado contra real y sesiones. Una sola tarea en curso a la vez.',
    color: 'var(--warning)', ann: ['CRONÓMETRO', 'ESTIMADO VS REAL'], shot: 'detalle',
  },
  {
    n: '03', label: 'ORGANIZAR', title: 'Ve tu día entero',
    text: 'Línea de tiempo con tareas, actividades, eventos y huecos libres, y un mapa de calor del mes.',
    color: 'var(--success)', ann: ['LÍNEA DE TIEMPO', 'MAPA DE CALOR'], shot: 'agenda',
  },
  {
    n: '04', label: 'ENTENDER', title: 'Entiende tu semana',
    text: 'Score diario, tiempo productivo y perdido, y uso real del teléfono. Sin adivinar.',
    color: 'var(--danger)', ann: ['SCORE DIARIO', 'USO DEL TELÉFONO'], shot: 'analizar2',
  },
] as const;

export interface Feature {
  title: string;
  text: string;
  bullets: string[];
  shot: keyof typeof shots;
}

export const features: Feature[] = [
  {
    title: 'Hoy',
    text: 'Tu día en una pantalla: score, tiempo productivo y perdido, la tarea en curso con cronómetro vivo y el siguiente bloque.',
    bullets: ['Score del día', 'Cronómetro vivo', 'Últimos 7 días'],
    shot: 'hoy',
  },
  {
    title: 'Tareas',
    text: 'Prioridades P1–P3, subtareas, tareas recurrentes y estimado contra real. Al finalizar, Cronos pregunta si de verdad se hizo.',
    bullets: ['Subtareas', 'Recurrentes', 'Estimado vs real'],
    shot: 'tareas',
  },
  {
    title: 'Agenda',
    text: 'Una línea de tiempo con tareas, actividades, eventos y huecos libres. Importa tu calendario desde un archivo .ics.',
    bullets: ['Línea de tiempo', 'Mapa de calor', 'Importar .ics'],
    shot: 'agenda',
  },
  {
    title: 'Actividades',
    text: 'Dormir, comer, ejercicio, redes… con cronómetro. Cada categoría cuenta como productiva, de ocio o neutra.',
    bullets: ['Tipos propios', 'Productiva / ocio', 'Sueño'],
    shot: 'registrar',
  },
  {
    title: 'Analizar',
    text: 'Métricas de la semana o el mes, eventos, tareas y el uso real del teléfono. Comparte un resumen con la IA que ya tengas.',
    bullets: ['Semana / mes', 'Uso del teléfono', 'Resumen para tu IA'],
    shot: 'analizar',
  },
  {
    title: 'Mes',
    text: 'Mapa de calor del mes con tu score de cada día. Toca cualquier día y abre su agenda real.',
    bullets: ['Score por día', 'Navegable', 'Día a día'],
    shot: 'mes',
  },
];

export const products = [
  {
    group: 'Planificar',
    items: [
      ['frame', 'Tareas y subtareas', 'Prioridades P1–P3 y checklist que bloquea finalizar'],
      ['trend', 'Tareas recurrentes', 'Diarias o por día de la semana'],
      ['calendar', 'Importar calendario', 'Trae eventos desde un archivo .ics'],
    ],
  },
  {
    group: 'Medir',
    items: [
      ['clock', 'Cronómetro', 'Por tarea y por actividad, uno a la vez'],
      ['chart', 'Score diario', 'Cumplimiento, eficiencia, sueño y puntualidad'],
    ],
  },
  {
    group: 'Proteger',
    items: [
      ['shield', 'Bloqueo biométrico', 'Huella, cara o PIN del sistema'],
      ['download', 'Exportar y backup', 'CSV, JSON, PDF o copia restaurable'],
    ],
  },
] as const;

export const privacyPoints = [
  ['100% local', 'Tus datos viven en una base SQLite dentro del teléfono.'],
  ['Sin cuenta', 'No hay registro, ni correo, ni contraseña.'],
  ['Sin servidor', 'Cronos no tiene backend. No hay nada que hackear.'],
  ['Tus datos, tu salida', 'Exporta en CSV, JSON o PDF, o haz un backup completo.'],
  ['Actualizaciones', 'Revisa GitHub Releases y se actualiza sin salir de la app.'],
];

export const footerNav = [
  {
    title: 'Producto',
    links: [
      { href: '/#funciones', label: 'Funciones' },
      { href: '/descargar', label: 'Descargar' },
      { href: '/#newsletter', label: 'Newsletter' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { href: '/terminos', label: 'Términos y condiciones' },
      { href: '/terminos#privacidad', label: 'Privacidad' },
      { cookies: true, label: 'Ajustes de cookies' },
    ],
  },
] as const;

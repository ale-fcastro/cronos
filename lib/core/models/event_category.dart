/// Categorías de Evento del sistema (imprevistos e interrupciones).
///
/// Única fuente de verdad: las usa tanto el registro manual de eventos desde
/// el FAB como la pausa justificada de una tarea (core/services/timer_service.dart).
const eventCategories = [
  'Interrupción',
  'Imprevisto',
  'Administrativo',
  'Social',
  'Traslado',
  'Espera',
];

/// Motivos al interrumpir el sueño (parar la actividad "Dormir" antes de
/// tiempo). Contemplan la realidad de dormir mal, no solo despertar sano.
const sleepInterruptionReasons = [
  'Pesadilla',
  'Ruido',
  'Necesidad fisiológica',
  'Desperté naturalmente',
  'Alarma',
  'Otro',
];

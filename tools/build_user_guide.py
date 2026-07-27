# -*- coding: utf-8 -*-
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
    TableStyle, NextPageTemplate, PageBreak, HRFlowable
)
from reportlab.platypus.flowables import Flowable

PAGE_W, PAGE_H = A4

BG = HexColor('#2A3475')
RING = HexColor('#4C63D2')
ACCENT = HexColor('#4C63D2')
TEXT = HexColor('#1C1E26')
TEXT_LIGHT = HexColor('#5A5F6B')
CALLOUT_BG = HexColor('#F4F6FB')
RULE = HexColor('#E2E5EC')

OUT = 'Guia_de_Uso_Cronos.pdf'

styles = getSampleStyleSheet()

h1 = ParagraphStyle('h1', fontName='Helvetica-Bold', fontSize=20, leading=24,
                     textColor=ACCENT, spaceAfter=4)
body = ParagraphStyle('body', fontName='Helvetica', fontSize=10.3, leading=15,
                       textColor=TEXT, spaceAfter=8)
bullet = ParagraphStyle('bullet', parent=body, leftIndent=14, bulletIndent=0,
                         spaceAfter=6)
callout_title = ParagraphStyle('callout_title', fontName='Helvetica-Bold',
                                fontSize=10.5, leading=14, textColor=ACCENT,
                                spaceAfter=4, spaceBefore=6)
callout_body = ParagraphStyle('callout_body', fontName='Helvetica', fontSize=10,
                               leading=14, textColor=TEXT)
idx_num = ParagraphStyle('idx_num', fontName='Helvetica-Bold', fontSize=11,
                          leading=16, textColor=ACCENT)
idx_label = ParagraphStyle('idx_label', fontName='Helvetica', fontSize=11,
                            leading=16, textColor=TEXT)
table_label = ParagraphStyle('table_label', fontName='Helvetica-Bold',
                              fontSize=10.3, leading=14, textColor=TEXT)
table_body = ParagraphStyle('table_body', fontName='Helvetica', fontSize=10.3,
                             leading=14.5, textColor=TEXT)
credit_style = ParagraphStyle('credit', fontName='Helvetica', fontSize=9,
                               leading=13, textColor=TEXT_LIGHT,
                               alignment=TA_CENTER)


def para(text):
    return Paragraph(text, body)


def bul(lead, text):
    inner = f'<b>{lead}</b> {text}' if lead else text
    return Paragraph(f'&bull;&nbsp;&nbsp;{inner}', bullet)


def callout(title, text):
    return Table(
        [[Paragraph(title, callout_title)], [Paragraph(text, callout_body)]],
        colWidths=[166 * mm],
        style=TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), CALLOUT_BG),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (0, 0), 10),
            ('BOTTOMPADDING', (0, 1), (0, 1), 10),
            ('TOPPADDING', (0, 1), (0, 1), 0),
        ]),
    )


def section_heading(number, title):
    return [
        Paragraph(f'{number}. {title}', h1),
        HRFlowable(width='100%', thickness=1, color=RULE, spaceAfter=14),
    ]


def info_table(rows):
    data = [[Paragraph(f'<b>{k}</b>', table_label), Paragraph(v, table_body)] for k, v in rows]
    return Table(
        data,
        colWidths=[38 * mm, 122 * mm],
        style=TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LINEBELOW', (0, 0), (-1, -2), 0.6, RULE),
            ('TOPPADDING', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ]),
    )


class CoverPage(Flowable):
    """Dibuja la tapa entera (fondo, anillo y textos) a mano sobre el canvas,
    replicando la portada original a partir de las coordenadas medidas en
    el PDF anterior."""

    def __init__(self):
        super().__init__()
        self.width = PAGE_W
        self.height = PAGE_H

    def draw(self):
        c = self.canv
        c.setFillColor(BG)
        c.rect(-4, -4, PAGE_W + 8, PAGE_H + 8, fill=1, stroke=0)

        cx, cy = PAGE_W / 2, 662.6
        c.setFillColor(RING)
        c.circle(cx, cy, 207.7, fill=1, stroke=0)
        c.setFillColor(BG)
        c.circle(cx, cy, 147.2, fill=1, stroke=0)

        c.setFillColor(HexColor('#FFFFFF'))
        c.setFont('Helvetica-Bold', 34)
        c.drawCentredString(cx, 603, 'Cronos')
        c.setFillColor(HexColor('#E7E9F5'))
        c.setFont('Helvetica', 15)
        c.drawCentredString(cx, 575, 'Guía de uso')

        c.setFillColor(HexColor('#DADFF3'))
        c.setFont('Helvetica', 13)
        c.drawCentredString(cx, 303, 'Para saber qué hacés con tu tiempo,')
        c.drawCentredString(cx, 280, 'y decidir mejor qué hacer con tu vida.')

        c.setFillColor(HexColor('#B9C0E0'))
        c.setFont('Helvetica', 9.5)
        c.drawCentredString(cx, 254, 'Escrita por Francisco Castro.')


def draw_content_chrome(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(ACCENT)
    canvas.rect(0, PAGE_H - 7, PAGE_W, 7, fill=1, stroke=0)
    canvas.setFont('Helvetica', 8.5)
    canvas.setFillColor(TEXT_LIGHT)
    canvas.drawString(22 * mm, 14 * mm, 'Cronos — Guía de uso')
    canvas.drawRightString(PAGE_W - 22 * mm, 14 * mm, f'Página {doc.page - 1}')
    canvas.restoreState()


def draw_cover_chrome(canvas, doc):
    pass


doc = BaseDocTemplate(
    OUT, pagesize=A4,
    leftMargin=22 * mm, rightMargin=22 * mm,
    topMargin=26 * mm, bottomMargin=20 * mm,
)

cover_frame = Frame(0, 0, PAGE_W, PAGE_H, id='cover', leftPadding=0, rightPadding=0,
                     topPadding=0, bottomPadding=0)
content_frame = Frame(doc.leftMargin, doc.bottomMargin,
                       doc.width, doc.height, id='content')

doc.addPageTemplates([
    PageTemplate(id='Cover', frames=[cover_frame], onPage=draw_cover_chrome),
    PageTemplate(id='Content', frames=[content_frame], onPage=draw_content_chrome),
])

story = []

# ---------- Cover ----------
story.append(CoverPage())
story.append(NextPageTemplate('Content'))
story.append(PageBreak())

# ---------- Índice ----------
index_items = [
    ('1', '¿Qué es Cronos?'),
    ('2', 'Antes de empezar'),
    ('3', 'Cómo se mueve la app'),
    ('4', 'La pantalla Hoy'),
    ('5', 'El botón + : registrar en dos toques'),
    ('6', 'La Agenda'),
    ('7', 'La pantalla Tareas'),
    ('8', 'Analizar: entender tus números'),
    ('9', 'Configuración'),
    ('10', 'Actualizaciones automáticas'),
    ('11', 'Tus datos son tuyos (privacidad y respaldo)'),
    ('12', 'Preguntas frecuentes'),
]
story.append(Paragraph('Índice', h1))
story.append(HRFlowable(width='100%', thickness=1, color=RULE, spaceAfter=14))
idx_rows = [[Paragraph(n, idx_num), Paragraph(t, idx_label)] for n, t in index_items]
story.append(Table(idx_rows, colWidths=[12 * mm, 148 * mm], style=TableStyle([
    ('TOPPADDING', (0, 0), (-1, -1), 5),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ('LEFTPADDING', (0, 0), (-1, -1), 0),
])))
story.append(PageBreak())

# ---------- 1. ¿Qué es Cronos? ----------
story += section_heading(1, '¿Qué es Cronos?')
story.append(para(
    'Cronos no es una lista de tareas ni un cronómetro más. Es una libreta que '
    'registra dos cosas al mismo tiempo: lo que planeaste hacer, y lo que '
    'realmente pasó en tu día.'))
story.append(para(
    'La idea es simple: si anotás con qué se te va el tiempo — trabajo, estudio, '
    'descanso, imprevistos — con el tiempo vas a poder ver patrones claros: en '
    'qué te distraés, qué tan seguido cumplís lo que planeaste, y en qué áreas '
    'de tu vida estás invirtiendo más o menos tiempo del que creías.'))
story.append(Spacer(1, 4))
story.append(callout(
    'La idea en una frase',
    '"Quiero saber qué hago, para saber qué voy a hacer con mi vida." Cronos '
    'junta los datos; las decisiones las seguís tomando vos.'))
story.append(Spacer(1, 10))
story.append(para('Dentro de la app vas a trabajar con tres tipos de registro:'))
story.append(bul('Tareas:', 'cosas planificadas de antemano ("Terminar el informe", "Llamar al '
                             'banco"). Tienen fecha, hora y un tiempo estimado.'))
story.append(bul('Actividades:', 'cosas de la vida diaria que se repiten pero no se "planifican" '
                                  'cada vez (dormir, comer, hacer ejercicio, redes sociales). Se '
                                  'inician y se detienen con un toque.'))
story.append(bul('Eventos:', 'imprevistos que te sacaron de tu plan (un corte de luz, una '
                              'llamada inesperada, tráfico). Sirven para explicar por qué el día '
                              'no salió como pensabas.'))
story.append(PageBreak())

# ---------- 2. Antes de empezar ----------
story += section_heading(2, 'Antes de empezar')
story.append(para(
    'La primera vez que abrís Cronos, un pequeño personaje llamado Croni te da '
    'una bienvenida de cuatro pantallas explicando la idea general. Podés tocar '
    '"Omitir" arriba a la derecha si querés saltarla, y volver a verla cuando '
    'quieras desde Configuración → Ayuda → "Ver guía de bienvenida".'))
story.append(Paragraph('Permisos que te puede pedir', callout_title))
story.append(para(
    'Cronos solo pide un permiso si vos activás la función que lo necesita — '
    'nunca de entrada. Estos son los que te va a preguntar, y por qué:'))
story.append(bul('Notificaciones:', 'si querés que te avise cuando empieza una tarea que '
                                     'planificaste, o si se te venció una sin arrancarla. Se '
                                     'activa desde Configuración → Notificaciones.'))
story.append(bul('Huella dactilar / PIN del teléfono:', 'si querés que la app pida tu huella '
                                                          'para abrirse, como un candado extra. Se activa desde '
                                                          'Configuración → Seguridad.'))
story.append(bul('Acceso al uso del teléfono:', 'solo si querés vincular una tarea con una app '
                                                 '(por ejemplo, "Estudiar" con Duolingo) para que Cronos note sola '
                                                 'si la usaste, o si querés ver tu tiempo de pantalla en Analizar. '
                                                 'Este permiso se concede desde los Ajustes del sistema, no desde '
                                                 'un cartel común — la app te lleva directo ahí cuando hace falta.'))
story.append(Spacer(1, 4))
story.append(callout('Nada es obligatorio',
                      'Podés usar Cronos entero sin activar ninguno de estos tres permisos. '
                      'Solo desbloquean funciones extra.'))
story.append(PageBreak())

# ---------- 3. Cómo se mueve la app ----------
story += section_heading(3, 'Cómo se mueve la app')
story.append(para('Abajo de la pantalla siempre vas a tener estos cinco botones:'))
for label, desc in [
    ('Hoy', 'El resumen de tu día: cómo vas, qué tenés encima, qué sigue.'),
    ('Agenda', 'La línea de tiempo del día, y un calendario del mes.'),
    ('+ (centro)', 'El botón para anotar algo nuevo: tarea, actividad o evento, en dos toques.'),
    ('Tareas', 'La lista completa de tus tareas: hoy, esta semana, o todas.'),
    ('Analizar', 'Gráficos y números sobre cómo estás usando tu tiempo.'),
]:
    story.append(bul(label + ':', desc))
story.append(Spacer(1, 4))
story.append(para('Tocá el avatar (tu foto, arriba a la derecha en Hoy) para entrar a '
                   'Configuración en cualquier momento.'))
story.append(PageBreak())

# ---------- 4. La pantalla Hoy ----------
story += section_heading(4, 'La pantalla Hoy')
story.append(para(
    'Es lo primero que ves al abrir Cronos. Está pensada para responderte '
    '"¿cómo va mi día?" en tres segundos, sin tener que buscar nada:'))
story.append(bul('', 'Un puntaje del día (0 a 100) que resume qué tan bien te fue: cuánto '
                      'cumpliste, qué tan eficiente fuiste, si dormiste lo suficiente y si '
                      'llegaste a horario.'))
story.append(bul('', 'Cuatro números clave: eficiencia, tareas cumplidas, tiempo trabajado y '
                      'horas de sueño.'))
story.append(bul('', 'Si tenés una tarea o actividad en curso, aparece arriba con su '
                      'cronómetro corriendo. Podés pausarla desde ahí mismo.'))
story.append(bul('', 'La próxima tarea planificada, para que sepas qué sigue.'))
story.append(bul('', 'Un gráfico chico con tu puntaje de los últimos 7 días.'))
story.append(PageBreak())

# ---------- 5. El botón + ----------
story += section_heading(5, 'El botón + : registrar en dos toques')
story.append(para(
    'Es el corazón de la app. Al tocarlo se abre una hoja con tres pestañas: '
    'Tarea, Actividad y Evento. Elegís una y completás el formulario '
    'correspondiente.'))
story.append(Paragraph('Crear una tarea', callout_title))
steps = [
    'Escribí el nombre. Si ya registraste algo parecido antes, Cronos te muestra '
    'sugerencias de tu historial (cuántas veces, duración promedio) para '
    'completarlo con un toque.',
    'Elegí el proyecto al que pertenece (por ejemplo, "Trabajo" o "Estudio") y, '
    'si querés, el área de vida (Salud, Trabajo, Ocio, etc.) para poder ver '
    'después en qué áreas invertís más tiempo.',
    'Elegí la prioridad (P1 la más alta), la fecha y hora, y cuánto tiempo '
    'estimás que te va a llevar.',
    'Si querés que se repita (por ejemplo, todos los días a las 7:00, o '
    'distintos días con distinta hora), activá Repetir, elegí el patrón y '
    'desde qué día querés que empiece a repetirse.',
    'De forma opcional, podés vincular la tarea con una app del teléfono (por '
    'ejemplo, vincular "Estudiar inglés" con Duolingo). Así, cuando la marques '
    'como hecha, Cronos puede confirmar sola si de verdad usaste esa app '
    'mientras la tarea estaba corriendo.',
    'Si ya sabés que la tarea va a tener pasos, agregale subtareas ahí mismo '
    '(título y, opcionalmente, una descripción). Si la tarea se repite, esas '
    'mismas subtareas se copian en cada ocurrencia que Cronos genere. Después '
    'de creada, se pueden seguir agregando o editando desde su detalle, como '
    'siempre.',
    'Tocá Crear tarea. Si ya tenés otra tarea planificada a esa misma hora, te '
    'avisa antes de dejarte guardar.',
]
for i, s in enumerate(steps, 1):
    story.append(Paragraph(f'<b>{i}.</b> {s}', bullet))
story.append(Paragraph('Iniciar, pausar y terminar una tarea', callout_title))
story.append(para(
    'Entrá al detalle de la tarea (tocándola en la lista) para arrancar su '
    'cronómetro. Si la pausás, te pregunta el motivo ("me interrumpieron", '
    '"almuerzo", etc.) para que después entiendas por qué se estiró. Cuando '
    'termines de verdad, tocá Finalizar.'))
story.append(Paragraph('Crear una actividad', callout_title))
story.append(para(
    'Las actividades (dormir, comer, hacer ejercicio, redes sociales…) '
    'aparecen como una grilla de tarjetas de colores. Tocá una para arrancar '
    'su cronómetro, y tocá Detener cuando termines. No hace falta '
    'planificarlas de antemano.'))
story.append(para(
    'Si te falta una (por ejemplo "Lectura" o "Limpieza"), tocá la tarjeta '
    'punteada + Nueva actividad: elegís un nombre, un color, si suma como '
    'tiempo productivo, de ocio o ninguno de los dos, opcionalmente un área '
    'de vida, y si querés que te avise cuando le dediques demasiado tiempo '
    'en el día.'))
story.append(para(
    'Para editar una ya creada, mantené el dedo apretado sobre su tarjeta '
    'un segundo (o tocala desde Configuración → Categorías).'))
story.append(Paragraph('Registrar un evento', callout_title))
story.append(para(
    'Para esos imprevistos que te descuadraron el día. Escribís qué pasó, '
    'elegís una categoría (Interrupción, Traslado, Social, etc.) y el rango '
    'horario. También te sugiere eventos parecidos de tu historial.'))
story.append(PageBreak())

# ---------- 6. La Agenda ----------
story += section_heading(6, 'La Agenda')
story.append(para('Tiene dos vistas, que alternás arriba a la derecha:'))
story.append(bul('Día:', 'una línea de tiempo con todo lo que pasó (o va a pasar) hoy: tareas '
                          'planificadas, cuándo las arrancaste, cuándo las pausaste y '
                          'reanudaste, actividades, eventos, y los huecos libres entre medio. '
                          'Cada tarea planificada tiene un botón para arrancarla ahí mismo, sin '
                          'tener que ir a buscarla.'))
story.append(bul('Mes:', 'un calendario donde cada día se pinta más o menos intenso según '
                          'cuánto registraste. Con las flechas de arriba te movés al mes '
                          'anterior o siguiente para revisar tu historial o planificar más '
                          'adelante. Tocando cualquier día se abre su agenda real -qué tenías '
                          'planificado, qué pasó- igual que la vista Día pero para esa '
                          'fecha.'))
story.append(Spacer(1, 8))
story.append(Paragraph('Traer eventos de Google Calendar', callout_title))
story.append(para(
    'Desde Configuración → Calendario podés importar un archivo .ics '
    'exportado de tu Google Calendar (en Google Calendar: Configuración '
    '→ elegí tu calendario → "Exportar", que descarga un .ics) y Cronos '
    'trae tus próximos eventos como tareas. Es manual -elegís el archivo '
    'cada vez que querés actualizar- y de una sola dirección: crea o '
    'actualiza tareas en Cronos, nunca toca tu calendario de Google. Por '
    'ahora no trae eventos que se repiten (diarios, semanales, etc.).'))
story.append(PageBreak())

# ---------- 7. La pantalla Tareas ----------
story += section_heading(7, 'La pantalla Tareas')
story.append(para(
    'La lista completa, filtrable por Hoy, Semana o Todas. Cada tarjeta '
    'muestra su prioridad, proyecto, hora planificada y si está atrasada o en '
    'curso.'))
story.append(para(
    'Tocando una tarea entrás a su detalle, donde podés ver su historial de '
    'sesiones (cada vez que la arrancaste y pausaste, las dos más recientes '
    'para no alargar la pantalla), editarla (ícono de lápiz) o borrarla '
    '(ícono de tacho, con confirmación).'))
story.append(Spacer(1, 8))
story.append(Paragraph('Subtareas', callout_title))
story.append(para(
    'Podés agregarle a una tarea una lista de subtareas, cada una con su '
    'título y, si querés, una descripción con más detalle -ya sea al '
    'crearla, o después desde su detalle. Tocando una subtarea la editás. '
    'Una tarea no se puede finalizar mientras le queden subtareas sin '
    'marcar.'))
story.append(Spacer(1, 4))
story.append(Paragraph('Finalizar no es automático', callout_title))
story.append(para(
    'Al tocar Finalizar, Cronos te pregunta si de verdad hiciste la tarea '
    '— no se puede completar "porque sí". Si nunca la arrancaste con el '
    'cronómetro, te pide que cuentes en qué horario la hiciste, para que '
    'quede algún registro real. Si en realidad no la hiciste, te deja '
    'marcarla como "no hecha" pidiéndote un motivo, en vez de dejarla '
    'como si nada hubiera pasado.'))
story.append(PageBreak())

# ---------- 8. Analizar ----------
story += section_heading(8, 'Analizar: entender tus números')
story.append(para(
    'Acá es donde todo lo que registraste se convierte en respuestas. Tiene '
    'cuatro pestañas, y arriba podés elegir si querés ver la última semana o '
    'el último mes:'))
story.append(bul('Métricas:', 'el panorama general — cumplimiento, eficiencia, puntualidad, '
                               'tiempo perdido, y cómo viene evolucionando tu puntaje.'))
story.append(bul('Tareas:', 'cuánto duran realmente tus tareas comparado con lo que estimás, '
                             'qué proyectos se desvían más, y a qué ritmo las vas cerrando.'))
story.append(bul('Teléfono:', 'tu tiempo de pantalla real, qué apps usás más, y qué porcentaje '
                               'de ese tiempo fue en apps que vinculaste a alguna tarea (o sea, '
                               'tiempo "productivo" verificado). Necesita el permiso de "Acceso '
                               'al uso" del punto 2 — sin él, esta pestaña simplemente te '
                               'explica cómo activarlo.'))
story.append(bul('Eventos:', 'cuánto tiempo te comieron los imprevistos, de dónde vinieron más '
                              'seguido, y cuáles se repiten.'))
story.append(Spacer(1, 8))
story.append(callout(
    'Preguntale a tu IA sobre tus datos',
    'Arriba a la derecha de Analizar hay un botón chiquito que arma un '
    'resumen de tus datos y lo manda al selector de compartir de Android, '
    'para que elijas con qué IA de tu teléfono abrirlo (Gemini, ChatGPT, '
    'la que tengas). Ahí podés preguntarle cosas como "¿por qué fui menos '
    'productivo esta semana?" o "¿en qué estoy perdiendo más tiempo?". '
    'Cronos no manda nada solo ni se conecta con ninguna IA por su cuenta: '
    'vos elegís cada vez si compartir y con quién.'))
story.append(PageBreak())

# ---------- 9. Configuración ----------
story += section_heading(9, 'Configuración')
story.append(para(
    'Se abre tocando tu foto de perfil (o el círculo con tu inicial) arriba de '
    'la pantalla Hoy. Es un menú de categorías -tocando cualquiera se abre su '
    'propia pantalla, en vez de un solo listado larguísimo-:'))
story.append(Spacer(1, 4))
story.append(info_table([
    ('Perfil', 'Poner o cambiar tu foto (de la galería o con la cámara) y cargar tu '
               'nombre, para que Croni te hable más directo en toda la app y quede '
               'incluido en lo que compartís con la IA desde Analizar.'),
    ('Horarios', 'Tu horario laboral, de estudio y hora de dormir, día por día de la '
                 'semana — incluso podés marcar un día sin horario. También podés '
                 'agregar horarios propios (por ejemplo "Gimnasio", martes y jueves de '
                 '18 a 19).'),
    ('Organización', 'Categorías (tipos de actividad), Proyectos, Tareas recurrentes y '
                      'Áreas de vida: para ver, agregar, editar o borrar cada una. Cada '
                      'categoría de actividad se puede marcar como productiva, de ocio o '
                      'neutra, para que el puntaje del día sepa qué hacer con ella.'),
    ('Calendario', 'Importar un archivo .ics exportado de un calendario externo '
                    '(Google Calendar) y traer sus eventos próximos como tareas. '
                    'Ver punto 6.'),
    ('Notificaciones', 'Activar avisos cuando empieza una tarea planificada, cuando se '
                        'vence una sin arrancarla, y un aviso opcional que te dice si '
                        'estás usando el teléfono para otra cosa en vez de la tarea que '
                        'tenías planificada en ese momento.'),
    ('Seguridad', 'Activar el bloqueo con huella dactilar o PIN al abrir la app.'),
    ('Score', 'Cuánto pesa cada factor (cumplimiento, eficiencia, sueño, puntualidad) '
              'en tu puntaje diario. Los cuatro deben sumar 100.'),
    ('Exportar y backup', 'Sacar tus datos como CSV, JSON o un reporte en PDF, o hacer '
                           'una copia de seguridad completa para restaurarla después. Ver '
                           'punto 11.'),
    ('Ayuda', 'Volver a ver la guía de bienvenida de Croni.'),
    ('Soporte', 'Datos de contacto para dudas, problemas o sugerencias. Ver punto 10.'),
]))
story.append(PageBreak())

# ---------- 10. Actualizaciones automáticas ----------
story += section_heading(10, 'Actualizaciones automáticas')
story.append(para(
    'Cronos revisa solo, cada vez que abrís la app, si hay una versión más '
    'nueva publicada. No hace falta que la busques en ningún lado ni que te '
    'acuerdes de instalarla vos.'))
story.append(para(
    'Si hay una actualización disponible, aparece un cartel con la versión '
    'nueva. Tocando Descargar, Cronos la baja e instala ahí mismo, sin salir '
    'de la app y sin pasar por el navegador. Cuando termina, se abre el '
    'instalador del sistema para que confirmes.'))
story.append(callout(
    'Nada es obligatorio',
    'Si no querés instalarla en ese momento, tocá "Ahora no". Cronos te lo '
    'vuelve a ofrecer la próxima vez que abras la app, sin insistir mientras '
    'tanto.'))
story.append(para(
    'La próxima vez que abras Cronos después de actualizar, Croni te cuenta '
    'en un cartel qué hay de nuevo en esa versión.'))
story.append(Spacer(1, 8))
story.append(para(
    'La primera vez que instala una actualización así, el sistema puede '
    'pedirte que autorices a Cronos a instalar aplicaciones — es un permiso '
    'normal de Android para cualquier app que se actualiza sola, no algo '
    'propio de Cronos.'))
story.append(PageBreak())

# ---------- 11. Tus datos son tuyos ----------
story += section_heading(11, 'Tus datos son tuyos')
story.append(para(
    'Todo lo que anotás en Cronos se guarda únicamente en tu teléfono. No hay '
    'ninguna cuenta, ni servidor, ni nube: nadie más que vos puede ver tus '
    'tareas, actividades o eventos.'))
story.append(para(
    'Eso tiene una consecuencia importante: si desinstalás la app o cambiás '
    'de teléfono, esos datos se pierden a menos que hayas hecho una copia '
    'antes.'))
story.append(Paragraph('Hacé una copia de seguridad de vez en cuando', callout_title))
story.append(para(
    'Andá a Configuración → Exportar y backup → Hacer backup completo. Esto '
    'guarda un archivo con toda tu información. Si algún día necesitás '
    'recuperarla (cambiaste de teléfono, reinstalaste la app), usá Restaurar '
    'backup y elegí ese archivo.'))
story.append(para(
    'También podés exportar reportes sueltos (CSV, JSON o PDF) desde el '
    'mismo lugar, por ejemplo para revisar tus números en la computadora.'))
story.append(PageBreak())

# ---------- 12. Preguntas frecuentes ----------
story += section_heading(12, 'Preguntas frecuentes')
faq = [
    ('¿Tengo que anotar todo, todo el tiempo?',
     'No. Cronos funciona mejor cuanto más registrás, pero no es un '
     'requisito. Aunque solo anotes tus tareas principales, ya vas a empezar '
     'a ver patrones útiles.'),
    ('¿Qué pasa si me olvido de pausar o terminar algo?',
     'No pasa nada grave: podés editar los tiempos después entrando al '
     'detalle. Lo importante es que la próxima vez te acuerdes de tocar '
     'Finalizar o Detener.'),
    ('¿Para qué sirve vincular una tarea con una app?',
     'Es opcional. Sirve para que Cronos confirme, sin que tengas que '
     'contarlo vos, si de verdad usaste esa app mientras la tarea estaba '
     'corriendo — por ejemplo, saber que realmente estudiaste con Duolingo y '
     'no otra cosa.'),
    ('¿Por qué la pestaña Teléfono en Analizar dice que le falta permiso?',
     'Porque todavía no activaste el "Acceso al uso" del punto 2. Es '
     'opcional y se activa desde ahí mismo, con un botón que te lleva a los '
     'Ajustes del sistema.'),
    ('¿Puedo cambiar cuánto pesa cada cosa en mi puntaje del día?',
     'Sí, en Configuración → Score. Cumplimiento, eficiencia, sueño y '
     'puntualidad tienen que sumar 100 entre los cuatro.'),
    ('Si borro una tarea recurrente, ¿se borran las que ya generó?',
     'No. Borrar la regla de repetición solo evita que se creen nuevas '
     'tareas a partir de ahí; las que ya se generaron quedan intactas en tu '
     'historial.'),
    ('Borré una tarea que había importado de mi calendario, ¿por qué volvió?',
     'Porque sigue existiendo en tu Google Calendar: cada sincronización '
     'trae lo que esté ahí. Si ya no la querés en Cronos, borrala también '
     'del calendario de origen, o desconectá el calendario desde '
     'Configuración.'),
    ('¿Cómo hago si tengo un problema o una duda?',
     'Andá a Configuración → Soporte: ahí tenés el contacto directo para '
     'escribir o llamar.'),
]
for q, a in faq:
    story.append(Paragraph(q, callout_title))
    story.append(para(a))

story.append(Spacer(1, 10))
story.append(para(
    'Croni te espera adentro. Cualquier duda, esta guía la volvés a '
    'encontrar desde Configuración → Ayuda.'))

story.append(Spacer(1, 26))
story.append(HRFlowable(width='100%', thickness=0.6, color=RULE, spaceAfter=10))
story.append(Paragraph('Hecho por Francisco Castro, desarrollador de software independiente.',
                        credit_style))

doc.build(story)
print('OK')

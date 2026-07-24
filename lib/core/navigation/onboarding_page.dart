import 'package:flutter/material.dart';

import '../../shared/shared.dart';
import '../di/service_locator.dart';
import '../services/notifications_service.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.title, required this.body, required this.mascotState});

  final String title;
  final String body;
  final MascotState mascotState;
}

const _slides = [
  _OnboardingSlide(
    title: '¡Hola! Soy Croni',
    body: 'Te voy a acompañar en Cronos. No soy un gestor de tareas: soy tu '
        'instrumento de medición. Te ayudo a ver qué hacés con tu tiempo, '
        'para que decidas qué vas a hacer con tu vida.',
    mascotState: MascotState.wave,
  ),
  _OnboardingSlide(
    title: 'Te cuento cómo vas',
    body: 'En Hoy, Agenda y Tareas te respondo "¿cómo va tu día?" con '
        'números, antes que con gráficos. Nada de leer entre líneas.',
    mascotState: MascotState.think,
  ),
  _OnboardingSlide(
    title: 'Registrás en 2 toques',
    body: 'Con el botón + anoto una tarea, una actividad o un imprevisto al '
        'instante. Si te cuesta más que eso, dejás de registrar -- por eso '
        'lo hice así de simple.',
    mascotState: MascotState.walk,
  ),
  _OnboardingSlide(
    title: '¡Ya estás listo!',
    body: 'Tus datos quedan en tu teléfono, nunca en un servidor. Cuando '
        'quieras, activá huella y avisos de tus tareas planificadas desde '
        'Configuración. ¿Empezamos?',
    mascotState: MascotState.celebrate,
  ),
];

/// Guía rápida de bienvenida (se muestra una sola vez, en el primer
/// arranque). [onDone] marca la guía como vista y continúa a la app.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == _slides.length - 1) {
      await _requestNotificationsIfNeeded();
      widget.onDone();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Pregunta con un modal si activar avisos, y de aceptar, pide el
  /// permiso con el diálogo normal del sistema (nunca saca de la app).
  Future<void> _requestNotificationsIfNeeded() async {
    final service = sl<NotificationsService>();
    if (await service.hasPermission()) return;
    if (!mounted) return;
    final wantsIt = await showNotificationsPermissionDialog(context);
    if (!wantsIt || !mounted) return;
    final granted = await service.requestPermission();
    if (granted) await service.setEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text(
                    'Omitir',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontFamily: AppTextStyles.sans,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CronosMascot(size: 160, state: slide.mascotState),
                        Gaps.vXl,
                        Text(
                          slide.title,
                          style: AppTextStyles.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        Gaps.vMd,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            slide.body,
                            style: AppTextStyles.bodySecondary.copyWith(height: 1.55, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.accent : AppColors.border,
                        borderRadius: const BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                ],
              ),
              Gaps.vLg,
              PrimaryButton(
                label: isLast ? 'Empezar' : 'Siguiente',
                expanded: true,
                onPressed: _next,
              ),
              Gaps.vMd,
            ],
          ),
        ),
      ),
    );
  }
}

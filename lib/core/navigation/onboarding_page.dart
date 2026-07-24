import 'package:flutter/material.dart';

import '../../shared/shared.dart';
import '../di/service_locator.dart';
import '../services/notifications_service.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.title, required this.body, this.wave = false});

  final String title;
  final String body;
  final bool wave;
}

const _slides = [
  _OnboardingSlide(
    title: 'Hola, soy Cronos',
    body: 'No soy un gestor de tareas: soy un instrumento de medición. '
        'Te ayudo a saber qué hacés con tu tiempo, para saber qué vas a '
        'hacer con tu vida.',
    wave: true,
  ),
  _OnboardingSlide(
    title: 'Tu día en segundos',
    body: 'Hoy, Agenda y Tareas responden "¿cómo va mi día?" con números '
        'antes que gráficos. Nada de leer entre líneas.',
  ),
  _OnboardingSlide(
    title: 'Registrar cuesta 2 toques',
    body: 'El botón + registra una tarea, una actividad o un imprevisto al '
        'instante. Si cuesta más que eso, dejás de registrar -- por eso es '
        'así de simple.',
  ),
  _OnboardingSlide(
    title: 'Tus datos, en tu teléfono',
    body: 'Todo se guarda localmente, nunca en un servidor. Podés proteger '
        'la app con huella y activar avisos de tus tareas planificadas '
        'cuando quieras, desde Configuración.',
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
                        CronosMascot(size: 160, wave: slide.wave),
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

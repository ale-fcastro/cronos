import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Personaje mascota de Cronos: el mismo reloj del isotipo (anillo abierto,
/// no un círculo perfecto, con dos manecillas) al que se le agregan dos
/// brazos, dos piernas y dos ojos. La apertura del anillo es justo lo que
/// "rompe" el círculo completo -- es la identidad del logo, no un descuido.
class CronosMascot extends StatefulWidget {
  const CronosMascot({super.key, this.size = 160, this.wave = true});

  final double size;

  /// Si es true, el brazo derecho saluda con un balanceo suave en loop.
  final bool wave;

  @override
  State<CronosMascot> createState() => _CronosMascotState();
}

class _CronosMascotState extends State<CronosMascot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.wave) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _MascotPainter(waveT: widget.wave ? _controller.value : 0),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.waveT});

  /// 0..1: fase del saludo del brazo derecho (0 = quieto).
  final double waveT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final headR = size.shortestSide * 0.30;

    _paintLegs(canvas, center, headR);
    _paintArms(canvas, center, headR);
    _paintRing(canvas, center, headR);
    _paintHandsAndPivot(canvas, center, headR);
    _paintEyes(canvas, center, headR);
  }

  void _paintRing(Canvas canvas, Offset center, double headR) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.26
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    // Apertura centrada arriba (12 en punto): se dibuja el resto del anillo.
    const startAngle = -math.pi / 4;
    const sweepAngle = 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: headR),
      startAngle,
      sweepAngle,
      false,
      ringPaint,
    );
  }

  void _paintHandsAndPivot(Canvas canvas, Offset center, double headR) {
    final handPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.textPrimary;

    void hand(double angleFromUp, double length) {
      final rad = -math.pi / 2 + angleFromUp;
      final end = center + Offset(math.cos(rad), math.sin(rad)) * length;
      canvas.drawLine(center, end, handPaint);
    }

    hand(-math.pi / 3.2, headR * 0.62);
    hand(math.pi / 3.2, headR * 0.62);
    canvas.drawCircle(center, headR * 0.09, Paint()..color = AppColors.textPrimary);
  }

  void _paintEyes(Canvas canvas, Offset center, double headR) {
    final eyePaint = Paint()..color = AppColors.textPrimary;
    final eyeY = center.dy + headR * 0.32;
    canvas.drawCircle(Offset(center.dx - headR * 0.28, eyeY), headR * 0.09, eyePaint);
    canvas.drawCircle(Offset(center.dx + headR * 0.28, eyeY), headR * 0.09, eyePaint);
  }

  void _paintArms(Canvas canvas, Offset center, double headR) {
    final limbPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.22
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    final armY = center.dy + headR * 0.15;

    // Brazo izquierdo: quieto, apoyado hacia abajo.
    canvas.drawLine(
      Offset(center.dx - headR * 0.95, armY),
      Offset(center.dx - headR * 1.35, armY + headR * 0.55),
      limbPaint,
    );

    // Brazo derecho: saluda (oscila con waveT).
    final waveAngle = math.sin(waveT * math.pi) * 0.5;
    final rightShoulder = Offset(center.dx + headR * 0.95, armY);
    final rightHandAngle = -math.pi / 2.6 + waveAngle;
    final rightHand = rightShoulder +
        Offset(math.cos(rightHandAngle), math.sin(rightHandAngle)) * headR * 0.75;
    canvas.drawLine(rightShoulder, rightHand, limbPaint);
  }

  void _paintLegs(Canvas canvas, Offset center, double headR) {
    final limbPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.22
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    final legTopY = center.dy + headR * 0.92;

    canvas.drawLine(
      Offset(center.dx - headR * 0.32, legTopY),
      Offset(center.dx - headR * 0.42, legTopY + headR * 0.6),
      limbPaint,
    );
    canvas.drawLine(
      Offset(center.dx + headR * 0.32, legTopY),
      Offset(center.dx + headR * 0.42, legTopY + headR * 0.6),
      limbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.waveT != waveT;
}

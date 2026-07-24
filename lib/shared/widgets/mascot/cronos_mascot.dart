import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Estados animados de Croni, la mascota de Cronos (ver diseño
/// "Cronos Mascota" en Claude Design). Cada uno tiene su propio ciclo de
/// animación (brazos, piernas, cuerpo, mechón-manecillas, ojos y boca).
enum MascotState { idle, wave, walk, celebrate, think, sleep }

/// Personaje mascota de Cronos: el isotipo (anillo abierto en forma de "C",
/// con las manecillas del reloj como mechón) con brazos, piernas y ojos
/// propios. La apertura del anillo es la identidad del logo, no un descuido.
class CronosMascot extends StatefulWidget {
  const CronosMascot({super.key, this.size = 160, this.state = MascotState.idle});

  final double size;
  final MascotState state;

  @override
  State<CronosMascot> createState() => _CronosMascotState();
}

class _CronosMascotState extends State<CronosMascot> with SingleTickerProviderStateMixin {
  // Un ciclo largo y monotónico (nunca se reinicia a mitad de una app en
  // uso real) evita el salto que daría un sawtooth corto al hacer % de
  // cada animación, que tiene su propio período independiente.
  static const _loopSeconds = 86400.0;
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(hours: 24))..repeat();

  MascotState _prevState = MascotState.idle;
  double _switchAtT = 0;

  @override
  void initState() {
    super.initState();
    _prevState = widget.state;
  }

  @override
  void didUpdateWidget(covariant CronosMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _prevState = oldWidget.state;
      _switchAtT = _controller.value * _loopSeconds;
    }
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
      builder: (context, _) {
        final t = _controller.value * _loopSeconds;
        final blendT = ((t - _switchAtT) / 0.4).clamp(0.0, 1.0);
        final pose = blendT >= 1.0
            ? _poseFor(widget.state, t)
            : _Pose.lerp(
                _poseFor(_prevState, t),
                _poseFor(widget.state, t),
                Curves.easeOutBack.transform(blendT),
              );
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _MascotPainter(pose: pose, sleeping: widget.state == MascotState.sleep, t: t),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pose: todos los valores de una instancia (ángulos en grados, offsets en
// unidades del viewBox 220x250 del diseño original).
// ---------------------------------------------------------------------------

class _Pose {
  const _Pose({
    required this.bodyOffset,
    required this.bodyRotationDeg,
    required this.bodyScale,
    required this.shadowScale,
    required this.shadowOpacity,
    required this.leftArmDeg,
    required this.rightArmDeg,
    required this.leftLegDeg,
    required this.rightLegDeg,
    required this.tuftDeg,
    required this.eyesOffset,
    required this.eyeScaleY,
    required this.pupilOffsetX,
    required this.mouthSmile,
    required this.mouthOpen,
    required this.mouthO,
    required this.mouthSleep,
  });

  final Offset bodyOffset;
  final double bodyRotationDeg;
  final Offset bodyScale;
  final double shadowScale;
  final double shadowOpacity;
  final double leftArmDeg;
  final double rightArmDeg;
  final double leftLegDeg;
  final double rightLegDeg;
  final double tuftDeg;
  final Offset eyesOffset;
  final double eyeScaleY;
  final double pupilOffsetX;
  final double mouthSmile;
  final double mouthOpen;
  final double mouthO;
  final double mouthSleep;

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
        bodyOffset: Offset.lerp(a.bodyOffset, b.bodyOffset, t)!,
        bodyRotationDeg: _lerpD(a.bodyRotationDeg, b.bodyRotationDeg, t),
        bodyScale: Offset.lerp(a.bodyScale, b.bodyScale, t)!,
        shadowScale: _lerpD(a.shadowScale, b.shadowScale, t),
        shadowOpacity: _lerpD(a.shadowOpacity, b.shadowOpacity, t),
        leftArmDeg: _lerpD(a.leftArmDeg, b.leftArmDeg, t),
        rightArmDeg: _lerpD(a.rightArmDeg, b.rightArmDeg, t),
        leftLegDeg: _lerpD(a.leftLegDeg, b.leftLegDeg, t),
        rightLegDeg: _lerpD(a.rightLegDeg, b.rightLegDeg, t),
        tuftDeg: _lerpD(a.tuftDeg, b.tuftDeg, t),
        eyesOffset: Offset.lerp(a.eyesOffset, b.eyesOffset, t)!,
        eyeScaleY: _lerpD(a.eyeScaleY, b.eyeScaleY, t),
        pupilOffsetX: _lerpD(a.pupilOffsetX, b.pupilOffsetX, t),
        mouthSmile: _lerpD(a.mouthSmile, b.mouthSmile, t),
        mouthOpen: _lerpD(a.mouthOpen, b.mouthOpen, t),
        mouthO: _lerpD(a.mouthO, b.mouthO, t),
        mouthSleep: _lerpD(a.mouthSleep, b.mouthSleep, t),
      );
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;

/// Un solo "bump" 0→1→0 a lo largo de un período (seno medio ciclo).
double _bump(double phase) => math.sin(math.pi * phase);

double _phase(double t, double period) {
  final m = t % period;
  return (m < 0 ? m + period : m) / period;
}

/// Interpolación lineal por tramos entre paradas (phase, value) ordenadas.
double _keyframes(double phase, List<(double, double)> stops) {
  for (var i = 0; i < stops.length - 1; i++) {
    final (p0, v0) = stops[i];
    final (p1, v1) = stops[i + 1];
    if (phase >= p0 && phase <= p1) {
      final localT = p1 == p0 ? 0.0 : (phase - p0) / (p1 - p0);
      return v0 + (v1 - v0) * localT;
    }
  }
  return stops.last.$2;
}

_Pose _poseFor(MascotState state, double t) {
  // Parpadeo: en todos los estados salvo dormir (ahí los ojos ya están
  // cerrados). 4.6s de ciclo, un parpadeo breve cerca del 94.5%.
  var eyeScaleY = 1.0;
  if (state != MascotState.sleep) {
    final bp = _phase(t, 4.6);
    if (bp >= 0.92 && bp < 0.945) {
      eyeScaleY = _lerpD(1.0, 0.08, (bp - 0.92) / 0.025);
    } else if (bp >= 0.945 && bp <= 0.97) {
      eyeScaleY = _lerpD(0.08, 1.0, (bp - 0.945) / 0.025);
    }
  }

  // Mirada distraída, solo en reposo.
  var pupilOffsetX = 0.0;
  if (state == MascotState.idle) {
    final lp = _phase(t, 6.5);
    pupilOffsetX = _keyframes(lp, [
      (0.0, 0.0), (0.38, 0.0),
      (0.48, 3.5), (0.58, 3.5),
      (0.70, -3.5), (0.80, -3.5),
      (0.90, 0.0), (1.0, 0.0),
    ]);
  }

  const restPose = (
    bodyScale: Offset(1.0, 1.0),
    shadowScale: 1.0,
    shadowOpacity: 0.28,
  );

  switch (state) {
    case MascotState.idle:
      final p = _phase(t, 3.4);
      final tuftP = _phase(t - 0.25, 3.4);
      final b = _bump(p);
      return _Pose(
        bodyOffset: Offset(0, -7 * b),
        bodyRotationDeg: -1.2 * b,
        bodyScale: restPose.bodyScale,
        shadowScale: restPose.shadowScale,
        shadowOpacity: restPose.shadowOpacity,
        leftArmDeg: 9 + 7 * b,
        rightArmDeg: -9 - 7 * b,
        leftLegDeg: 0,
        rightLegDeg: 0,
        tuftDeg: -4 + 9 * _bump(tuftP),
        eyesOffset: Offset.zero,
        eyeScaleY: eyeScaleY,
        pupilOffsetX: pupilOffsetX,
        mouthSmile: 1,
        mouthOpen: 0,
        mouthO: 0,
        mouthSleep: 0,
      );

    case MascotState.wave:
      final pBody = _phase(t, 1.0);
      final pArm = _phase(t, 0.5);
      final pTuft = _phase(t, 1.0);
      final bb = _bump(pBody);
      return _Pose(
        bodyOffset: Offset(0, -3 * bb),
        bodyRotationDeg: 1.5 * bb,
        bodyScale: restPose.bodyScale,
        shadowScale: restPose.shadowScale,
        shadowOpacity: restPose.shadowOpacity,
        leftArmDeg: 14,
        rightArmDeg: -128 - 30 * _bump(pArm),
        leftLegDeg: 0,
        rightLegDeg: 0,
        tuftDeg: -4 + 9 * _bump(pTuft),
        eyesOffset: Offset.zero,
        eyeScaleY: eyeScaleY,
        pupilOffsetX: 0,
        mouthSmile: 0,
        mouthOpen: 1,
        mouthO: 0,
        mouthSleep: 0,
      );

    case MascotState.walk:
      final pBody = _phase(t, 0.52);
      final pLimb = _phase(t, 1.04);
      final cosLimb = math.cos(2 * math.pi * pLimb);
      final bodyY = -6 * math.sin(2 * math.pi * pBody).abs();
      return _Pose(
        bodyOffset: Offset(0, bodyY),
        bodyRotationDeg: 0,
        bodyScale: restPose.bodyScale,
        shadowScale: restPose.shadowScale,
        shadowOpacity: restPose.shadowOpacity,
        leftArmDeg: 10 - 24 * cosLimb,
        rightArmDeg: 10 + 24 * cosLimb,
        leftLegDeg: 24 * cosLimb,
        rightLegDeg: -24 * cosLimb,
        tuftDeg: -6 * math.cos(2 * math.pi * pBody),
        eyesOffset: Offset.zero,
        eyeScaleY: eyeScaleY,
        pupilOffsetX: 0,
        mouthSmile: 1,
        mouthOpen: 0,
        mouthO: 0,
        mouthSleep: 0,
      );

    case MascotState.celebrate:
      final p = _phase(t, 1.1);
      final jumpY = _keyframes(p, [(0.0, 0.0), (0.28, -34.0), (0.48, -34.0), (0.64, 0.0), (1.0, 0.0)]);
      final cheerL = _keyframes(p, [(0.0, 140.0), (0.28, 120.0), (1.0, 140.0)]);
      final cheerR = _keyframes(p, [(0.0, -140.0), (0.28, -120.0), (1.0, -140.0)]);
      final squishX = _keyframes(p, [(0.0, 1.0), (0.68, 1.1), (1.0, 1.0)]);
      final squishY = _keyframes(p, [(0.0, 1.0), (0.68, 0.9), (1.0, 1.0)]);
      final shadowScale = _keyframes(p, [(0.0, 1.0), (0.40, 0.6), (1.0, 1.0)]);
      final shadowOpacity = _keyframes(p, [(0.0, 0.35), (0.40, 0.15), (1.0, 0.35)]);
      return _Pose(
        bodyOffset: Offset(0, jumpY),
        bodyRotationDeg: 0,
        bodyScale: Offset(squishX, squishY),
        shadowScale: shadowScale,
        shadowOpacity: shadowOpacity,
        leftArmDeg: cheerL,
        rightArmDeg: cheerR,
        leftLegDeg: 0,
        rightLegDeg: 0,
        tuftDeg: 0,
        eyesOffset: Offset.zero,
        eyeScaleY: eyeScaleY,
        pupilOffsetX: 0,
        mouthSmile: 0,
        mouthOpen: 1,
        mouthO: 0,
        mouthSleep: 0,
      );

    case MascotState.think:
      final p = _phase(t, 3.0);
      return _Pose(
        bodyOffset: Offset.zero,
        bodyRotationDeg: -2.5 * math.cos(2 * math.pi * p),
        bodyScale: restPose.bodyScale,
        shadowScale: restPose.shadowScale,
        shadowOpacity: restPose.shadowOpacity,
        leftArmDeg: 9,
        rightArmDeg: -108,
        leftLegDeg: 0,
        rightLegDeg: 0,
        tuftDeg: 0,
        eyesOffset: const Offset(5, -4),
        eyeScaleY: eyeScaleY,
        pupilOffsetX: 0,
        mouthSmile: 0,
        mouthOpen: 0,
        mouthO: 1,
        mouthSleep: 0,
      );

    case MascotState.sleep:
      final p = _phase(t, 3.6);
      return _Pose(
        bodyOffset: Offset(0, 4 * _bump(p)),
        bodyRotationDeg: 0,
        bodyScale: restPose.bodyScale,
        shadowScale: restPose.shadowScale,
        shadowOpacity: restPose.shadowOpacity,
        leftArmDeg: 7,
        rightArmDeg: -7,
        leftLegDeg: 0,
        rightLegDeg: 0,
        tuftDeg: 0,
        eyesOffset: Offset.zero,
        eyeScaleY: 1,
        pupilOffsetX: 0,
        mouthSmile: 0,
        mouthOpen: 0,
        mouthO: 0,
        mouthSleep: 1,
      );
  }
}

// ---------------------------------------------------------------------------
// Paleta del diseño (ver "Cronos Mascota" en Claude Design).
// ---------------------------------------------------------------------------

class _Palette {
  static const bodyGradStart = Color(0xFF9AABE4);
  static const bodyGradEnd = Color(0xFF7D90D6);
  static const arm = Color(0xFF8496DA);
  static const leg = Color(0xFF6A7CC4);
  static const mitt = Color(0xFFE2E5EC);
  static const eyebrow = Color(0xFF5866A8);
  static const pupil = Color(0xFF20242C);
  static const tuft = Color(0xFFDFE3EC);
  static const tuftPivot = Color(0xFFEEF0F4);
  static const shirt = Color(0xFFEEF0F4);
  static const collarFoldL = Color(0xFFD7DBE4);
  static const collarFoldR = Color(0xFFC6CBD6);
  static const tieKnot = Color(0xFF39406B);
  static const tie = Color(0xFF2F3760);
  static const mouthLine = Color(0xFFE8E9ED);
  static const mouthOpenFill = Color(0xFF20242C);
  static const mouthTongue = Color(0xFFF0857A);
  static const eyeClosedLine = Color(0xFFCDD2DC);
  static const shadow = Colors.black;
  static const zzz = Color(0xFF9DB1F5);
}

// ---------------------------------------------------------------------------
// Painter: dibuja en el espacio del viewBox original (220x250) y escala
// para que quepa "contain" dentro del tamaño pedido.
// ---------------------------------------------------------------------------

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.pose, required this.sleeping, required this.t});

  static const _viewW = 220.0;
  static const _viewH = 250.0;

  final _Pose pose;
  final bool sleeping;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _viewW, size.height / _viewH);
    canvas.save();
    canvas.translate(
      (size.width - _viewW * scale) / 2,
      (size.height - _viewH * scale) / 2,
    );
    canvas.scale(scale);

    _paintShadow(canvas);
    canvas.save();
    canvas.translate(110 + pose.bodyOffset.dx, 216 + pose.bodyOffset.dy);
    canvas.rotate(_rad(pose.bodyRotationDeg));
    canvas.translate(-110, -216);
    _paintLeg(canvas, originX: 95, rectX: 89, deg: pose.leftLegDeg);
    _paintLeg(canvas, originX: 125, rectX: 119, deg: pose.rightLegDeg);
    _paintArm(canvas, originX: 58, rectX: 52, deg: pose.leftArmDeg);
    _paintArm(canvas, originX: 162, rectX: 156, deg: pose.rightArmDeg);
    _paintTuft(canvas);
    _paintBody(canvas);
    _paintEyebrows(canvas);
    _paintEyes(canvas);
    _paintShirt(canvas);
    _paintMouth(canvas);
    canvas.restore();

    if (sleeping) _paintZzz(canvas);
    canvas.restore();
  }

  double _rad(double deg) => deg * math.pi / 180;

  void _paintShadow(Canvas canvas) {
    canvas.save();
    canvas.translate(110, 232);
    canvas.scale(pose.shadowScale);
    canvas.translate(-110, -232);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 232), width: 112, height: 20),
      Paint()..color = _Palette.shadow.withValues(alpha: pose.shadowOpacity),
    );
    canvas.restore();
  }

  void _paintLeg(Canvas canvas, {required double originX, required double rectX, required double deg}) {
    canvas.save();
    canvas.translate(originX, 176);
    canvas.rotate(_rad(deg));
    canvas.translate(-originX, -176);
    final legRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectX, 176, 12, 42),
      const Radius.circular(6),
    );
    canvas.drawRRect(legRect, Paint()..color = _Palette.leg);
    final footPath = Path()
      ..moveTo(rectX - 13, 214)
      ..relativeQuadraticBezierTo(0, -6, 6, -6)
      ..relativeLineTo(15, 0)
      ..relativeQuadraticBezierTo(6, 0, 6, 6)
      ..relativeLineTo(0, 3)
      ..relativeQuadraticBezierTo(0, 5, -6, 5)
      ..relativeLineTo(-15, 0)
      ..relativeQuadraticBezierTo(-6, 0, -6, -5)
      ..close();
    canvas.drawPath(footPath, Paint()..color = _Palette.mitt);
    canvas.restore();
  }

  void _paintArm(Canvas canvas, {required double originX, required double rectX, required double deg}) {
    canvas.save();
    canvas.translate(originX, 118);
    canvas.rotate(_rad(deg));
    canvas.translate(-originX, -118);
    final armRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectX, 116, 12, 50),
      const Radius.circular(6),
    );
    canvas.drawRRect(armRect, Paint()..color = _Palette.arm);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(originX, 169), width: 20, height: 22),
      Paint()..color = _Palette.mitt,
    );
    canvas.restore();
  }

  void _paintTuft(Canvas canvas) {
    canvas.save();
    canvas.translate(109, 54);
    canvas.rotate(_rad(pose.tuftDeg));
    void hand(double signDeg) {
      canvas.save();
      canvas.rotate(_rad(signDeg));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -34, 7, 34),
          const Radius.circular(3.5),
        ),
        Paint()..color = _Palette.tuft,
      );
      canvas.restore();
    }

    hand(-32);
    hand(32);
    canvas.drawCircle(Offset.zero, 4, Paint()..color = _Palette.tuftPivot);
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    canvas.save();
    canvas.translate(110, 176);
    canvas.scale(pose.bodyScale.dx, pose.bodyScale.dy);
    canvas.translate(-110, -176);
    const center = Offset(110, 118);
    const radius = 58.0;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        const Offset(52, 60),
        const Offset(168, 176),
        [_Palette.bodyGradStart, _Palette.bodyGradEnd],
      );
    // Círculo con dasharray "74 26" (de 100) y luego rotado 38°: arranca a
    // 38° y dibuja el 74% de la vuelta, dejando el 26% restante como
    // apertura (la "C").
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _rad(38),
      _rad(0.74 * 360),
      false,
      ringPaint,
    );
    canvas.restore();
  }

  void _paintEyebrows(Canvas canvas) {
    final paint = Paint()..color = _Palette.eyebrow;
    void brow(double x, double pivotX, double deg) {
      canvas.save();
      canvas.translate(pivotX, 95);
      canvas.rotate(_rad(deg));
      canvas.translate(-pivotX, -95);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 93, 20, 4.5), const Radius.circular(2.2)),
        paint,
      );
      canvas.restore();
    }

    brow(81, 91, 4);
    brow(119, 129, -4);
  }

  void _paintEyes(Canvas canvas) {
    canvas.save();
    canvas.translate(110 + pose.eyesOffset.dx, 113 + pose.eyesOffset.dy);
    canvas.scale(1, pose.eyeScaleY);
    canvas.translate(-110, -113);

    if (!sleeping) {
      final white = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(92, 111), 15, white);
      canvas.drawCircle(const Offset(128, 111), 15, white);

      canvas.save();
      canvas.translate(pose.pupilOffsetX, 0);
      final pupil = Paint()..color = _Palette.pupil;
      canvas.drawCircle(const Offset(95, 113), 7, pupil);
      canvas.drawCircle(const Offset(131, 113), 7, pupil);
      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(const Offset(98, 110), 1.8, highlight);
      canvas.drawCircle(const Offset(134, 110), 1.8, highlight);
      canvas.restore();
    } else {
      final closedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = _Palette.eyeClosedLine;
      final leftEye = Path()
        ..moveTo(80, 112)
        ..quadraticBezierTo(92, 122, 104, 112);
      final rightEye = Path()
        ..moveTo(116, 112)
        ..quadraticBezierTo(128, 122, 140, 112);
      canvas.drawPath(leftEye, closedPaint);
      canvas.drawPath(rightEye, closedPaint);
    }
    canvas.restore();
  }

  void _paintShirt(Canvas canvas) {
    canvas.save();
    canvas.translate(0, 15);
    canvas.translate(110, 156);
    canvas.scale(0.76);
    canvas.translate(-110, -156);

    final collar = Path()
      ..moveTo(98, 143)
      ..quadraticBezierTo(110, 141, 122, 143)
      ..lineTo(114, 186)
      ..quadraticBezierTo(110, 189, 106, 186)
      ..close();
    canvas.drawPath(collar, Paint()..color = _Palette.shirt);

    final foldL = Path()
      ..moveTo(99, 143)
      ..lineTo(110, 152)
      ..lineTo(101, 157)
      ..close();
    canvas.drawPath(foldL, Paint()..color = _Palette.collarFoldL);

    final foldR = Path()
      ..moveTo(121, 143)
      ..lineTo(110, 152)
      ..lineTo(119, 157)
      ..close();
    canvas.drawPath(foldR, Paint()..color = _Palette.collarFoldR);

    final knot = Path()
      ..moveTo(105, 150)
      ..relativeLineTo(10, 0)
      ..relativeLineTo(-2, 7)
      ..relativeLineTo(-6, 0)
      ..close();
    canvas.drawPath(knot, Paint()..color = _Palette.tieKnot);

    final tie = Path()
      ..moveTo(107.5, 157)
      ..relativeLineTo(5, 0)
      ..relativeLineTo(3, 24)
      ..relativeLineTo(-5.5, 6)
      ..relativeLineTo(-5.5, -6)
      ..close();
    canvas.drawPath(tie, Paint()..color = _Palette.tie);

    canvas.restore();
  }

  void _paintMouth(Canvas canvas) {
    if (pose.mouthSmile > 0.01) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..color = _Palette.mouthLine.withValues(alpha: pose.mouthSmile.clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(102, 141)
        ..quadraticBezierTo(110, 145, 118, 141);
      canvas.drawPath(path, paint);
    }
    if (pose.mouthOpen > 0.01) {
      final alpha = pose.mouthOpen.clamp(0.0, 1.0);
      final mouth = Path()
        ..moveTo(100, 139)
        ..quadraticBezierTo(110, 138, 120, 139)
        ..quadraticBezierTo(117, 153, 110, 153)
        ..quadraticBezierTo(103, 153, 100, 139)
        ..close();
      canvas.drawPath(mouth, Paint()..color = _Palette.mouthOpenFill.withValues(alpha: alpha));
      final tongue = Path()
        ..moveTo(104, 148)
        ..quadraticBezierTo(110, 152, 116, 148)
        ..quadraticBezierTo(113, 152, 110, 152)
        ..quadraticBezierTo(107, 152, 104, 148)
        ..close();
      canvas.drawPath(tongue, Paint()..color = _Palette.mouthTongue.withValues(alpha: alpha));
    }
    if (pose.mouthO > 0.01) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 144), width: 9, height: 11),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..color = _Palette.mouthLine.withValues(alpha: pose.mouthO.clamp(0.0, 1.0)),
      );
    }
    if (pose.mouthSleep > 0.01) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = _Palette.eyeClosedLine.withValues(alpha: pose.mouthSleep.clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(104, 145)
        ..quadraticBezierTo(110, 149, 116, 145);
      canvas.drawPath(path, paint);
    }
  }

  void _paintZzz(Canvas canvas) {
    void z(String glyph, double fontSize, double delay) {
      final phase = _phase(t - delay, 2.4);
      double opacity;
      if (phase < 0.2) {
        opacity = _lerpD(0, 1, phase / 0.2);
      } else {
        opacity = _lerpD(1, 0, (phase - 0.2) / 0.8);
      }
      if (opacity <= 0.01) return;
      final dx = _lerpD(0, 20, phase);
      final dy = _lerpD(0, -44, phase);
      final scale = _lerpD(0.6, 1.25, phase);
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: _Palette.zzz.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(150 + dx, 92 + dy);
      canvas.scale(scale);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    z('z', 20, 0);
    z('Z', 26, 1.2);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.sleeping != sleeping || oldDelegate.t != t;
}

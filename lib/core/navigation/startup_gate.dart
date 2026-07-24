import 'package:flutter/material.dart';

import '../../shared/shared.dart';
import '../di/service_locator.dart';
import '../services/onboarding_service.dart';
import 'lock_gate.dart';
import 'onboarding_page.dart';

/// Primera puerta de la app: muestra la guía rápida en el primer arranque
/// y después compone con [LockGate]. Vive en core/navigation porque
/// orquesta un servicio de núcleo junto con la puerta de bloqueo.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final _service = sl<OnboardingService>();
  bool? _seen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _service.hasSeenOnboarding();
    if (mounted) setState(() => _seen = seen);
  }

  @override
  Widget build(BuildContext context) {
    final seen = _seen;
    if (seen == null) {
      return const Scaffold(backgroundColor: AppColors.background, body: LoadingView());
    }
    if (!seen) {
      return OnboardingPage(
        onDone: () async {
          await _service.markSeen();
          if (mounted) setState(() => _seen = true);
        },
      );
    }
    return const LockGate();
  }
}

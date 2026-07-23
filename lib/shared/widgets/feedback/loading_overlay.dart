import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../layout/loading_view.dart';

/// Velo de carga sobre el contenido durante operaciones bloqueantes.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
  });

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: AppDurations.normal,
          child: loading
              ? const ColoredBox(
                  color: Color(0xB3121316),
                  child: LoadingView(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

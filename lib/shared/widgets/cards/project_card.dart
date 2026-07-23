import 'package:flutter/material.dart';
import '../charts/deviation_bar.dart';
import 'app_card.dart';

/// Fila de proyecto con su barra de desviacion estimado/real.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.name,
    required this.deviationLabel,
    required this.deviationFraction,
    required this.color,
    this.onTap,
  });

  final String name;

  /// Texto de la desviacion ya formateado, p.ej. "+32%".
  final String deviationLabel;

  /// Largo de la barra 0..1.
  final double deviationFraction;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: DeviationBar(
        label: name,
        valueLabel: deviationLabel,
        fraction: deviationFraction,
        color: color,
      ),
    );
  }
}

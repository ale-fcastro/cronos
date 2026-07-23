import 'package:flutter/material.dart';
import '../cards/metric_card.dart';
import 'trend_indicator.dart';

/// KPI de la pantalla Analizar: alias semantico de MetricCard con delta.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trend,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TrendIndicator? trend;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      label: label,
      value: value,
      valueColor: valueColor,
      trend: trend,
    );
  }
}

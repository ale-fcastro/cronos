import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

/// Observacion generada por los datos ("Las tareas de X duran un tercio mas...").
/// Texto plano, sin decoracion: el sistema habla con datos, no con banners.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.text, this.title});

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
          Text(text,
              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }
}

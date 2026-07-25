import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/shared.dart';

/// Pantalla "Soporte": datos de contacto del desarrollador.
class SupportInfoPage extends StatelessWidget {
  const SupportInfoPage({super.key});

  static const _phoneDisplay = '+1 829 693 2458';
  static const _phoneDial = '+18296932458';
  static const _phoneDigits = '18296932458';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIconButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Gaps.hSm,
                  const Text('Soporte', style: AppTextStyles.headline),
                ],
              ),
              Gaps.vLg,
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.accent, size: 26),
                    ),
                    Gaps.hMd,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Francisco Castro', style: AppTextStyles.title),
                          SizedBox(height: 2),
                          Text(
                            'Desarrollador de software independiente',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.vLg,
              const SectionHeader(title: 'Contacto'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _contactRow(
                      icon: Icons.chat_bubble_rounded,
                      label: 'WhatsApp',
                      value: _phoneDisplay,
                      onTap: () => launchUrl(
                        Uri.parse('https://wa.me/$_phoneDigits'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    const Divider(height: 1),
                    _contactRow(
                      icon: Icons.call_rounded,
                      label: 'Llamar',
                      value: _phoneDisplay,
                      onTap: () =>
                          launchUrl(Uri.parse('tel:$_phoneDial')),
                    ),
                  ],
                ),
              ),
              Gaps.vSm,
              const AppCaption('República Dominicana'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            Gaps.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body),
                  Text(value, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

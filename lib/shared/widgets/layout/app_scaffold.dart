import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Scaffold estandar: fondo del sistema, padding horizontal de pagina,
/// slots para header, bottom nav y FAB.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottomNavigation,
    this.fab,
    this.padded = true,
  });

  final Widget body;

  /// Cabecera fija sobre el contenido (PageHeader, segmentados...).
  final Widget? header;
  final Widget? bottomNavigation;
  final Widget? fab;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (header != null)
              Padding(padding: AppSpacing.page, child: header),
            Expanded(
              child: padded
                  ? Padding(padding: AppSpacing.page, child: body)
                  : body,
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomNavigation,
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Drawer sobrio para rutas secundarias (configuracion, exportar, acerca de).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.header, required this.children});

  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (header != null) ...[header!, const Divider(height: 24)],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Entrada estandar del drawer.
class AppDrawerItem extends StatelessWidget {
  const AppDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: selected,
      selectedTileColor: AppColors.accentSoft,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      leading: Icon(icon,
          size: 20,
          color: selected ? AppColors.accent : AppColors.textSecondary),
      title: Text(label,
          style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.accent : AppColors.textPrimary)),
      dense: true,
    );
  }
}

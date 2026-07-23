import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../buttons/app_fab.dart';

/// Destino de la barra inferior.
class BottomBarItem {
  const BottomBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra inferior del sistema: 4 destinos + FAB central de registro.
/// El FAB no es un destino: es la accion mas frecuente (registrar).
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.onFabPressed,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Si es null no se muestra el FAB central.
  final VoidCallback? onFabPressed;

  @override
  Widget build(BuildContext context) {
    final half = (items.length / 2).ceil();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (onFabPressed != null && i == half)
                  Expanded(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -8),
                        child: AppFab(onPressed: onFabPressed),
                      ),
                    ),
                  ),
                Expanded(child: _destination(i)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _destination(int i) {
    final selected = i == currentIndex;
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(i),
        borderRadius: AppRadius.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 52,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(13)),
              ),
              child: Icon(items[i].icon, size: 19, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              items[i].label,
              style: TextStyle(
                fontFamily: AppTextStyles.sans,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

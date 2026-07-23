import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'bottom_bar.dart';

/// Rail lateral para pantallas anchas (tablet/desktop). Mismos destinos
/// que BottomBar; el FAB de registro se coloca como leading.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.leading,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AppColors.navBackground,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: AppColors.accentSoft,
      selectedIconTheme: const IconThemeData(color: AppColors.accent, size: 20),
      unselectedIconTheme:
          const IconThemeData(color: AppColors.textSecondary, size: 20),
      selectedLabelTextStyle: const TextStyle(
          color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      labelType: NavigationRailLabelType.all,
      leading: leading,
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

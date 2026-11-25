import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// 底部四 Tab 导航栏：复习、测验、错题本（带待攻克角标）、查结构。
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.mistakeCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int mistakeCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: '复习',
          ),
          const NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: '测验',
          ),
          NavigationDestination(
            icon: _MistakeNavIcon(
              icon: Icons.star_outline_rounded,
              count: mistakeCount,
            ),
            selectedIcon: _MistakeNavIcon(
              icon: Icons.star_rounded,
              count: mistakeCount,
            ),
            label: '错题本',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: '查结构',
          ),
        ],
      ),
    );
  }
}

class _MistakeNavIcon extends StatelessWidget {
  const _MistakeNavIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    final palette = AppPalette.of(context);
    final badgeText = count > 99 ? '99+' : '$count';
    return Badge(
      backgroundColor: palette.amber,
      textColor: palette.isDark ? const Color(0xFF0E141B) : Colors.white,
      label: Text(
        badgeText,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      child: Icon(icon),
    );
  }
}

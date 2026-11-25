import 'package:material_ui/material_ui.dart';

import '../data/study_preferences_store.dart';
import 'app_theme.dart';

/// 外观与护眼主题选择面板，支持浅色、深色护眼与跟随系统三态切换。
class ThemeModeSheet extends StatelessWidget {
  const ThemeModeSheet({
    super.key,
    required this.currentMode,
    required this.onSelected,
  });

  final AppThemePreference currentMode;
  final ValueChanged<AppThemePreference> onSelected;

  static Future<void> show(
    BuildContext context, {
    required AppThemePreference currentMode,
    required ValueChanged<AppThemePreference> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          ThemeModeSheet(currentMode: currentMode, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('外观与护眼模式', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '深色护眼模式采用低蓝光夜蓝底色并自动柔和反色结构式线条',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              palette: palette,
              preference: AppThemePreference.light,
              icon: Icons.light_mode_rounded,
              title: '日间蓝图',
              subtitle: '冷调浅灰蓝画布配炭黑矢量结构式',
              swatchBg: AppPalette.light.canvas,
              swatchAccent: AppPalette.light.primary,
            ),
            const SizedBox(height: 10),
            _buildOption(
              context,
              palette: palette,
              preference: AppThemePreference.dark,
              icon: Icons.dark_mode_rounded,
              title: '深色护眼',
              subtitle: '深石板夜蓝底色配月光白结构式，适合夜间背诵',
              swatchBg: AppPalette.dark.canvas,
              swatchAccent: AppPalette.dark.primary,
            ),
            const SizedBox(height: 10),
            _buildOption(
              context,
              palette: palette,
              preference: AppThemePreference.system,
              icon: Icons.brightness_auto_rounded,
              title: '跟随系统',
              subtitle: '根据手机系统外观自动切换日间与夜间护眼主题',
              swatchBg: palette.badgeSurface,
              swatchAccent: palette.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required AppPalette palette,
    required AppThemePreference preference,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color swatchBg,
    required Color swatchAccent,
  }) {
    final selected = currentMode == preference;
    return Material(
      color: selected ? palette.primarySoft : palette.structureSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          onSelected(preference);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.primary : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: swatchBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(icon, size: 20, color: swatchAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? palette.primary : palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../../data/study_preferences_store.dart';
import '../../theme/app_theme.dart';

class ReviewHeader extends StatelessWidget {
  const ReviewHeader({
    super.key,
    required this.totalCount,
    required this.revealedCount,
    required this.progress,
    required this.scopeLabel,
    required this.lastDrugId,
    required this.hasProgress,
    required this.themePreference,
    required this.onOpenThemeSheet,
    required this.onJumpToLast,
    required this.onReset,
  });

  final int totalCount;
  final int revealedCount;
  final double progress;
  final String scopeLabel;
  final String? lastDrugId;
  final bool hasProgress;
  final AppThemePreference themePreference;
  final VoidCallback onOpenThemeSheet;
  final VoidCallback? onJumpToLast;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(palette),
            const SizedBox(height: 12),
            Text('结构式复习', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '观察结构回忆药名，核对进度与难点自动保存在本地',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _buildProgressSection(context, palette),
            if (lastDrugId != null && onJumpToLast != null) ...[
              const SizedBox(height: 12),
              _buildResumeBanner(palette),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(AppPalette palette) {
    final themeIcon = switch (themePreference) {
      AppThemePreference.dark => Icons.dark_mode_rounded,
      AppThemePreference.light => Icons.light_mode_rounded,
      AppThemePreference.system => Icons.brightness_auto_rounded,
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science_outlined, size: 14, color: palette.primary),
              const SizedBox(width: 5),
              Text(
                '药物化学 · 考研全章',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _HeaderActionButton(
          icon: themeIcon,
          tooltip: '切换护眼主题',
          onTap: onOpenThemeSheet,
        ),
        if (hasProgress && onReset != null) ...[
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: palette.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text(
              '重置',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, AppPalette palette) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                scopeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$revealedCount / $totalCount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: palette.primaryDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: palette.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeBanner(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primarySoftBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, size: 16, color: palette.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '上次复习至 No. $lastDrugId',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.primaryDeep,
              ),
            ),
          ),
          TextButton(
            onPressed: onJumpToLast,
            style: TextButton.styleFrom(
              foregroundColor: palette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '定位到此处',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.badgeSurface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(icon, size: 16, color: palette.primaryDeep),
          ),
        ),
      ),
    );
  }
}

class FloatingBackToTopButton extends StatelessWidget {
  const FloatingBackToTopButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surface,
      elevation: 4,
      shadowColor: palette.cardShadow,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: palette.primaryDeep,
              ),
              const SizedBox(width: 4),
              Text(
                '顶部',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.primaryDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetProgressDialog extends StatelessWidget {
  const ResetProgressDialog({
    super.key,
    required this.revealedCount,
    required this.lastDrugId,
  });

  final int revealedCount;
  final String? lastDrugId;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final detail = lastDrugId != null
        ? '当前已核对 $revealedCount 种药物，上次停留在 No. $lastDrugId。重置后将收起所有药名并清除进度位置（错题本标记不受影响）。'
        : '当前已核对 $revealedCount 种药物。重置后将收起所有药名并清除进度位置（错题本标记不受影响）。';

    return AlertDialog(
      title: const Text('重置复习进度'),
      content: Text(detail, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: palette.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('确认重置'),
        ),
      ],
    );
  }
}

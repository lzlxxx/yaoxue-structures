import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'encouragement_content.dart';

/// 每天首次打开应用时弹出的专属考研鼓励大卡片。
class DailyWelcomeDialog extends StatelessWidget {
  const DailyWelcomeDialog({
    super.key,
    required this.data,
    required this.studyDaysCount,
    required this.revealedCount,
    required this.totalDrugCount,
    required this.showDarkModeShortcut,
    required this.onEnableDarkMode,
  });

  final WelcomeCardData data;
  final int studyDaysCount;
  final int revealedCount;
  final int totalDrugCount;
  final bool showDarkModeShortcut;
  final VoidCallback onEnableDarkMode;

  static Future<void> show(
    BuildContext context, {
    required WelcomeCardData data,
    required int studyDaysCount,
    required int revealedCount,
    required int totalDrugCount,
    required bool showDarkModeShortcut,
    required VoidCallback onEnableDarkMode,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0x99070B11),
      builder: (_) => DailyWelcomeDialog(
        data: data,
        studyDaysCount: studyDaysCount,
        revealedCount: revealedCount,
        totalDrugCount: totalDrugCount,
        showDarkModeShortcut: showDarkModeShortcut,
        onEnableDarkMode: onEnableDarkMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBadgeRow(palette),
            const SizedBox(height: 14),
            Text(data.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildQuoteCard(palette),
            const SizedBox(height: 12),
            _buildProgressPill(palette),
            if (showDarkModeShortcut) ...[
              const SizedBox(height: 10),
              _buildNightModeShortcut(context, palette),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '开始今天的学习',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBadgeRow(AppPalette palette) {
    final icon = switch (data.period) {
      GreetingPeriod.morning => Icons.wb_sunny_rounded,
      GreetingPeriod.afternoon => Icons.wb_cloudy_rounded,
      GreetingPeriod.evening => Icons.nights_stay_rounded,
      GreetingPeriod.lateNight => Icons.bedtime_rounded,
    };
    final accent = data.isLateNight ? palette.amber : palette.primary;
    final softBg = data.isLateNight ? palette.amberSoft : palette.primarySoft;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                data.periodTag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: palette.badgeSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '累计陪伴第 $studyDaysCount 天',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.structureSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.structureBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.5,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.quote,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill(AppPalette palette) {
    return Row(
      children: [
        Icon(Icons.auto_graph_rounded, size: 15, color: palette.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '当前已核对 $revealedCount / $totalDrugCount 种代表药',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNightModeShortcut(BuildContext context, AppPalette palette) {
    return OutlinedButton.icon(
      onPressed: () {
        onEnableDarkMode();
        Navigator.of(context).pop();
      },
      icon: Icon(Icons.dark_mode_rounded, size: 16, color: palette.amber),
      label: const Text(
        '一键开启深色护眼模式',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.amber,
        side: BorderSide(color: palette.amberBorder),
        backgroundColor: palette.amberSoft,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// 准备离开应用时弹出的暖心告别鼓励卡片，返回 true 表示确认退出。
class ExitFarewellDialog extends StatelessWidget {
  const ExitFarewellDialog({super.key, required this.data});

  final FarewellCardData data;

  static Future<bool> show(
    BuildContext context, {
    required FarewellCardData data,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99070B11),
      builder: (_) => ExitFarewellDialog(data: data),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final icon = data.isLateNight
        ? Icons.bedtime_outlined
        : Icons.local_cafe_rounded;
    final badgeBg = data.isLateNight ? palette.amberSoft : palette.successSoft;
    final badgeFg = data.isLateNight ? palette.amber : palette.success;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: badgeFg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: palette.structureSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.structureBorder),
              ),
              child: Text(
                data.sessionSummary,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.careTip,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
            _buildActions(context, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.textSecondary,
              side: BorderSide(color: palette.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '先去休息',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '再看一会儿',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

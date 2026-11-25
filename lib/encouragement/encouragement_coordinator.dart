import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/study_preferences_store.dart';
import '../theme/app_theme.dart';
import 'encouragement_content.dart';
import 'encouragement_dialogs.dart';

/// 启动每日鼓励大卡片 / 再次打开轻提示 / 退出告别账单展示协调器。
abstract final class EncouragementCoordinator {
  /// 根据当日是否首次启动展示鼓励弹窗或悬浮轻提示，返回更新后的偏好快照（如有打卡递增）。
  static StudyPreferencesSnapshot? handleAppLaunch(
    BuildContext context, {
    required StudyPreferencesSnapshot prefs,
    required int revealedCount,
    required int totalDrugCount,
    required VoidCallback onEnableDarkMode,
  }) {
    final now = DateTime.now();
    final todayKey = EncouragementContent.formatDateKey(now);
    if (prefs.lastWelcomeDate == todayKey) {
      _showReturnBanner(context);
      return null;
    }

    final data = EncouragementContent.buildWelcomeData(
      now: now,
      lastMessageIndex: prefs.lastMessageIndex,
    );
    final nextStudyDays = prefs.studyDaysCount + 1;
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;
    unawaited(
      DailyWelcomeDialog.show(
        context,
        data: data,
        studyDaysCount: nextStudyDays,
        revealedCount: revealedCount,
        totalDrugCount: totalDrugCount,
        showDarkModeShortcut: data.isLateNight && !isCurrentlyDark,
        onEnableDarkMode: onEnableDarkMode,
      ),
    );
    return prefs.copyWith(
      lastWelcomeDate: todayKey,
      studyDaysCount: nextStudyDays,
      lastMessageIndex: data.messageIndex,
    );
  }

  static Future<bool> confirmAppExit(
    BuildContext context, {
    required int sessionRevealedCount,
    required int sessionQuizCount,
  }) {
    final data = EncouragementContent.buildFarewellData(
      now: DateTime.now(),
      sessionRevealedCount: sessionRevealedCount,
      sessionQuizCount: sessionQuizCount,
    );
    return ExitFarewellDialog.show(context, data: data);
  }

  static void _showReturnBanner(BuildContext context) {
    final palette = AppPalette.of(context);
    final message = EncouragementContent.buildReturnBanner();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 2500),
        content: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 17, color: palette.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

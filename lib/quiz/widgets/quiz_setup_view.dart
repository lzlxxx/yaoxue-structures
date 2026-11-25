import 'package:material_ui/material_ui.dart';

import '../../data/drug_catalog_helper.dart';
import '../../data/quiz_engine.dart';
import '../../data/study_preferences_store.dart';
import '../../theme/app_theme.dart';
import 'quiz_setup_components.dart';

/// 互动四选一测验的配置界面：选择题型、药理大类/二级小类范围、题量、考场旋转与已屏蔽管理。
class QuizSetupView extends StatelessWidget {
  const QuizSetupView({
    super.key,
    required this.totalDrugCount,
    required this.mistakeCount,
    required this.excludedCount,
    required this.chapters,
    required this.subcategories,
    required this.questionType,
    required this.scope,
    required this.selectedChapter,
    required this.selectedSubcategory,
    required this.desiredCount,
    required this.availablePoolCount,
    required this.examRotationEnabled,
    required this.themePreference,
    required this.lastQuizCorrect,
    required this.lastQuizTotal,
    required this.lastQuizDurationSeconds,
    required this.onQuestionTypeChanged,
    required this.onScopeChanged,
    required this.onChapterChanged,
    required this.onSubcategoryChanged,
    required this.onDesiredCountChanged,
    required this.onToggleExamRotation,
    required this.onOpenExcluded,
    required this.onOpenThemeSheet,
    required this.onStartQuiz,
  });

  final int totalDrugCount;
  final int mistakeCount;
  final int excludedCount;
  final List<ChapterSummary> chapters;
  final List<SubcategorySummary> subcategories;
  final QuizQuestionType questionType;
  final QuizScope scope;
  final String? selectedChapter;
  final String? selectedSubcategory;
  final int desiredCount;
  final int availablePoolCount;
  final bool examRotationEnabled;
  final AppThemePreference themePreference;
  final int? lastQuizCorrect;
  final int? lastQuizTotal;
  final int? lastQuizDurationSeconds;
  final ValueChanged<QuizQuestionType> onQuestionTypeChanged;
  final ValueChanged<QuizScope> onScopeChanged;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final ValueChanged<int> onDesiredCountChanged;
  final VoidCallback onToggleExamRotation;
  final VoidCallback onOpenExcluded;
  final VoidCallback onOpenThemeSheet;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final effectiveCount = desiredCount <= 0
        ? availablePoolCount
        : (availablePoolCount < desiredCount
              ? availablePoolCount
              : desiredCount);
    final canStart = effectiveCount > 0 && totalDrugCount >= 4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        _buildHeaderCard(context),
        const SizedBox(height: 14),
        _buildQuestionTypeCard(),
        const SizedBox(height: 12),
        _buildScopeCard(context),
        const SizedBox(height: 12),
        _buildCountAndRotationCard(context),
        const SizedBox(height: 18),
        _buildStartButton(effectiveCount, canStart),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final palette = AppPalette.of(context);
    final themeIcon = switch (themePreference) {
      AppThemePreference.dark => Icons.dark_mode_rounded,
      AppThemePreference.light => Icons.light_mode_rounded,
      AppThemePreference.system => Icons.brightness_auto_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, size: 14, color: palette.primary),
                    const SizedBox(width: 5),
                    Text(
                      '同族高迷惑四选一',
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
              QuizThemeIconButton(icon: themeIcon, onTap: onOpenThemeSheet),
            ],
          ),
          const SizedBox(height: 12),
          Text('模拟测验', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '优先抽取同小类与同大类干扰项，自动跳过已屏蔽结构式，答错收入错题本',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (lastQuizCorrect != null &&
              lastQuizTotal != null &&
              lastQuizTotal! > 0) ...[
            const SizedBox(height: 12),
            _buildLastScoreStrip(palette),
          ],
        ],
      ),
    );
  }

  Widget _buildLastScoreStrip(AppPalette palette) {
    final rate = ((lastQuizCorrect! / lastQuizTotal!) * 100).round();
    final sec = lastQuizDurationSeconds;
    final durationLabel = sec == null ? '' : ' · 用时 ${_formatDuration(sec)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primarySoftBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, size: 16, color: palette.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '上次测验：$lastQuizCorrect / $lastQuizTotal（正确率 $rate%）$durationLabel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: palette.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeCard() {
    return QuizSetupSectionCard(
      title: '测验题型',
      child: Row(
        children: [
          Expanded(
            child: QuizSelectableTile(
              icon: Icons.image_search_rounded,
              label: '看图选名',
              selected: questionType == QuizQuestionType.structureToName,
              onTap: () =>
                  onQuestionTypeChanged(QuizQuestionType.structureToName),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QuizSelectableTile(
              icon: Icons.grid_view_rounded,
              label: '看名选图',
              selected: questionType == QuizQuestionType.nameToStructure,
              onTap: () =>
                  onQuestionTypeChanged(QuizQuestionType.nameToStructure),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QuizSelectableTile(
              icon: Icons.auto_awesome_rounded,
              label: '混合题型',
              selected: questionType == QuizQuestionType.mixed,
              onTap: () => onQuestionTypeChanged(QuizQuestionType.mixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeCard(BuildContext context) {
    final palette = AppPalette.of(context);
    final activeTotal = totalDrugCount - excludedCount;
    return QuizSetupSectionCard(
      title: '出题范围',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QuizPillOption(
                label: '全部可测 ($activeTotal)',
                selected: scope == QuizScope.all,
                onTap: () => onScopeChanged(QuizScope.all),
              ),
              QuizPillOption(
                label: '错题本专项 ($mistakeCount)',
                selected: scope == QuizScope.mistakes,
                accentAmber: true,
                onTap: () => onScopeChanged(QuizScope.mistakes),
              ),
              QuizPillOption(
                label: '按药理分类',
                selected: scope == QuizScope.chapter,
                onTap: () => onScopeChanged(QuizScope.chapter),
              ),
            ],
          ),
          if (scope == QuizScope.chapter) ...[
            const SizedBox(height: 10),
            QuizCategoryPickers(
              totalDrugCount: activeTotal,
              chapters: chapters,
              subcategories: subcategories,
              selectedChapter: selectedChapter,
              selectedSubcategory: selectedSubcategory,
              onSelectAllScope: () => onScopeChanged(QuizScope.all),
              onChapterChanged: onChapterChanged,
              onSubcategoryChanged: onSubcategoryChanged,
            ),
          ],
          if (scope == QuizScope.mistakes && mistakeCount == 0) ...[
            const SizedBox(height: 8),
            Text(
              '当前错题本暂无可测难点药物，可先在「复习」或「查结构」中标难后再测。',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          _buildExcludedStrip(palette),
        ],
      ),
    );
  }

  Widget _buildExcludedStrip(AppPalette palette) {
    final hasExcluded = excludedCount > 0;
    return Material(
      color: hasExcluded ? palette.badgeSurface : palette.structureSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpenExcluded,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasExcluded ? palette.primarySoftBorder : palette.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 16,
                color: hasExcluded ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasExcluded
                      ? '已自动过滤 $excludedCount 种手动屏蔽的结构式'
                      : '已屏蔽结构式 (0) · 复习时可随时屏蔽不考条目',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasExcluded ? FontWeight.w600 : FontWeight.w500,
                    color: hasExcluded
                        ? palette.primaryDeep
                        : palette.textSecondary,
                  ),
                ),
              ),
              Text(
                '已屏蔽 ($excludedCount)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: palette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountAndRotationCard(BuildContext context) {
    final palette = AppPalette.of(context);
    const counts = <(int, String)>[
      (10, '10 题'),
      (20, '20 题'),
      (30, '30 题'),
      (0, '全部'),
    ];
    return QuizSetupSectionCard(
      title: '题量与防背图设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: counts
                .map(
                  (item) => QuizPillOption(
                    label: item.$2,
                    selected: desiredCount == item.$1,
                    onTap: () => onDesiredCountChanged(item.$1),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          _buildRotationSwitchTile(palette),
        ],
      ),
    );
  }

  Widget _buildRotationSwitchTile(AppPalette palette) {
    return Material(
      color: examRotationEnabled
          ? palette.primarySoft
          : palette.structureSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggleExamRotation,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: examRotationEnabled ? palette.primary : palette.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.screen_rotation_alt_rounded,
                size: 18,
                color: examRotationEnabled
                    ? palette.primary
                    : palette.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拟真考场旋转（0° / 90° / 180° / 270°）',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '保持手性与文字正立，随机变换出图朝向防背图',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: examRotationEnabled,
                onChanged: (_) => onToggleExamRotation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(int effectiveCount, bool canStart) {
    final label = canStart ? '开始测验（共 $effectiveCount 题）' : '当前范围暂无可测题目';
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: canStart ? onStartQuiz : null,
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '$secs秒';
    return '$mins分${secs.toString().padLeft(2, '0')}秒';
  }
}

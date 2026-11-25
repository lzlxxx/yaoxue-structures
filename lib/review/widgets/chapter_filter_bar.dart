import 'package:material_ui/material_ui.dart';

import '../../data/drug_catalog_helper.dart';
import '../../data/study_preferences_store.dart';
import '../../theme/app_theme.dart';
import 'chapter_overview_sheet.dart';
import 'filter_bar_chips.dart';

/// 药理大类 + 二级小类筛选横向胶囊栏，以及顺序/乱序、考场旋转与已屏蔽管理控制条。
class ChapterFilterBar extends StatelessWidget {
  const ChapterFilterBar({
    super.key,
    required this.chapters,
    required this.totalCount,
    required this.selectedChapter,
    required this.onChapterChanged,
    this.subcategories = const <SubcategorySummary>[],
    this.selectedSubcategory,
    this.onSubcategoryChanged,
    this.orderMode,
    this.onOrderModeChanged,
    this.onReshuffle,
    this.examRotationEnabled,
    this.onToggleExamRotation,
    this.excludedCount,
    this.onOpenExcluded,
    this.showProgressInSheet = true,
  });

  final List<ChapterSummary> chapters;
  final int totalCount;
  final String? selectedChapter;
  final ValueChanged<String?> onChapterChanged;
  final List<SubcategorySummary> subcategories;
  final String? selectedSubcategory;
  final ValueChanged<String?>? onSubcategoryChanged;
  final StudyOrderMode? orderMode;
  final ValueChanged<StudyOrderMode>? onOrderModeChanged;
  final VoidCallback? onReshuffle;
  final bool? examRotationEnabled;
  final VoidCallback? onToggleExamRotation;
  final int? excludedCount;
  final VoidCallback? onOpenExcluded;
  final bool showProgressInSheet;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final showSubcategories =
        selectedChapter != null &&
        subcategories.length > 1 &&
        onSubcategoryChanged != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChapterStrip(context, palette),
          if (showSubcategories) ...[
            const SizedBox(height: 8),
            _buildSubcategoryStrip(palette),
          ],
          if (orderMode != null && onOrderModeChanged != null) ...[
            const SizedBox(height: 10),
            _buildOrderControls(palette),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterStrip(BuildContext context, AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chapters.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChapterChip(
                    label: '全部',
                    count: totalCount,
                    selected: selectedChapter == null,
                    onTap: () => onChapterChanged(null),
                  );
                }
                final chapter = chapters[index - 1];
                return FilterChapterChip(
                  label: chapter.name,
                  count: chapter.totalCount,
                  selected: selectedChapter == chapter.name,
                  onTap: () => onChapterChanged(chapter.name),
                );
              },
            ),
          ),
        ),
        if (chapters.isNotEmpty) ...[
          const SizedBox(width: 8),
          Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _openChapterSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: palette.primaryDeep,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubcategoryStrip(AppPalette palette) {
    final chapterTotal = subcategories.fold<int>(
      0,
      (sum, item) => sum + item.totalCount,
    );
    return Row(
      children: [
        Icon(
          Icons.subdirectory_arrow_right_rounded,
          size: 15,
          color: palette.textMuted,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subcategories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterSubcategoryChip(
                    label: '全部小类',
                    count: chapterTotal,
                    selected: selectedSubcategory == null,
                    onTap: () => onSubcategoryChanged!(null),
                  );
                }
                final item = subcategories[index - 1];
                return FilterSubcategoryChip(
                  label: item.name,
                  count: item.totalCount,
                  selected: selectedSubcategory == item.name,
                  onTap: () => onSubcategoryChanged!(item.name),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderControls(AppPalette palette) {
    final isShuffled = orderMode == StudyOrderMode.shuffled;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildOrderSegmentGroup(palette, isShuffled),
        if (isShuffled && onReshuffle != null) _buildReshuffleButton(palette),
        if (examRotationEnabled != null && onToggleExamRotation != null)
          _buildRotationToggle(palette, examRotationEnabled!),
        if (excludedCount != null && onOpenExcluded != null)
          _buildExcludedButton(palette, excludedCount!),
      ],
    );
  }

  Widget _buildOrderSegmentGroup(AppPalette palette, bool isShuffled) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterOrderSegment(
            icon: Icons.format_list_numbered_rounded,
            label: '顺序',
            selected: !isShuffled,
            onTap: () => onOrderModeChanged!(StudyOrderMode.sequential),
          ),
          const SizedBox(width: 2),
          FilterOrderSegment(
            icon: Icons.shuffle_rounded,
            label: '乱序',
            selected: isShuffled,
            onTap: () => onOrderModeChanged!(StudyOrderMode.shuffled),
          ),
        ],
      ),
    );
  }

  Widget _buildReshuffleButton(AppPalette palette) {
    return Material(
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onReshuffle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.primarySoftBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.casino_outlined, size: 15, color: palette.primary),
              const SizedBox(width: 4),
              Text(
                '洗牌',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotationToggle(AppPalette palette, bool enabled) {
    return Material(
      color: enabled ? palette.primarySoft : palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onToggleExamRotation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? palette.primary : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screen_rotation_alt_rounded,
                size: 15,
                color: enabled ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                enabled ? '考场旋转 · 开' : '考场旋转',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: enabled ? FontWeight.w700 : FontWeight.w600,
                  color: enabled ? palette.primary : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcludedButton(AppPalette palette, int count) {
    final active = count > 0;
    return Material(
      color: active ? palette.badgeSurface : palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpenExcluded,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? palette.primarySoftBorder : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                size: 15,
                color: active ? palette.primaryDeep : palette.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                active ? '已屏蔽 ($count)' : '已屏蔽',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: active ? palette.primaryDeep : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChapterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChapterOverviewSheet(
        chapters: chapters,
        totalCount: totalCount,
        selectedChapter: selectedChapter,
        showProgress: showProgressInSheet,
        onSelected: (chapter) {
          onChapterChanged(chapter);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

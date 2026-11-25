import 'package:material_ui/material_ui.dart';

import '../../data/drug_catalog_helper.dart';
import '../../review/widgets/chapter_overview_sheet.dart';
import '../../theme/app_theme.dart';

/// 测验配置页通用卡片容器。
class QuizSetupSectionCard extends StatelessWidget {
  const QuizSetupSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 测验题型选择方块。
class QuizSelectableTile extends StatelessWidget {
  const QuizSelectableTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.primarySoft : palette.structureSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.primary : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? palette.primary : palette.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? palette.primaryDeep : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 测验配置胶囊按钮。
class QuizPillOption extends StatelessWidget {
  const QuizPillOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentAmber = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool accentAmber;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final activeBg = accentAmber ? palette.amberSoft : palette.primarySoft;
    final activeBorder = accentAmber ? palette.amber : palette.primary;
    final activeFg = accentAmber ? palette.amber : palette.primaryDeep;

    return Material(
      color: selected ? activeBg : palette.structureSurface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? activeBorder : palette.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? activeFg : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 测验页顶栏护眼主题按钮。
class QuizThemeIconButton extends StatelessWidget {
  const QuizThemeIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Tooltip(
      message: '切换护眼主题',
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

/// 测验配置页的 24 大类 + 二级小类联动选择器，支持底部总览弹窗秒选大类。
class QuizCategoryPickers extends StatelessWidget {
  const QuizCategoryPickers({
    super.key,
    required this.totalDrugCount,
    required this.chapters,
    required this.subcategories,
    required this.selectedChapter,
    required this.selectedSubcategory,
    required this.onSelectAllScope,
    required this.onChapterChanged,
    required this.onSubcategoryChanged,
  });

  final int totalDrugCount;
  final List<ChapterSummary> chapters;
  final List<SubcategorySummary> subcategories;
  final String? selectedChapter;
  final String? selectedSubcategory;
  final VoidCallback onSelectAllScope;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<String?> onSubcategoryChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildChapterRow(context, palette),
        if (subcategories.length > 1) ...[
          const SizedBox(height: 8),
          _buildSubcategoryRow(palette),
        ],
      ],
    );
  }

  Widget _buildChapterRow(BuildContext context, AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chapters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return QuizPillOption(
                  label: '${chapter.name} (${chapter.totalCount})',
                  selected: selectedChapter == chapter.name,
                  onTap: () => onChapterChanged(chapter.name),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: palette.structureSurface,
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
    );
  }

  Widget _buildSubcategoryRow(AppPalette palette) {
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
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subcategories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return QuizPillOption(
                    label: '全部小类 ($chapterTotal)',
                    selected: selectedSubcategory == null,
                    onTap: () => onSubcategoryChanged(null),
                  );
                }
                final item = subcategories[index - 1];
                return QuizPillOption(
                  label: '${item.name} (${item.totalCount})',
                  selected: selectedSubcategory == item.name,
                  onTap: () => onSubcategoryChanged(item.name),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openChapterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChapterOverviewSheet(
        chapters: chapters,
        totalCount: totalDrugCount,
        selectedChapter: selectedChapter,
        showProgress: false,
        onSelected: (chapter) {
          if (chapter == null) {
            onSelectAllScope();
          } else {
            onChapterChanged(chapter);
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

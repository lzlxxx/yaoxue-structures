import 'package:material_ui/material_ui.dart';

import '../../data/drug_catalog_helper.dart';
import '../../theme/app_theme.dart';

/// 全部章节总览底部弹窗，展示每章总药数、已核对数与难点数。
class ChapterOverviewSheet extends StatelessWidget {
  const ChapterOverviewSheet({
    super.key,
    required this.chapters,
    required this.totalCount,
    required this.selectedChapter,
    required this.showProgress,
    required this.onSelected,
  });

  final List<ChapterSummary> chapters;
  final int totalCount;
  final String? selectedChapter;
  final bool showProgress;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '按药理大类筛选',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '共 ${chapters.length} 个药理大类，同小类药物已按顺序连贯排列',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: chapters.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildRow(
                      context,
                      palette: palette,
                      title: '全部药理大类',
                      meta: '共 $totalCount 种药物',
                      selected: selectedChapter == null,
                      onTap: () => onSelected(null),
                    );
                  }
                  final chapter = chapters[index - 1];
                  final segments = <String>[
                    if (chapter.subcategoryCount > 1)
                      '${chapter.subcategoryCount} 个小类',
                    if (showProgress)
                      '已核对 ${chapter.revealedCount} / ${chapter.totalCount}'
                    else
                      '共 ${chapter.totalCount} 种药物',
                    if (showProgress && chapter.difficultCount > 0)
                      '难点 ${chapter.difficultCount}',
                  ];
                  final meta = segments.join(' · ');
                  return _buildRow(
                    context,
                    palette: palette,
                    title: chapter.name,
                    meta: meta,
                    selected: selectedChapter == chapter.name,
                    onTap: () => onSelected(chapter.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required AppPalette palette,
    required String title,
    required String meta,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? palette.primarySoft : palette.structureSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.primary : palette.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
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

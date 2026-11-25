import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/study_preferences_store.dart';
import '../review/widgets/chapter_filter_bar.dart';
import '../review/widgets/drug_card.dart';
import '../theme/app_theme.dart';

/// 错题本页面：集中攻克未屏蔽的难点药物，支持按大类/小类筛选、乱序复习与已掌握移出。
class MistakeBookPage extends StatefulWidget {
  const MistakeBookPage({
    super.key,
    required this.drugs,
    required this.difficultIds,
    required this.excludedIds,
    required this.orderMode,
    required this.shuffledIds,
    required this.examRotationEnabled,
    required this.rotationAngles,
    required this.themePreference,
    required this.onOrderModeChanged,
    required this.onReshuffle,
    required this.onToggleExamRotation,
    required this.onToggleDifficult,
    required this.onMarkMastered,
    required this.onClearAllDifficult,
    required this.onOpenThemeSheet,
    required this.onGoToReview,
  });

  final List<Drug> drugs;
  final Set<String> difficultIds;
  final Set<String> excludedIds;
  final StudyOrderMode orderMode;
  final List<String> shuffledIds;
  final bool examRotationEnabled;
  final Map<String, int> rotationAngles;
  final AppThemePreference themePreference;
  final ValueChanged<StudyOrderMode> onOrderModeChanged;
  final VoidCallback onReshuffle;
  final VoidCallback onToggleExamRotation;
  final ValueChanged<Drug> onToggleDifficult;
  final ValueChanged<Drug> onMarkMastered;
  final Future<void> Function() onClearAllDifficult;
  final VoidCallback onOpenThemeSheet;
  final VoidCallback onGoToReview;

  @override
  State<MistakeBookPage> createState() => _MistakeBookPageState();
}

class _MistakeBookPageState extends State<MistakeBookPage> {
  final Set<String> _revealedIds = <String>{};
  String? _selectedChapter;
  String? _selectedSubcategory;

  List<Drug> _allDifficultDrugs() {
    return widget.drugs
        .where(
          (drug) =>
              widget.difficultIds.contains(drug.id) &&
              !widget.excludedIds.contains(drug.id),
        )
        .toList(growable: false);
  }

  void _toggleReveal(String drugId) {
    setState(() {
      if (!_revealedIds.add(drugId)) {
        _revealedIds.remove(drugId);
      }
    });
  }

  Future<void> _confirmClearAll(int activeCount) async {
    final palette = AppPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空错题本'),
        content: Text(
          '确定要移出错题本中的全部 $activeCount 种难点药物吗？',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _revealedIds.clear();
      _selectedChapter = null;
      _selectedSubcategory = null;
    });
    await widget.onClearAllDifficult();
  }

  @override
  Widget build(BuildContext context) {
    final difficultDrugs = _allDifficultDrugs();
    if (difficultDrugs.isEmpty) {
      return _buildEmptyState(context);
    }

    final chapters = DrugCatalogHelper.buildChapterSummaries(
      difficultDrugs,
      revealedIds: _revealedIds,
      difficultIds: widget.difficultIds,
    );
    final activeChapter =
        chapters.any((chapter) => chapter.name == _selectedChapter)
        ? _selectedChapter
        : null;
    final subcategories = DrugCatalogHelper.buildSubcategorySummaries(
      difficultDrugs,
      chapter: activeChapter,
      revealedIds: _revealedIds,
      difficultIds: widget.difficultIds,
    );
    final activeSubcategory =
        subcategories.any((item) => item.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    final displayed = DrugCatalogHelper.selectDrugs(
      difficultDrugs,
      chapter: activeChapter,
      subcategory: activeSubcategory,
      orderMode: widget.orderMode,
      shuffledIds: widget.shuffledIds,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderCard(
            context,
            totalDifficult: difficultDrugs.length,
            displayedCount: displayed.length,
          ),
        ),
        SliverToBoxAdapter(
          child: ChapterFilterBar(
            chapters: chapters,
            totalCount: difficultDrugs.length,
            selectedChapter: activeChapter,
            subcategories: subcategories,
            selectedSubcategory: activeSubcategory,
            orderMode: widget.orderMode,
            examRotationEnabled: widget.examRotationEnabled,
            onToggleExamRotation: widget.onToggleExamRotation,
            showProgressInSheet: false,
            onChapterChanged: (chapter) {
              setState(() {
                _selectedChapter = chapter;
                _selectedSubcategory = null;
              });
            },
            onSubcategoryChanged: (sub) {
              setState(() => _selectedSubcategory = sub);
            },
            onOrderModeChanged: widget.onOrderModeChanged,
            onReshuffle: widget.onReshuffle,
          ),
        ),
        _buildMistakeList(displayed),
      ],
    );
  }

  Widget _buildMistakeList(List<Drug> displayed) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
      sliver: SliverList.separated(
        itemCount: displayed.length,
        itemBuilder: (context, index) {
          final drug = displayed[index];
          return DrugCard(
            drug: drug,
            totalCount: widget.drugs.length,
            positionInScope: index + 1,
            scopeCount: displayed.length,
            rotationAngle: widget.examRotationEnabled
                ? (widget.rotationAngles[drug.id] ?? 0)
                : 0,
            isRevealed: _revealedIds.contains(drug.id),
            isLastFocused: false,
            isDifficult: true,
            onToggleReveal: () => _toggleReveal(drug.id),
            onToggleDifficult: () => widget.onToggleDifficult(drug),
            revealedFooter: _buildMasteredAction(context, drug),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 14),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required int totalDifficult,
    required int displayedCount,
  }) {
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
            _buildHeaderTopRow(palette, totalDifficult),
            const SizedBox(height: 12),
            Text('错题本', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              displayedCount == totalDifficult
                  ? '盲测回忆易错药物与作用靶点，熟练后点击「已掌握」移出错题本'
                  : '当前筛选出 $displayedCount 种难点药物',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTopRow(AppPalette palette, int totalDifficult) {
    final themeIcon = switch (widget.themePreference) {
      AppThemePreference.dark => Icons.dark_mode_rounded,
      AppThemePreference.light => Icons.light_mode_rounded,
      AppThemePreference.system => Icons.brightness_auto_rounded,
    };
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: palette.amberSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.amberBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: palette.amber),
              const SizedBox(width: 4),
              Text(
                '错题攻坚 · 待攻克 $totalDifficult 种',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.amber,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Tooltip(
          message: '切换护眼主题',
          child: Material(
            color: palette.badgeSurface,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onOpenThemeSheet,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Icon(themeIcon, size: 16, color: palette.primaryDeep),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        TextButton.icon(
          onPressed: () => _confirmClearAll(totalDifficult),
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text(
            '清空',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildMasteredAction(BuildContext context, Drug drug) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.successSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          _revealedIds.remove(drug.id);
          widget.onMarkMastered(drug);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.successBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: palette.success,
              ),
              const SizedBox(width: 6),
              Text(
                '已掌握，移出错题本',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.amberSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_outline_rounded,
                  size: 28,
                  color: palette.amber,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '错题本暂无难点药物',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '在「复习」或「查结构」页面点击卡片右上角的「标难」星标，即可自动收集到这里集中攻克。',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.onGoToReview,
                icon: const Icon(Icons.style_rounded, size: 18),
                label: const Text('去复习结构式'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

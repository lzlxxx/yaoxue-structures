import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/review_progress_store.dart';
import '../data/study_preferences_store.dart';
import '../theme/app_theme.dart';
import 'widgets/chapter_filter_bar.dart';
import 'widgets/drug_card.dart';
import 'widgets/review_header.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.drugs,
    required this.initialProgress,
    required this.selectedChapter,
    required this.orderMode,
    required this.shuffledIds,
    required this.difficultIds,
    required this.excludedIds,
    required this.examRotationEnabled,
    required this.rotationAngles,
    required this.themePreference,
    required this.onChapterChanged,
    required this.onOrderModeChanged,
    required this.onReshuffle,
    required this.onToggleExamRotation,
    required this.onToggleDifficult,
    required this.onExcludeDrug,
    required this.onOpenExcludedPage,
    required this.onOpenThemeSheet,
    required this.onSaveProgress,
    required this.onClearProgress,
    this.onSessionDrugRevealed,
  });

  final List<Drug> drugs;
  final ReviewProgressSnapshot initialProgress;
  final String? selectedChapter;
  final StudyOrderMode orderMode;
  final List<String> shuffledIds;
  final Set<String> difficultIds;
  final Set<String> excludedIds;
  final bool examRotationEnabled;
  final Map<String, int> rotationAngles;
  final AppThemePreference themePreference;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<StudyOrderMode> onOrderModeChanged;
  final VoidCallback onReshuffle;
  final VoidCallback onToggleExamRotation;
  final ValueChanged<Drug> onToggleDifficult;
  final ValueChanged<Drug> onExcludeDrug;
  final VoidCallback onOpenExcludedPage;
  final VoidCallback onOpenThemeSheet;
  final Future<void> Function(ReviewProgressSnapshot snapshot) onSaveProgress;
  final Future<void> Function() onClearProgress;
  final VoidCallback? onSessionDrugRevealed;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  final _scrollViewKey = GlobalKey();
  late final Map<String, GlobalKey> _cardKeys;
  late Set<String> _revealedIds;
  String? _selectedSubcategory;
  String? _lastDrugId;
  double _savedScrollOffset = 0;
  bool _showBackToTop = false;
  Timer? _scrollSaveTimer;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cardKeys = {for (final drug in widget.drugs) drug.id: GlobalKey()};
    _revealedIds = Set<String>.from(widget.initialProgress.revealedIds);
    _lastDrugId = widget.initialProgress.lastDrugId;
    _savedScrollOffset = widget.initialProgress.lastScrollOffset;
    _scrollController = ScrollController(
      initialScrollOffset: _savedScrollOffset,
    )..addListener(_handleScroll);

    if (_savedScrollOffset > 0 || _lastDrugId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollSaveTimer?.cancel();
    if (!_resetting && _scrollController.hasClients) {
      _saveCurrentPosition(updateHeader: false);
    }
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_resetting) {
      _scrollSaveTimer?.cancel();
      _scrollSaveTimer = null;
      _saveCurrentPosition();
    }
  }

  @override
  void didUpdateWidget(covariant ReviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChapter != widget.selectedChapter) {
      _selectedSubcategory = null;
    }
  }

  List<Drug> _visibleDrugs() {
    return DrugCatalogHelper.selectDrugs(
      widget.drugs,
      chapter: widget.selectedChapter,
      subcategory: _selectedSubcategory,
      excludedIds: widget.excludedIds,
      orderMode: widget.orderMode,
      shuffledIds: widget.shuffledIds,
    );
  }

  void _restorePosition() {
    if (!mounted || !_scrollController.hasClients || _savedScrollOffset <= 0) {
      return;
    }
    final clamped = _savedScrollOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(clamped);
    setState(() => _showBackToTop = clamped > 360);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final shouldShowTop = offset > 360;
    if (shouldShowTop != _showBackToTop) {
      setState(() => _showBackToTop = shouldShowTop);
    }

    if (_resetting) return;
    _savedScrollOffset = offset.clamp(0.0, double.infinity);
    _scrollSaveTimer ??= Timer(const Duration(milliseconds: 350), () {
      _scrollSaveTimer = null;
      if (mounted) _saveCurrentPosition();
    });
  }

  String? _visibleDrugId(List<Drug> displayedDrugs) {
    final viewport = _scrollViewKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return null;
    final top = viewport.localToGlobal(Offset.zero).dy;
    for (final drug in displayedDrugs) {
      final box = _cardKeys[drug.id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > top && y < top + viewport.size.height) {
        return drug.id;
      }
    }
    return null;
  }

  void _saveCurrentPosition({bool updateHeader = true}) {
    if (!_scrollController.hasClients) return;
    _savedScrollOffset = _scrollController.offset.clamp(0.0, double.infinity);
    if (_revealedIds.isEmpty &&
        _lastDrugId == null &&
        _savedScrollOffset == 0) {
      return;
    }
    final visibleId = _visibleDrugId(_visibleDrugs());
    if (visibleId != null && visibleId != _lastDrugId) {
      if (mounted && updateHeader) {
        setState(() => _lastDrugId = visibleId);
      } else {
        _lastDrugId = visibleId;
      }
    }
    _persistProgress();
  }

  void _toggleReveal(Drug drug) {
    var newlyRevealed = false;
    setState(() {
      if (_revealedIds.add(drug.id)) {
        newlyRevealed = true;
      } else {
        _revealedIds.remove(drug.id);
      }
      _lastDrugId = drug.id;
      if (_scrollController.hasClients) {
        _savedScrollOffset = _scrollController.offset.clamp(
          0.0,
          double.infinity,
        );
      }
    });
    if (newlyRevealed) {
      widget.onSessionDrugRevealed?.call();
    }
    _persistProgress();
  }

  void _persistProgress() {
    final snapshot = ReviewProgressSnapshot(
      revealedIds: Set<String>.unmodifiable(_revealedIds),
      lastDrugId: _lastDrugId,
      lastScrollOffset: _savedScrollOffset,
    );
    unawaited(widget.onSaveProgress(snapshot));
  }

  void _handleFilterOrOrderChange(VoidCallback action) {
    action();
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      unawaited(_scrollToTop());
    }
  }

  Future<void> _jumpToResumePosition() async {
    if (!_scrollController.hasClients) return;
    final target = _savedScrollOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ResetProgressDialog(
        revealedCount: _revealedIds.length,
        lastDrugId: _lastDrugId,
      ),
    );
    if (confirmed != true || !mounted) return;
    _resetting = true;
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = null;
    setState(() {
      _revealedIds.clear();
      _lastDrugId = null;
      _savedScrollOffset = 0;
    });
    await widget.onClearProgress();
    if (!mounted) return;
    await _scrollToTop();
    _resetting = false;
  }

  @override
  Widget build(BuildContext context) {
    final chapters = DrugCatalogHelper.buildChapterSummaries(
      widget.drugs,
      revealedIds: _revealedIds,
      difficultIds: widget.difficultIds,
      excludedIds: widget.excludedIds,
    );
    final activeChapter =
        chapters.any((item) => item.name == widget.selectedChapter)
        ? widget.selectedChapter
        : null;
    final subcategories = DrugCatalogHelper.buildSubcategorySummaries(
      widget.drugs,
      chapter: activeChapter,
      revealedIds: _revealedIds,
      difficultIds: widget.difficultIds,
      excludedIds: widget.excludedIds,
    );
    final activeSubcategory =
        subcategories.any((item) => item.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    final displayedDrugs = DrugCatalogHelper.selectDrugs(
      widget.drugs,
      chapter: activeChapter,
      subcategory: activeSubcategory,
      excludedIds: widget.excludedIds,
      orderMode: widget.orderMode,
      shuffledIds: widget.shuffledIds,
    );
    final activeTotalCount = widget.drugs.length - widget.excludedIds.length;

    return Stack(
      children: [
        CustomScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                displayedDrugs,
                activeChapter,
                activeSubcategory,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildFilterBar(
                chapters,
                activeTotalCount,
                activeChapter,
                subcategories,
                activeSubcategory,
              ),
            ),
            if (displayedDrugs.isEmpty)
              SliverToBoxAdapter(child: _buildAllExcludedCard(context))
            else
              _buildDrugSliverList(displayedDrugs, activeTotalCount),
          ],
        ),
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingBackToTopButton(onTap: _scrollToTop),
          ),
      ],
    );
  }

  Widget _buildHeader(
    List<Drug> displayedDrugs,
    String? activeChapter,
    String? activeSubcategory,
  ) {
    final total = displayedDrugs.length;
    final revealedInScope = displayedDrugs
        .where((drug) => _revealedIds.contains(drug.id))
        .length;
    final hasProgress =
        _revealedIds.isNotEmpty ||
        _lastDrugId != null ||
        _savedScrollOffset > 0;
    final scopeLabel = activeSubcategory != null
        ? '$activeSubcategory · 已核对'
        : (activeChapter == null ? '本轮已核对' : '$activeChapter · 已核对');
    return ReviewHeader(
      totalCount: total,
      revealedCount: revealedInScope,
      progress: total == 0 ? 0.0 : revealedInScope / total,
      scopeLabel: scopeLabel,
      lastDrugId: _lastDrugId,
      hasProgress: hasProgress,
      themePreference: widget.themePreference,
      onOpenThemeSheet: widget.onOpenThemeSheet,
      onJumpToLast: _lastDrugId != null || _savedScrollOffset > 0
          ? _jumpToResumePosition
          : null,
      onReset: hasProgress ? _confirmResetProgress : null,
    );
  }

  Widget _buildFilterBar(
    List<ChapterSummary> chapters,
    int activeTotalCount,
    String? activeChapter,
    List<SubcategorySummary> subcategories,
    String? activeSubcategory,
  ) {
    return ChapterFilterBar(
      chapters: chapters,
      totalCount: activeTotalCount,
      selectedChapter: activeChapter,
      subcategories: subcategories,
      selectedSubcategory: activeSubcategory,
      orderMode: widget.orderMode,
      examRotationEnabled: widget.examRotationEnabled,
      excludedCount: widget.excludedIds.length,
      onOpenExcluded: widget.onOpenExcludedPage,
      onToggleExamRotation: widget.onToggleExamRotation,
      onChapterChanged: (chapter) => _handleFilterOrOrderChange(() {
        setState(() => _selectedSubcategory = null);
        widget.onChapterChanged(chapter);
      }),
      onSubcategoryChanged: (sub) => _handleFilterOrOrderChange(() {
        setState(() => _selectedSubcategory = sub);
      }),
      onOrderModeChanged: (mode) =>
          _handleFilterOrOrderChange(() => widget.onOrderModeChanged(mode)),
      onReshuffle: () => _handleFilterOrOrderChange(widget.onReshuffle),
    );
  }

  Widget _buildDrugSliverList(List<Drug> displayedDrugs, int activeTotalCount) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
      sliver: SliverList.separated(
        itemCount: displayedDrugs.length,
        itemBuilder: (context, index) {
          final drug = displayedDrugs[index];
          return DrugCard(
            key: _cardKeys[drug.id],
            drug: drug,
            totalCount: activeTotalCount,
            positionInScope: index + 1,
            scopeCount: displayedDrugs.length,
            rotationAngle: widget.examRotationEnabled
                ? (widget.rotationAngles[drug.id] ?? 0)
                : 0,
            isRevealed: _revealedIds.contains(drug.id),
            isLastFocused: _lastDrugId == drug.id,
            isDifficult: widget.difficultIds.contains(drug.id),
            onToggleReveal: () => _toggleReveal(drug),
            onToggleDifficult: () => widget.onToggleDifficult(drug),
            onExclude: () => widget.onExcludeDrug(drug),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 14),
      ),
    );
  }

  Widget _buildAllExcludedCard(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 32,
              color: palette.primary,
            ),
            const SizedBox(height: 10),
            Text(
              '当前范围结构式已全部屏蔽',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '可进入「已屏蔽结构式」页面按需恢复任意药物继续复习',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: widget.onOpenExcludedPage,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: Text('管理已屏蔽 (${widget.excludedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }
}

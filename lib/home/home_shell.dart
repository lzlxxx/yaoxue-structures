import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/drug_repository.dart';
import '../data/quiz_engine.dart';
import '../data/review_progress_store.dart';
import '../data/study_preferences_store.dart';
import '../encouragement/encouragement_coordinator.dart';
import '../excluded/excluded_drugs_page.dart';
import '../mistakes/mistake_book_page.dart';
import '../quiz/quiz_page.dart';
import '../review/review_page.dart';
import '../search/search_page.dart';
import '../theme/theme_mode_sheet.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_error_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.preferencesStore,
    required this.themePreference,
    required this.onThemePreferenceChanged,
  });

  final StudyPreferencesStore preferencesStore;
  final AppThemePreference themePreference;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final DrugRepository _repository = const DrugRepository();
  final ReviewProgressStore _progressStore = ReviewProgressStore();
  final GlobalKey<QuizPageState> _quizPageKey = GlobalKey<QuizPageState>();

  List<Drug>? _drugs;
  ReviewProgressSnapshot _progress = ReviewProgressSnapshot.empty;
  StudyPreferencesSnapshot _prefs = StudyPreferencesSnapshot.empty;
  Map<String, int> _rotationAngles = const <String, int>{};
  int _rotationSeed = 1;
  bool _loading = true;
  bool _loadFailed = false;
  int _currentTab = 0;

  int _sessionRevealedCount = 0;
  int _sessionQuizCount = 0;
  bool _exitDialogShowing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialData());
  }

  Future<void> _loadInitialData() async {
    try {
      final drugs = await _repository.loadDrugs();
      final validDrugIds = drugs.map((drug) => drug.id).toSet();
      final validChapters = drugs
          .map((drug) => drug.chapter)
          .where((chapter) => chapter.isNotEmpty)
          .toSet();
      final progress = await _progressStore.load(validDrugIds: validDrugIds);
      final prefs = await widget.preferencesStore.load(
        validDrugIds: validDrugIds,
        validChapters: validChapters,
      );
      if (!mounted) return;
      final seed = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _drugs = drugs;
        _progress = progress;
        _prefs = prefs;
        _rotationSeed = seed;
        _rotationAngles = QuizEngine.buildRotationMap(
          drugs,
          enabled: prefs.examRotationEnabled,
          seed: seed,
        );
        _loading = false;
        _loadFailed = false;
      });
      widget.onThemePreferenceChanged(prefs.themePreference);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final updated = EncouragementCoordinator.handleAppLaunch(
          context,
          prefs: _prefs,
          revealedCount: _progress.revealedIds.length,
          totalDrugCount: drugs.length - _prefs.excludedIds.length,
          onEnableDarkMode: _enableDarkModeDirectly,
        );
        if (updated != null) _updatePrefs(updated);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _enableDarkModeDirectly() {
    widget.onThemePreferenceChanged(AppThemePreference.dark);
    _updatePrefs(_prefs.copyWith(themePreference: AppThemePreference.dark));
  }

  Future<void> _handleSystemBack() async {
    if (_currentTab == 1 && _quizPageKey.currentState?.isPlaying == true) {
      await _quizPageKey.currentState?.requestExitQuiz();
      return;
    }
    if (_exitDialogShowing || !mounted) return;
    _exitDialogShowing = true;
    final shouldExit = await EncouragementCoordinator.confirmAppExit(
      context,
      sessionRevealedCount: _sessionRevealedCount,
      sessionQuizCount: _sessionQuizCount,
    );
    _exitDialogShowing = false;
    if (shouldExit && mounted) {
      await SystemNavigator.pop();
    }
  }

  void _updatePrefs(StudyPreferencesSnapshot next) {
    setState(() => _prefs = next);
    unawaited(widget.preferencesStore.save(next));
  }

  void _refreshRotationAngles(bool enabled) {
    final drugs = _drugs;
    if (drugs == null) return;
    _rotationSeed += 1;
    _rotationAngles = QuizEngine.buildRotationMap(
      drugs,
      enabled: enabled,
      seed: _rotationSeed,
    );
  }

  void _handleToggleExamRotation() {
    final nextEnabled = !_prefs.examRotationEnabled;
    _refreshRotationAngles(nextEnabled);
    _updatePrefs(_prefs.copyWith(examRotationEnabled: nextEnabled));
    _showBriefMessage(nextEnabled ? '已开启考场四向旋转防背图' : '已还原标准 0° 出图朝向');
  }

  void _handleChapterChanged(String? chapter) {
    _updatePrefs(
      _prefs.copyWith(
        selectedChapter: chapter,
        clearSelectedChapter: chapter == null,
      ),
    );
  }

  void _handleReviewOrderChanged(StudyOrderMode mode) {
    final drugs = _drugs;
    if (drugs == null) return;
    final shuffledIds =
        mode == StudyOrderMode.shuffled && _prefs.shuffledDrugIds.isEmpty
        ? DrugCatalogHelper.createShuffledIds(drugs)
        : _prefs.shuffledDrugIds;
    _updatePrefs(
      _prefs.copyWith(reviewOrderMode: mode, shuffledDrugIds: shuffledIds),
    );
  }

  void _handleReshuffleReview() {
    final drugs = _drugs;
    if (drugs == null) return;
    if (_prefs.examRotationEnabled) _refreshRotationAngles(true);
    _updatePrefs(
      _prefs.copyWith(
        reviewOrderMode: StudyOrderMode.shuffled,
        shuffledDrugIds: DrugCatalogHelper.createShuffledIds(drugs),
      ),
    );
    _showBriefMessage('已重新打乱复习顺序');
  }

  void _handleMistakeOrderChanged(StudyOrderMode mode) {
    final drugs = _drugs;
    if (drugs == null) return;
    final difficultDrugs = drugs
        .where((drug) => _prefs.difficultIds.contains(drug.id))
        .toList(growable: false);
    final shuffledIds =
        mode == StudyOrderMode.shuffled && _prefs.shuffledMistakeIds.isEmpty
        ? DrugCatalogHelper.createShuffledIds(difficultDrugs)
        : _prefs.shuffledMistakeIds;
    _updatePrefs(
      _prefs.copyWith(mistakeOrderMode: mode, shuffledMistakeIds: shuffledIds),
    );
  }

  void _handleReshuffleMistakes() {
    final drugs = _drugs;
    if (drugs == null) return;
    if (_prefs.examRotationEnabled) _refreshRotationAngles(true);
    final difficultDrugs = drugs
        .where((drug) => _prefs.difficultIds.contains(drug.id))
        .toList(growable: false);
    _updatePrefs(
      _prefs.copyWith(
        mistakeOrderMode: StudyOrderMode.shuffled,
        shuffledMistakeIds: DrugCatalogHelper.createShuffledIds(difficultDrugs),
      ),
    );
    _showBriefMessage('已重新打乱错题顺序');
  }

  void _handleExcludeDrug(Drug drug) {
    if (_prefs.excludedIds.contains(drug.id)) return;
    final nextExcluded = Set<String>.from(_prefs.excludedIds)..add(drug.id);
    _updatePrefs(
      _prefs.copyWith(excludedIds: Set<String>.unmodifiable(nextExcluded)),
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已屏蔽「${drug.name}」，复习与测验将自动跳过'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => _handleRestoreExcluded(drug),
        ),
      ),
    );
  }

  void _handleToggleExclude(Drug drug) {
    if (_prefs.excludedIds.contains(drug.id)) {
      _handleRestoreExcluded(drug);
      _showBriefMessage('已恢复「${drug.name}」参与复习与测验');
    } else {
      _handleExcludeDrug(drug);
    }
  }

  void _handleRestoreExcluded(Drug drug) {
    if (!_prefs.excludedIds.contains(drug.id)) return;
    final nextExcluded = Set<String>.from(_prefs.excludedIds)..remove(drug.id);
    _updatePrefs(
      _prefs.copyWith(excludedIds: Set<String>.unmodifiable(nextExcluded)),
    );
  }

  void _handleReExcludeSilent(Drug drug) {
    final nextExcluded = Set<String>.from(_prefs.excludedIds)..add(drug.id);
    _updatePrefs(
      _prefs.copyWith(excludedIds: Set<String>.unmodifiable(nextExcluded)),
    );
  }

  void _handleRestoreAllExcluded() {
    _updatePrefs(_prefs.copyWith(excludedIds: const <String>{}));
    _showBriefMessage('已恢复全部屏蔽结构式');
  }

  Future<void> _openExcludedPage() async {
    final drugs = _drugs;
    if (drugs == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExcludedDrugsPage(
          allDrugs: drugs,
          initialExcludedIds: _prefs.excludedIds,
          onRestoreDrug: _handleRestoreExcluded,
          onReExcludeDrug: _handleReExcludeSilent,
          onRestoreAll: _handleRestoreAllExcluded,
        ),
      ),
    );
  }

  void _handleToggleDifficult(Drug drug) {
    final nextDifficult = Set<String>.from(_prefs.difficultIds);
    final added = nextDifficult.add(drug.id);
    if (!added) nextDifficult.remove(drug.id);
    _updatePrefs(
      _prefs.copyWith(difficultIds: Set<String>.unmodifiable(nextDifficult)),
    );
    _showBriefMessage(added ? '已标记为难点并加入错题本' : '已取消难点标记');
  }

  void _handleAutoAddDifficult(Drug drug) {
    if (_prefs.difficultIds.contains(drug.id)) return;
    final nextDifficult = Set<String>.from(_prefs.difficultIds)..add(drug.id);
    _updatePrefs(
      _prefs.copyWith(difficultIds: Set<String>.unmodifiable(nextDifficult)),
    );
  }

  void _handleBatchRemoveDifficult(Set<String> masteredIds) {
    final nextDifficult = Set<String>.from(_prefs.difficultIds)
      ..removeAll(masteredIds);
    _updatePrefs(
      _prefs.copyWith(difficultIds: Set<String>.unmodifiable(nextDifficult)),
    );
    _showBriefMessage('已将 ${masteredIds.length} 种掌握药物移出错题本');
  }

  void _handleQuizCompleted(int correct, int total, int durationSeconds) {
    _sessionQuizCount += 1;
    _updatePrefs(
      _prefs.copyWith(
        lastQuizCorrect: correct,
        lastQuizTotal: total,
        lastQuizDurationSeconds: durationSeconds,
      ),
    );
  }

  void _handleMarkMastered(Drug drug) {
    final nextDifficult = Set<String>.from(_prefs.difficultIds)
      ..remove(drug.id);
    _updatePrefs(
      _prefs.copyWith(difficultIds: Set<String>.unmodifiable(nextDifficult)),
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已将「${drug.name}」移出错题本'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            final restored = Set<String>.from(_prefs.difficultIds)
              ..add(drug.id);
            _updatePrefs(
              _prefs.copyWith(difficultIds: Set<String>.unmodifiable(restored)),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleClearAllDifficult() async {
    _updatePrefs(
      _prefs.copyWith(
        difficultIds: const <String>{},
        shuffledMistakeIds: const <String>[],
      ),
    );
    _showBriefMessage('已清空错题本');
  }

  Future<void> _openThemeSheet() async {
    await ThemeModeSheet.show(
      context,
      currentMode: widget.themePreference,
      onSelected: (preference) {
        widget.onThemePreferenceChanged(preference);
        _updatePrefs(_prefs.copyWith(themePreference: preference));
      },
    );
  }

  void _showBriefMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMistakeCount = _prefs.difficultIds
        .difference(_prefs.excludedIds)
        .length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
        body: SafeArea(bottom: false, child: _buildBody(context)),
        bottomNavigationBar: HomeBottomNavBar(
          selectedIndex: _currentTab,
          mistakeCount: activeMistakeCount,
          onSelected: (index) {
            if (index == _currentTab) return;
            setState(() => _currentTab = index);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final drugs = _drugs;
    if (_loadFailed || drugs == null) {
      return const HomeErrorView();
    }

    return IndexedStack(
      index: _currentTab,
      children: [
        _buildReviewTab(drugs),
        _buildQuizTab(drugs),
        MistakeBookPage(
          drugs: drugs,
          difficultIds: _prefs.difficultIds,
          excludedIds: _prefs.excludedIds,
          orderMode: _prefs.mistakeOrderMode,
          shuffledIds: _prefs.shuffledMistakeIds,
          examRotationEnabled: _prefs.examRotationEnabled,
          rotationAngles: _rotationAngles,
          themePreference: widget.themePreference,
          onOrderModeChanged: _handleMistakeOrderChanged,
          onReshuffle: _handleReshuffleMistakes,
          onToggleExamRotation: _handleToggleExamRotation,
          onToggleDifficult: _handleToggleDifficult,
          onMarkMastered: _handleMarkMastered,
          onClearAllDifficult: _handleClearAllDifficult,
          onOpenThemeSheet: _openThemeSheet,
          onGoToReview: () => setState(() => _currentTab = 0),
        ),
        SearchPage(
          drugs: drugs,
          difficultIds: _prefs.difficultIds,
          excludedIds: _prefs.excludedIds,
          themePreference: widget.themePreference,
          onToggleDifficult: _handleToggleDifficult,
          onToggleExclude: _handleToggleExclude,
          onOpenThemeSheet: _openThemeSheet,
        ),
      ],
    );
  }

  Widget _buildReviewTab(List<Drug> drugs) {
    return ReviewPage(
      drugs: drugs,
      initialProgress: _progress,
      selectedChapter: _prefs.selectedChapter,
      orderMode: _prefs.reviewOrderMode,
      shuffledIds: _prefs.shuffledDrugIds,
      difficultIds: _prefs.difficultIds,
      excludedIds: _prefs.excludedIds,
      examRotationEnabled: _prefs.examRotationEnabled,
      rotationAngles: _rotationAngles,
      themePreference: widget.themePreference,
      onChapterChanged: _handleChapterChanged,
      onOrderModeChanged: _handleReviewOrderChanged,
      onReshuffle: _handleReshuffleReview,
      onToggleExamRotation: _handleToggleExamRotation,
      onToggleDifficult: _handleToggleDifficult,
      onExcludeDrug: _handleExcludeDrug,
      onOpenExcludedPage: _openExcludedPage,
      onOpenThemeSheet: _openThemeSheet,
      onSessionDrugRevealed: () => _sessionRevealedCount += 1,
      onSaveProgress: _progressStore.save,
      onClearProgress: _progressStore.clear,
    );
  }

  Widget _buildQuizTab(List<Drug> drugs) {
    return QuizPage(
      key: _quizPageKey,
      drugs: drugs,
      difficultIds: _prefs.difficultIds,
      excludedIds: _prefs.excludedIds,
      examRotationEnabled: _prefs.examRotationEnabled,
      themePreference: widget.themePreference,
      lastQuizCorrect: _prefs.lastQuizCorrect,
      lastQuizTotal: _prefs.lastQuizTotal,
      lastQuizDurationSeconds: _prefs.lastQuizDurationSeconds,
      onToggleExamRotation: _handleToggleExamRotation,
      onOpenExcludedPage: _openExcludedPage,
      onOpenThemeSheet: _openThemeSheet,
      onAutoAddDifficult: _handleAutoAddDifficult,
      onBatchRemoveDifficult: _handleBatchRemoveDifficult,
      onQuizCompleted: _handleQuizCompleted,
    );
  }
}

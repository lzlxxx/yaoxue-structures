import 'package:material_ui/material_ui.dart';

import '../data/drug.dart';
import '../data/drug_catalog_helper.dart';
import '../data/quiz_engine.dart';
import '../data/study_preferences_store.dart';
import 'widgets/quiz_play_view.dart';
import 'widgets/quiz_result_view.dart';
import 'widgets/quiz_setup_view.dart';

enum _QuizPhase { setup, playing, result }

/// 测验标签页主控制器：协调配置态、沉浸答题态与交卷复盘态，自动剔除已屏蔽药物。
class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.drugs,
    required this.difficultIds,
    required this.excludedIds,
    required this.examRotationEnabled,
    required this.themePreference,
    required this.lastQuizCorrect,
    required this.lastQuizTotal,
    required this.lastQuizDurationSeconds,
    required this.onToggleExamRotation,
    required this.onOpenExcludedPage,
    required this.onOpenThemeSheet,
    required this.onAutoAddDifficult,
    required this.onBatchRemoveDifficult,
    required this.onQuizCompleted,
  });

  final List<Drug> drugs;
  final Set<String> difficultIds;
  final Set<String> excludedIds;
  final bool examRotationEnabled;
  final AppThemePreference themePreference;
  final int? lastQuizCorrect;
  final int? lastQuizTotal;
  final int? lastQuizDurationSeconds;
  final VoidCallback onToggleExamRotation;
  final VoidCallback onOpenExcludedPage;
  final VoidCallback onOpenThemeSheet;
  final ValueChanged<Drug> onAutoAddDifficult;
  final ValueChanged<Set<String>> onBatchRemoveDifficult;
  final void Function(int correct, int total, int durationSeconds)
  onQuizCompleted;

  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  _QuizPhase _phase = _QuizPhase.setup;

  /// 当前是否正处于沉浸测验答题阶段，供外壳处理系统返回键。
  bool get isPlaying => _phase == _QuizPhase.playing;

  /// 外部响应返回键时触发与「退出」按钮一致的二次确认。
  Future<void> requestExitQuiz() => _confirmExit();
  QuizQuestionType _questionType = QuizQuestionType.structureToName;
  QuizScope _scope = QuizScope.all;
  String? _selectedChapter;
  String? _selectedSubcategory;
  int _desiredCount = 20;

  List<QuizQuestion> _questions = const <QuizQuestion>[];
  List<QuizAnswerRecord> _records = const <QuizAnswerRecord>[];
  int _currentIndex = 0;
  String? _selectedDrugId;
  DateTime? _startedAt;
  int _elapsedSeconds = 0;
  bool _sessionIsMistakes = false;
  bool _masteredBatchApplied = false;

  List<Drug> _resolvePool(List<ChapterSummary> chapters) {
    return switch (_scope) {
      QuizScope.all => DrugCatalogHelper.filterActiveDrugs(
        widget.drugs,
        widget.excludedIds,
      ),
      QuizScope.mistakes =>
        widget.drugs
            .where(
              (drug) =>
                  widget.difficultIds.contains(drug.id) &&
                  !widget.excludedIds.contains(drug.id),
            )
            .toList(growable: false),
      QuizScope.chapter => _resolveChapterPool(chapters),
    };
  }

  List<Drug> _resolveChapterPool(List<ChapterSummary> chapters) {
    final activeChapter = _selectedChapter ?? chapters.firstOrNull?.name;
    if (activeChapter == null) return const <Drug>[];
    final validSubs = DrugCatalogHelper.buildSubcategorySummaries(
      widget.drugs,
      chapter: activeChapter,
      excludedIds: widget.excludedIds,
    );
    final activeSub = validSubs.any((item) => item.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    return DrugCatalogHelper.selectDrugs(
      widget.drugs,
      chapter: activeChapter,
      subcategory: activeSub,
      excludedIds: widget.excludedIds,
    );
  }

  void _startQuiz({List<Drug>? customPool, bool? isMistakeSession}) {
    final chapters = DrugCatalogHelper.buildChapterSummaries(
      widget.drugs,
      excludedIds: widget.excludedIds,
    );
    final pool = customPool ?? _resolvePool(chapters);
    final generated = QuizEngine.generateQuestions(
      allDrugs: widget.drugs,
      candidatePool: pool,
      desiredCount: customPool != null ? customPool.length : _desiredCount,
      questionType: _questionType,
      examRotationEnabled: widget.examRotationEnabled,
      excludedIds: widget.excludedIds,
    );
    if (generated.isEmpty) return;

    setState(() {
      _questions = generated;
      _records = <QuizAnswerRecord>[];
      _currentIndex = 0;
      _selectedDrugId = null;
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _sessionIsMistakes = isMistakeSession ?? (_scope == QuizScope.mistakes);
      _masteredBatchApplied = false;
      _phase = _QuizPhase.playing;
    });
  }

  void _handleSelectOption(Drug option) {
    if (_selectedDrugId != null) return;
    final question = _questions[_currentIndex];
    final isCorrect = option.id == question.target.id;
    if (!isCorrect) {
      widget.onAutoAddDifficult(question.target);
    }
    setState(() {
      _selectedDrugId = option.id;
      _records = <QuizAnswerRecord>[
        ..._records,
        QuizAnswerRecord(question: question, selectedDrugId: option.id),
      ];
    });
  }

  void _handleNext() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex += 1;
        _selectedDrugId = null;
      });
      return;
    }
    final elapsed = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final correctCount = _records.where((record) => record.isCorrect).length;
    setState(() {
      _elapsedSeconds = elapsed < 1 ? 1 : elapsed;
      _phase = _QuizPhase.result;
    });
    widget.onQuizCompleted(correctCount, _records.length, _elapsedSeconds);
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退出当前测验'),
        content: const Text('退出后本轮未完成的答题将不计入成绩（已答错药物仍会保留在错题本中）。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续答题'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
    if (shouldExit != true || !mounted) return;
    setState(() => _phase = _QuizPhase.setup);
  }

  void _handleRemoveCorrectFromMistakes() {
    final masteredIds = _records
        .where((record) => record.isCorrect)
        .map((record) => record.question.target.id)
        .toSet();
    if (masteredIds.isEmpty) return;
    widget.onBatchRemoveDifficult(masteredIds);
    setState(() => _masteredBatchApplied = true);
  }

  void _handleRetryWrongOnly() {
    final wrongDrugs = _records
        .where((record) => !record.isCorrect)
        .map((record) => record.question.target)
        .toList(growable: false);
    if (wrongDrugs.isEmpty) return;
    _startQuiz(customPool: wrongDrugs, isMistakeSession: true);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _QuizPhase.setup => _buildSetupPhase(),
      _QuizPhase.playing => QuizPlayView(
        question: _questions[_currentIndex],
        currentIndex: _currentIndex,
        totalCount: _questions.length,
        correctCount: _records.where((record) => record.isCorrect).length,
        selectedDrugId: _selectedDrugId,
        onSelectOption: _handleSelectOption,
        onNext: _handleNext,
        onExit: _confirmExit,
      ),
      _QuizPhase.result => QuizResultView(
        records: _records,
        durationSeconds: _elapsedSeconds,
        isMistakeSession: _sessionIsMistakes,
        masteredBatchApplied: _masteredBatchApplied,
        onRemoveCorrectFromMistakes: _handleRemoveCorrectFromMistakes,
        onRetryMistakes: _handleRetryWrongOnly,
        onPlayAgain: _startQuiz,
        onBackToSetup: () => setState(() => _phase = _QuizPhase.setup),
      ),
    };
  }

  Widget _buildSetupPhase() {
    final chapters = DrugCatalogHelper.buildChapterSummaries(
      widget.drugs,
      difficultIds: widget.difficultIds,
      excludedIds: widget.excludedIds,
    );
    final activeChapter =
        chapters.any((chapter) => chapter.name == _selectedChapter)
        ? _selectedChapter
        : chapters.firstOrNull?.name;
    final subcategories = DrugCatalogHelper.buildSubcategorySummaries(
      widget.drugs,
      chapter: activeChapter,
      difficultIds: widget.difficultIds,
      excludedIds: widget.excludedIds,
    );
    final activeSubcategory =
        subcategories.any((item) => item.name == _selectedSubcategory)
        ? _selectedSubcategory
        : null;
    final activeMistakeCount = widget.difficultIds
        .difference(widget.excludedIds)
        .length;

    return QuizSetupView(
      totalDrugCount: widget.drugs.length,
      mistakeCount: activeMistakeCount,
      excludedCount: widget.excludedIds.length,
      chapters: chapters,
      subcategories: subcategories,
      questionType: _questionType,
      scope: _scope,
      selectedChapter: activeChapter,
      selectedSubcategory: activeSubcategory,
      desiredCount: _desiredCount,
      availablePoolCount: _resolvePool(chapters).length,
      examRotationEnabled: widget.examRotationEnabled,
      themePreference: widget.themePreference,
      lastQuizCorrect: widget.lastQuizCorrect,
      lastQuizTotal: widget.lastQuizTotal,
      lastQuizDurationSeconds: widget.lastQuizDurationSeconds,
      onQuestionTypeChanged: (type) => setState(() => _questionType = type),
      onScopeChanged: (scope) => setState(() {
        _scope = scope;
        if (scope == QuizScope.chapter && _selectedChapter == null) {
          _selectedChapter = chapters.firstOrNull?.name;
          _selectedSubcategory = null;
        }
      }),
      onChapterChanged: (chapter) => setState(() {
        _selectedChapter = chapter;
        _selectedSubcategory = null;
      }),
      onSubcategoryChanged: (sub) => setState(() => _selectedSubcategory = sub),
      onDesiredCountChanged: (count) => setState(() => _desiredCount = count),
      onToggleExamRotation: widget.onToggleExamRotation,
      onOpenExcluded: widget.onOpenExcludedPage,
      onOpenThemeSheet: widget.onOpenThemeSheet,
      onStartQuiz: _startQuiz,
    );
  }
}

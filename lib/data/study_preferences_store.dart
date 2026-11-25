import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用外观偏好：跟随系统、日间蓝图、深色护眼。
enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode toThemeMode() {
    return switch (this) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
  }
}

/// 复习排列方式：按题库顺序或乱序随机复习。
enum StudyOrderMode { sequential, shuffled }

/// 学习偏好、错题本、已屏蔽集合、考场旋转、测验摘要与每日鼓励打卡状态快照。
class StudyPreferencesSnapshot {
  const StudyPreferencesSnapshot({
    this.themePreference = AppThemePreference.system,
    this.difficultIds = const <String>{},
    this.excludedIds = const <String>{},
    this.selectedChapter,
    this.reviewOrderMode = StudyOrderMode.sequential,
    this.shuffledDrugIds = const <String>[],
    this.mistakeOrderMode = StudyOrderMode.sequential,
    this.shuffledMistakeIds = const <String>[],
    this.examRotationEnabled = false,
    this.lastQuizCorrect,
    this.lastQuizTotal,
    this.lastQuizDurationSeconds,
    this.lastWelcomeDate,
    this.studyDaysCount = 0,
    this.lastMessageIndex,
  });

  static const StudyPreferencesSnapshot empty = StudyPreferencesSnapshot();

  final AppThemePreference themePreference;
  final Set<String> difficultIds;
  final Set<String> excludedIds;
  final String? selectedChapter;
  final StudyOrderMode reviewOrderMode;
  final List<String> shuffledDrugIds;
  final StudyOrderMode mistakeOrderMode;
  final List<String> shuffledMistakeIds;
  final bool examRotationEnabled;
  final int? lastQuizCorrect;
  final int? lastQuizTotal;
  final int? lastQuizDurationSeconds;
  final String? lastWelcomeDate;
  final int? lastMessageIndex;
  final int studyDaysCount;

  bool get hasQuizHistory =>
      lastQuizCorrect != null && lastQuizTotal != null && lastQuizTotal! > 0;

  StudyPreferencesSnapshot copyWith({
    AppThemePreference? themePreference,
    Set<String>? difficultIds,
    Set<String>? excludedIds,
    String? selectedChapter,
    bool clearSelectedChapter = false,
    StudyOrderMode? reviewOrderMode,
    List<String>? shuffledDrugIds,
    StudyOrderMode? mistakeOrderMode,
    List<String>? shuffledMistakeIds,
    bool? examRotationEnabled,
    int? lastQuizCorrect,
    int? lastQuizTotal,
    int? lastQuizDurationSeconds,
    String? lastWelcomeDate,
    int? studyDaysCount,
    int? lastMessageIndex,
  }) {
    return StudyPreferencesSnapshot(
      themePreference: themePreference ?? this.themePreference,
      difficultIds: difficultIds ?? this.difficultIds,
      excludedIds: excludedIds ?? this.excludedIds,
      selectedChapter: clearSelectedChapter
          ? null
          : (selectedChapter ?? this.selectedChapter),
      reviewOrderMode: reviewOrderMode ?? this.reviewOrderMode,
      shuffledDrugIds: shuffledDrugIds ?? this.shuffledDrugIds,
      mistakeOrderMode: mistakeOrderMode ?? this.mistakeOrderMode,
      shuffledMistakeIds: shuffledMistakeIds ?? this.shuffledMistakeIds,
      examRotationEnabled: examRotationEnabled ?? this.examRotationEnabled,
      lastQuizCorrect: lastQuizCorrect ?? this.lastQuizCorrect,
      lastQuizTotal: lastQuizTotal ?? this.lastQuizTotal,
      lastQuizDurationSeconds:
          lastQuizDurationSeconds ?? this.lastQuizDurationSeconds,
      lastWelcomeDate: lastWelcomeDate ?? this.lastWelcomeDate,
      studyDaysCount: studyDaysCount ?? this.studyDaysCount,
      lastMessageIndex: lastMessageIndex ?? this.lastMessageIndex,
    );
  }
}

/// 沿用 study_preferences_v3 键并按字段独立解析，确保覆盖升级无损保留用户数据。
class StudyPreferencesStore {
  static const _key = 'study_preferences_v3';

  Future<void> _pending = Future<void>.value();

  Future<StudyPreferencesSnapshot> load({
    Set<String>? validDrugIds,
    Set<String>? validChapters,
  }) async {
    await _pending;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.get(_key);
    if (raw is! String) return StudyPreferencesSnapshot.empty;

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return StudyPreferencesSnapshot.empty;
    }
    if (decoded is! Map<String, dynamic>) {
      return StudyPreferencesSnapshot.empty;
    }
    final quizSummary = _readQuizSummary(decoded);
    final encouragement = _readEncouragement(decoded);
    return StudyPreferencesSnapshot(
      themePreference: _readTheme(decoded['themePreference']),
      difficultIds: _readIds(
        decoded['difficultIds'],
        validDrugIds: validDrugIds,
      ),
      excludedIds: _readIds(decoded['excludedIds'], validDrugIds: validDrugIds),
      selectedChapter: _readChapter(
        decoded['selectedChapter'],
        validChapters: validChapters,
      ),
      reviewOrderMode: _readOrder(decoded['reviewOrderMode']),
      shuffledDrugIds: _readList(
        decoded['shuffledDrugIds'],
        validDrugIds: validDrugIds,
      ),
      mistakeOrderMode: _readOrder(decoded['mistakeOrderMode']),
      shuffledMistakeIds: _readList(
        decoded['shuffledMistakeIds'],
        validDrugIds: validDrugIds,
      ),
      examRotationEnabled: decoded['examRotationEnabled'] == true,
      lastQuizCorrect: quizSummary.correct,
      lastQuizTotal: quizSummary.total,
      lastQuizDurationSeconds: quizSummary.durationSeconds,
      lastWelcomeDate: encouragement.lastDate,
      studyDaysCount: encouragement.studyDays,
      lastMessageIndex: encouragement.lastMessageIndex,
    );
  }

  Future<void> save(StudyPreferencesSnapshot snapshot) {
    final encoded = jsonEncode({
      'themePreference': snapshot.themePreference.name,
      'difficultIds': snapshot.difficultIds.toList(),
      'excludedIds': snapshot.excludedIds.toList(),
      'selectedChapter': snapshot.selectedChapter,
      'reviewOrderMode': snapshot.reviewOrderMode.name,
      'shuffledDrugIds': snapshot.shuffledDrugIds,
      'mistakeOrderMode': snapshot.mistakeOrderMode.name,
      'shuffledMistakeIds': snapshot.shuffledMistakeIds,
      'examRotationEnabled': snapshot.examRotationEnabled,
      'lastQuizCorrect': snapshot.lastQuizCorrect,
      'lastQuizTotal': snapshot.lastQuizTotal,
      'lastQuizDurationSeconds': snapshot.lastQuizDurationSeconds,
      'lastWelcomeDate': snapshot.lastWelcomeDate,
      'studyDaysCount': snapshot.studyDaysCount,
      'lastMessageIndex': snapshot.lastMessageIndex,
    });
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_key, encoded);
      if (!saved) throw StateError('学习偏好保存失败');
    });
  }

  AppThemePreference _readTheme(dynamic value) {
    return switch (value) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }

  ({int? correct, int? total, int? durationSeconds}) _readQuizSummary(
    Map<String, dynamic> decoded,
  ) {
    final correct = decoded['lastQuizCorrect'];
    final total = decoded['lastQuizTotal'];
    final duration = decoded['lastQuizDurationSeconds'];
    if (correct is! int || total is! int || total <= 0 || correct < 0) {
      return (correct: null, total: null, durationSeconds: null);
    }
    final safeCorrect = correct > total ? total : correct;
    final safeDuration = duration is int && duration >= 0 ? duration : null;
    return (correct: safeCorrect, total: total, durationSeconds: safeDuration);
  }

  ({String? lastDate, int studyDays, int? lastMessageIndex}) _readEncouragement(
    Map<String, dynamic> decoded,
  ) {
    final rawDate = decoded['lastWelcomeDate'];
    final rawDays = decoded['studyDaysCount'];
    final rawIndex = decoded['lastMessageIndex'];
    final validDate =
        rawDate is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)
        ? rawDate
        : null;
    final safeDays = rawDays is int && rawDays >= 0 ? rawDays : 0;
    final safeIndex = rawIndex is int && rawIndex >= 0 ? rawIndex : null;
    return (
      lastDate: validDate,
      studyDays: safeDays,
      lastMessageIndex: safeIndex,
    );
  }

  StudyOrderMode _readOrder(dynamic value) {
    return value == 'shuffled'
        ? StudyOrderMode.shuffled
        : StudyOrderMode.sequential;
  }

  Set<String> _readIds(dynamic value, {Set<String>? validDrugIds}) {
    return Set<String>.unmodifiable(
      _readList(value, validDrugIds: validDrugIds),
    );
  }

  List<String> _readList(dynamic value, {Set<String>? validDrugIds}) {
    if (value is! List) return const <String>[];
    final result = <String>[];
    final seen = <String>{};
    for (final entry in value) {
      if (entry is! String || entry.isEmpty || !seen.add(entry)) continue;
      if (validDrugIds != null && !validDrugIds.contains(entry)) continue;
      result.add(entry);
    }
    return List<String>.unmodifiable(result);
  }

  String? _readChapter(dynamic value, {Set<String>? validChapters}) {
    if (value is! String || value.isEmpty) return null;
    if (validChapters != null && !validChapters.contains(value)) return null;
    return value;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.catchError((Object error) {});
    return result;
  }
}

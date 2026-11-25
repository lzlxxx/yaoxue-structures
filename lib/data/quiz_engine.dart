import 'dart:math';

import 'drug.dart';

/// 测验题型：看结构选药名、看药名选结构、混合交替。
enum QuizQuestionType { structureToName, nameToStructure, mixed }

/// 测验出题范围：全库、指定章节、仅错题本。
enum QuizScope { all, chapter, mistakes }

/// 单道四选一测验题目。
class QuizQuestion {
  const QuizQuestion({
    required this.target,
    required this.options,
    required this.isNameToStructure,
    required this.optionAngles,
  });

  final Drug target;
  final List<Drug> options;
  final bool isNameToStructure;
  final Map<String, int> optionAngles;

  int angleFor(String drugId) => optionAngles[drugId] ?? 0;
}

/// 单道题作答记录，用于交卷复盘与错题重练。
class QuizAnswerRecord {
  const QuizAnswerRecord({
    required this.question,
    required this.selectedDrugId,
  });

  final QuizQuestion question;
  final String selectedDrugId;

  bool get isCorrect => selectedDrugId == question.target.id;
}

/// 互动四选一测验出题引擎与考场旋转角度分配器。
abstract final class QuizEngine {
  static const int optionCount = 4;

  /// 为每项药物生成稳定的四向考场旋转角度映射（0 / 90 / 180 / 270）。
  static Map<String, int> buildRotationMap(
    List<Drug> drugs, {
    required bool enabled,
    int seed = 0,
  }) {
    if (!enabled) return const <String, int>{};
    final random = Random(seed);
    return Map<String, int>.unmodifiable({
      for (final drug in drugs)
        drug.id: Drug.examRotationAngles[random.nextInt(4)],
    });
  }

  /// 从候选范围生成四选一题目列表，自动剔除已屏蔽药物，干扰项优先取未屏蔽的同小类与同大类药物。
  static List<QuizQuestion> generateQuestions({
    required List<Drug> allDrugs,
    required List<Drug> candidatePool,
    required int desiredCount,
    required QuizQuestionType questionType,
    required bool examRotationEnabled,
    Set<String> excludedIds = const <String>{},
    Random? random,
  }) {
    final activeCandidates = excludedIds.isEmpty
        ? candidatePool
        : candidatePool
              .where((drug) => !excludedIds.contains(drug.id))
              .toList(growable: false);
    if (allDrugs.length < optionCount || activeCandidates.isEmpty) {
      return const <QuizQuestion>[];
    }
    final activeAll = excludedIds.isEmpty
        ? allDrugs
        : allDrugs
              .where((drug) => !excludedIds.contains(drug.id))
              .toList(growable: false);
    final rng = random ?? Random();
    final shuffledTargets = List<Drug>.of(activeCandidates)..shuffle(rng);
    final limit = desiredCount <= 0
        ? shuffledTargets.length
        : min(desiredCount, shuffledTargets.length);

    final questions = <QuizQuestion>[];
    for (var i = 0; i < limit; i++) {
      final target = shuffledTargets[i];
      final distractors = _pickDistractors(
        target,
        activeAll: activeAll,
        fallbackAll: allDrugs,
        rng: rng,
      );
      final options = <Drug>[target, ...distractors]..shuffle(rng);
      final isNameToStructure = switch (questionType) {
        QuizQuestionType.structureToName => false,
        QuizQuestionType.nameToStructure => true,
        QuizQuestionType.mixed => i.isOdd,
      };
      final angles = <String, int>{
        for (final option in options)
          option.id: examRotationEnabled
              ? Drug.examRotationAngles[rng.nextInt(4)]
              : 0,
      };
      questions.add(
        QuizQuestion(
          target: target,
          options: List<Drug>.unmodifiable(options),
          isNameToStructure: isNameToStructure,
          optionAngles: Map<String, int>.unmodifiable(angles),
        ),
      );
    }
    return List<QuizQuestion>.unmodifiable(questions);
  }

  static List<Drug> _pickDistractors(
    Drug target, {
    required List<Drug> activeAll,
    required List<Drug> fallbackAll,
    required Random rng,
  }) {
    final chosen = <Drug>[];
    final chosenIds = <String>{target.id};

    void takeFrom(Iterable<Drug> pool) {
      if (chosen.length >= optionCount - 1) return;
      final candidates =
          pool.where((drug) => !chosenIds.contains(drug.id)).toList()
            ..shuffle(rng);
      for (final drug in candidates) {
        if (chosen.length >= optionCount - 1) break;
        chosen.add(drug);
        chosenIds.add(drug.id);
      }
    }

    // 优先抽取未屏蔽的同二级小类、同大类与全库药物作为干扰项；仅当全库未屏蔽不足 4 项时兜底补齐。
    if (target.subcategory.isNotEmpty) {
      takeFrom(
        activeAll.where(
          (drug) =>
              drug.chapter == target.chapter &&
              drug.subcategory == target.subcategory,
        ),
      );
    }
    if (target.chapter.isNotEmpty) {
      takeFrom(activeAll.where((drug) => drug.chapter == target.chapter));
    }
    takeFrom(activeAll);
    takeFrom(fallbackAll);
    return chosen;
  }
}

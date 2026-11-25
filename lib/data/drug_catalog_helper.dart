import 'dart:math';

import 'drug.dart';
import 'study_preferences_store.dart';

/// 单个药理大类的统计摘要，用于大类筛选栏与总览弹窗展示。
class ChapterSummary {
  const ChapterSummary({
    required this.name,
    required this.totalCount,
    required this.revealedCount,
    required this.difficultCount,
    this.subcategoryCount = 0,
  });

  final String name;
  final int totalCount;
  final int revealedCount;
  final int difficultCount;
  final int subcategoryCount;
}

/// 单个二级小类的统计摘要，用于选中大类后进一步精细筛选。
class SubcategorySummary {
  const SubcategorySummary({
    required this.name,
    required this.totalCount,
    required this.revealedCount,
    required this.difficultCount,
  });

  final String name;
  final int totalCount;
  final int revealedCount;
  final int difficultCount;
}

/// 24 大类与二级小类筛选、屏蔽剔除、统计及连续教材顺序/乱序队列构建工具。
abstract final class DrugCatalogHelper {
  static const standardChapters = <String>[
    '镇静催眠药与抗癫痫药',
    '抗精神病药',
    '抗抑郁药',
    '镇痛药',
    '神经退行性疾病、麻醉与中枢兴奋药',
    '拟胆碱、抗胆碱与拟肾上腺素药',
    '抗过敏药',
    '抗高血压药',
    '利尿药',
    '抗心律失常与抗心绞痛药',
    '调血脂药',
    '抗凝血与抗血小板药',
    '消化系统药物',
    '解热镇痛、非甾体抗炎及抗痛风药',
    '抗肿瘤药',
    '抗生素',
    '合成抗菌药',
    '抗结核药',
    '抗真菌药',
    '抗病毒药',
    '抗寄生虫药',
    '降血糖药',
    '甾体激素类药物',
    '维生素',
  ];

  /// 教材分类顺序比较器：优先按 sortOrder 保证同大类、同小类严格连续。
  static int compareByStudyOrder(Drug a, Drug b) {
    final orderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (orderCompare != 0) return orderCompare;
    return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
  }

  /// 返回剔除已屏蔽条目后的可用药物列表。
  static List<Drug> filterActiveDrugs(
    List<Drug> drugs,
    Set<String> excludedIds,
  ) {
    if (excludedIds.isEmpty) return drugs;
    return drugs
        .where((drug) => !excludedIds.contains(drug.id))
        .toList(growable: false);
  }

  static List<ChapterSummary> buildChapterSummaries(
    List<Drug> drugs, {
    Set<String> revealedIds = const <String>{},
    Set<String> difficultIds = const <String>{},
    Set<String> excludedIds = const <String>{},
  }) {
    final counts =
        <
          String,
          ({int total, int revealed, int difficult, Set<String> subs})
        >{};
    for (final drug in drugs) {
      if (excludedIds.contains(drug.id)) continue;
      final key = drug.chapter;
      if (key.isEmpty) continue;
      final prev =
          counts[key] ??
          (total: 0, revealed: 0, difficult: 0, subs: <String>{});
      if (drug.subcategory.isNotEmpty) prev.subs.add(drug.subcategory);
      counts[key] = (
        total: prev.total + 1,
        revealed: prev.revealed + (revealedIds.contains(drug.id) ? 1 : 0),
        difficult: prev.difficult + (difficultIds.contains(drug.id) ? 1 : 0),
        subs: prev.subs,
      );
    }
    final orderedNames = <String>[
      ...standardChapters.where(counts.containsKey),
      ...counts.keys.where((name) => !standardChapters.contains(name)),
    ];
    return orderedNames
        .map((name) {
          final value = counts[name]!;
          return ChapterSummary(
            name: name,
            totalCount: value.total,
            revealedCount: value.revealed,
            difficultCount: value.difficult,
            subcategoryCount: value.subs.length,
          );
        })
        .toList(growable: false);
  }

  /// 构建指定大类下的二级小类统计，按组内最小 sortOrder 严格保持教材连贯顺序。
  static List<SubcategorySummary> buildSubcategorySummaries(
    List<Drug> drugs, {
    required String? chapter,
    Set<String> revealedIds = const <String>{},
    Set<String> difficultIds = const <String>{},
    Set<String> excludedIds = const <String>{},
  }) {
    if (chapter == null || chapter.isEmpty) {
      return const <SubcategorySummary>[];
    }
    final groups =
        <String, ({int total, int revealed, int difficult, int minOrder})>{};
    for (final drug in drugs) {
      if (excludedIds.contains(drug.id)) continue;
      if (drug.chapter != chapter || drug.subcategory.isEmpty) continue;
      final key = drug.subcategory;
      final prev = groups[key];
      if (prev == null) {
        groups[key] = (
          total: 1,
          revealed: revealedIds.contains(drug.id) ? 1 : 0,
          difficult: difficultIds.contains(drug.id) ? 1 : 0,
          minOrder: drug.sortOrder,
        );
      } else {
        groups[key] = (
          total: prev.total + 1,
          revealed: prev.revealed + (revealedIds.contains(drug.id) ? 1 : 0),
          difficult: prev.difficult + (difficultIds.contains(drug.id) ? 1 : 0),
          minOrder: min(prev.minOrder, drug.sortOrder),
        );
      }
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => a.value.minOrder.compareTo(b.value.minOrder));
    return entries
        .map(
          (entry) => SubcategorySummary(
            name: entry.key,
            totalCount: entry.value.total,
            revealedCount: entry.value.revealed,
            difficultCount: entry.value.difficult,
          ),
        )
        .toList(growable: false);
  }

  static List<Drug> selectDrugs(
    List<Drug> drugs, {
    String? chapter,
    String? subcategory,
    Set<String> excludedIds = const <String>{},
    StudyOrderMode orderMode = StudyOrderMode.sequential,
    List<String> shuffledIds = const <String>[],
  }) {
    final filtered = drugs.where((drug) {
      if (excludedIds.contains(drug.id)) return false;
      if (chapter != null && chapter.isNotEmpty && drug.chapter != chapter) {
        return false;
      }
      if (subcategory != null &&
          subcategory.isNotEmpty &&
          drug.subcategory != subcategory) {
        return false;
      }
      return true;
    }).toList();

    if (orderMode == StudyOrderMode.sequential) {
      filtered.sort(compareByStudyOrder);
      return List<Drug>.unmodifiable(filtered);
    }

    final byId = {for (final drug in filtered) drug.id: drug};
    final ordered = <Drug>[];
    final selectedIds = <String>{};
    for (final id in shuffledIds) {
      final drug = byId[id];
      if (drug == null || !selectedIds.add(id)) continue;
      ordered.add(drug);
    }
    final remaining =
        byId.values.where((drug) => !selectedIds.contains(drug.id)).toList()
          ..sort(compareByStudyOrder);
    ordered.addAll(remaining);
    return List<Drug>.unmodifiable(ordered);
  }

  static List<String> createShuffledIds(List<Drug> drugs, {Random? random}) {
    final ids = drugs.map((drug) => drug.id).toList();
    ids.shuffle(random ?? Random());
    return List<String>.unmodifiable(ids);
  }
}

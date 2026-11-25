import 'drug.dart';

/// 单条药名检索结果，携带命中的别名或作用机制标记以便结果卡片展示。
class DrugSearchResult {
  const DrugSearchResult({
    required this.drug,
    this.matchedAlias,
    this.matchedMechanism = false,
  });

  final Drug drug;
  final String? matchedAlias;
  final bool matchedMechanism;
}

/// 按编号、通用名、别称、药理分类及作用靶点机制的相关性检索。
abstract final class DrugSearchEngine {
  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s()（）\-‐‑‒–—−﹣－]'), '');

  static List<DrugSearchResult> search(List<Drug> drugs, String rawQuery) {
    final query = _normalize(rawQuery);
    if (query.isEmpty) {
      return drugs
          .map((drug) => DrugSearchResult(drug: drug))
          .toList(growable: false);
    }

    final matches = <({DrugSearchResult result, int rank, int index})>[];
    final number = int.tryParse(query);
    for (var index = 0; index < drugs.length; index++) {
      final drug = drugs[index];
      final hit = _matchSingleDrug(drug, query, number);
      if (hit != null) {
        matches.add((result: hit.result, rank: hit.rank, index: index));
      }
    }
    matches.sort((a, b) {
      final comparison = a.rank.compareTo(b.rank);
      return comparison == 0 ? a.index.compareTo(b.index) : comparison;
    });
    return matches.map((match) => match.result).toList(growable: false);
  }

  static ({DrugSearchResult result, int rank})? _matchSingleDrug(
    Drug drug,
    String query,
    int? number,
  ) {
    final name = _normalize(drug.name);
    if (query == _normalize(drug.id) ||
        (number != null && number == int.tryParse(drug.id))) {
      return (result: DrugSearchResult(drug: drug), rank: 0);
    }
    if (name == query) return (result: DrugSearchResult(drug: drug), rank: 1);
    if (name.startsWith(query)) {
      return (result: DrugSearchResult(drug: drug), rank: 2);
    }
    if (name.contains(query)) {
      return (result: DrugSearchResult(drug: drug), rank: 3);
    }
    for (final alias in drug.aliases) {
      if (_normalize(alias).contains(query)) {
        return (
          result: DrugSearchResult(drug: drug, matchedAlias: alias),
          rank: 4,
        );
      }
    }
    if (_normalize(drug.chapter).contains(query) ||
        _normalize(drug.subcategory).contains(query) ||
        _normalize(drug.category).contains(query)) {
      return (result: DrugSearchResult(drug: drug), rank: 5);
    }
    if (_normalize(drug.mechanism).contains(query)) {
      return (
        result: DrugSearchResult(drug: drug, matchedMechanism: true),
        rank: 6,
      );
    }
    if (drug.id.contains(query)) {
      return (result: DrugSearchResult(drug: drug), rank: 7);
    }
    return null;
  }
}

class Drug {
  const Drug({
    required this.id,
    required this.name,
    required this.smiles,
    required this.structure,
    this.chapter = '',
    this.subcategory = '',
    this.mechanism = '',
    this.category = '',
    this.sortOrder = 0,
    this.aliases = const <String>[],
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'] as List<dynamic>?;
    final category = (json['category'] as String?) ?? '';
    final rawChapter = (json['chapter'] as String?)?.trim() ?? '';
    final rawSubcategory = (json['subcategory'] as String?)?.trim() ?? '';
    final rawMechanism = (json['mechanism'] as String?)?.trim() ?? '';
    final parts = category.split('·');
    // 未显式提供大类或小类时，从 category 的「·」分隔符回退，兼容旧数据。
    final fallbackChapter = parts.first.trim();
    final fallbackSubcategory = parts.length > 1
        ? parts.sublist(1).join('·').trim()
        : '';
    final id = json['id'] as String;
    final rawOrder = json['sortOrder'];

    return Drug(
      id: id,
      name: json['name'] as String,
      smiles: json['smiles'] as String,
      structure: json['structure'] as String,
      chapter: rawChapter.isNotEmpty ? rawChapter : fallbackChapter,
      subcategory: rawSubcategory.isNotEmpty
          ? rawSubcategory
          : fallbackSubcategory,
      mechanism: rawMechanism,
      category: category,
      sortOrder: rawOrder is int ? rawOrder : (int.tryParse(id) ?? 0),
      aliases: rawAliases == null
          ? const <String>[]
          : rawAliases.map((item) => item.toString()).toList(growable: false),
    );
  }

  static const List<int> examRotationAngles = <int>[0, 90, 180, 270];

  final String id;
  final String name;
  final String smiles;
  final String structure;
  final String chapter;
  final String subcategory;
  final String mechanism;
  final String category;
  final int sortOrder;
  final List<String> aliases;

  /// 根据拟真考场旋转角度返回对应正立文字 SVG 资源路径。
  String structureForAngle(int angle) {
    return switch (angle) {
      90 => 'assets/structures/rot90/$id.svg',
      180 => 'assets/structures/rot180/$id.svg',
      270 => 'assets/structures/rot270/$id.svg',
      _ => structure,
    };
  }
}

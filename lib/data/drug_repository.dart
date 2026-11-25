import 'dart:convert';

import 'package:flutter/services.dart';

import 'drug.dart';

class DrugRepository {
  const DrugRepository({this.bundle});

  static const String _dataAssetPath = 'assets/drugs.json';

  final AssetBundle? bundle;

  Future<List<Drug>> loadDrugs() async {
    final assetBundle = bundle ?? rootBundle;
    final rawJson = await assetBundle.loadString(_dataAssetPath);
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((item) => Drug.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

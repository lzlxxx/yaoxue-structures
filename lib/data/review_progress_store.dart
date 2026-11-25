import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 复习进度的本地保存内容。
class ReviewProgressSnapshot {
  const ReviewProgressSnapshot({
    this.revealedIds = const <String>{},
    this.lastDrugId,
    this.lastScrollOffset = 0,
  });

  static const ReviewProgressSnapshot empty = ReviewProgressSnapshot();

  final Set<String> revealedIds;
  final String? lastDrugId;
  final double lastScrollOffset;

  bool get hasProgress =>
      revealedIds.isNotEmpty || lastDrugId != null || lastScrollOffset > 0;
}

/// 三项进度以同一条 JSON 写入，按调用顺序完成保存与清空。
class ReviewProgressStore {
  static const _key = 'review_progress_v2';
  Future<void> _pending = Future<void>.value();

  Future<ReviewProgressSnapshot> load({Set<String>? validDrugIds}) async {
    await _pending;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.get(_key);
    if (raw is! String) return ReviewProgressSnapshot.empty;
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return ReviewProgressSnapshot.empty;
    }
    if (decoded is! Map<String, dynamic>) {
      return ReviewProgressSnapshot.empty;
    }
    final ids = decoded['revealedIds'];
    final revealed = ids is List
        ? ids.whereType<String>().where((id) => id.isNotEmpty).toSet()
        : <String>{};
    if (validDrugIds != null) revealed.retainAll(validDrugIds);
    final last = decoded['lastDrugId'];
    final validLast =
        last is String &&
        last.isNotEmpty &&
        (validDrugIds == null || validDrugIds.contains(last));
    final offset = decoded['lastScrollOffset'];
    final validOffset = offset is num && offset.isFinite && offset >= 0;
    return ReviewProgressSnapshot(
      revealedIds: Set<String>.unmodifiable(revealed),
      lastDrugId: validLast ? last : null,
      lastScrollOffset: validOffset && (last == null || validLast)
          ? offset.toDouble()
          : 0,
    );
  }

  Future<void> save(ReviewProgressSnapshot snapshot) {
    final offset = snapshot.lastScrollOffset;
    final encoded = jsonEncode({
      'revealedIds': snapshot.revealedIds.toList()..sort(),
      'lastDrugId': snapshot.lastDrugId,
      'lastScrollOffset': offset.isFinite && offset >= 0 ? offset : 0,
    });
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_key, encoded);
      if (!saved) throw StateError('复习进度保存失败');
    });
  }

  Future<void> clear() => _enqueue(() async {
    final preferences = await SharedPreferences.getInstance();
    final cleared = await preferences.remove(_key);
    if (!cleared) throw StateError('复习进度清空失败');
  });

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.catchError((Object error) {});
    return result;
  }
}

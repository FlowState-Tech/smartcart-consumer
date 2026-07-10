import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/experience/domain/value_objects.dart';

class WalletStorage {
  final FlutterSecureStorage _storage;
  static const _key = 'wallet_state_json';

  WalletStorage(this._storage);

  Future<void> save({
    required int points,
    required List<GamificationBadge> badges,
    String? activeVoucher,
    double? lastSavings,
    int validationsCount = 0,
    int purchasesCount = 0,
    double totalSavings = 0,
  }) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'points': points,
        'badges': badges
            .map((b) => {'id': b.id, 'name': b.name, 'description': b.description, 'iconCode': b.iconCode})
            .toList(),
        'activeVoucher': activeVoucher,
        'lastSavings': lastSavings,
        'validationsCount': validationsCount,
        'purchasesCount': purchasesCount,
        'totalSavings': totalSavings,
      }),
    );
  }

  Future<Map<String, dynamic>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

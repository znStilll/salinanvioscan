import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_result.dart';

class ScanHistoryService {
  static const String boxName = 'scan_history';

  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return Hive.openBox<String>(boxName);
  }

  static Future<void> save(ScanResult result) async {
    final box = await _box();
    await box.put(result.id, jsonEncode(result.toJson()));
  }

  static Future<List<ScanResult>> getAll() async {
    final box = await _box();
    final results = <ScanResult>[];

    for (final raw in box.values) {
      try {
        results.add(
          ScanResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        );
      } catch (_) {}
    }

    results.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return results;
  }

  static Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }
}

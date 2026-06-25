// lib/logic/persistence_store.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PersistenceStore {
  PersistenceStore._();

  static const String _prefix = 'frododesk_';

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value);
  }

  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  static Future<bool?> loadBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key');
  }

  static Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$key', value);
  }

  static Future<int?> loadInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$key');
  }

  static Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefix$key', value);
  }

  static Future<double?> loadDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_prefix$key');
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_prefix$key', value);
  }

  static Future<List<String>?> loadStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_prefix$key');
  }

  static Future<void> saveJsonMap(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> loadJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  static Future<void> saveJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>> loadJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  static Future<void> clearAllFrodoDeskData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith(_prefix)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<String> exportAllFrodoDeskDataAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    final Map<String, dynamic> data = {};

    for (final key in allKeys) {
      if (!key.startsWith(_prefix)) continue;

      final value = prefs.get(key);

      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        data[key] = value;
      }
    }

    final export = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  static Future<int> importAllFrodoDeskDataFromJson(
    String rawJson, {
    bool clearBeforeImport = true,
  }) async {
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map) {
      throw FormatException('Formato importazione non valido');
    }

    final rawData = decoded['data'];

    if (rawData is! Map) {
      throw FormatException('Dati FrodoDesk mancanti');
    }

    final prefs = await SharedPreferences.getInstance();

    if (clearBeforeImport) {
      await clearAllFrodoDeskData();
    }

    int imported = 0;

    for (final entry in rawData.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key is! String || !key.startsWith(_prefix)) continue;

      if (value is String) {
        await prefs.setString(key, value);
        imported++;
      } else if (value is bool) {
        await prefs.setBool(key, value);
        imported++;
      } else if (value is int) {
        await prefs.setInt(key, value);
        imported++;
      } else if (value is double) {
        await prefs.setDouble(key, value);
        imported++;
      } else if (value is List) {
        await prefs.setStringList(key, value.map((e) => e.toString()).toList());
        imported++;
      }
    }

    return imported;
  }
}
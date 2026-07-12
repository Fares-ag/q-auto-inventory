import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists cached lists to disk so cold-start reads are instant.
///
/// Backed by [SharedPreferences] (cross-platform: Android XML, iOS plist,
/// web localStorage, desktop file). Storing a list of model objects works as
/// long as each item exposes [Map<String, dynamic> toJson()]; Firestore
/// [Timestamp]s are converted to ISO 8601 strings during encoding so the
/// existing `fromJson` factories (which already handle ISO strings) read
/// them back transparently.
///
/// Typical usage:
///   await PersistentCacheService.instance.init();        // call once in main
///   ...
///   final cached = persistent.getJsonList('items_all_all');
///   if (cached != null) { /* hydrate UI instantly */ }
///   ...
///   persistent.setJsonList('items_all_all', items.map((i) => i.toJson()).toList());
class PersistentCacheService {
  PersistentCacheService._();
  static final PersistentCacheService instance = PersistentCacheService._();

  // Bumping this prefix invalidates all previously persisted data, e.g. when
  // a model schema change would break old cached payloads.
  static const String _prefix = 'qcache_v1_';

  // Hard cap so we never bloat web localStorage (which is limited to ~5MB).
  static const int _maxItemsPerKey = 5000;

  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('PersistentCacheService init failed: $e');
    }
  }

  bool get isReady => _prefs != null;

  /// Read a previously persisted list of JSON maps. Returns null if no entry
  /// exists or if decoding fails.
  List<Map<String, dynamic>>? getJsonList(String key) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<dynamic, dynamic>>()
            .map<Map<String, dynamic>>(
              (m) => m.map((k, v) => MapEntry(k.toString(), v)),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('PersistentCache decode failed for $key: $e');
    }
    return null;
  }

  /// Persist a list of maps. Fire-and-forget; never throws to caller.
  /// Caps to [_maxItemsPerKey] entries to stay safe for web localStorage.
  Future<void> setJsonList(String key, List<Map<String, dynamic>> items) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final capped =
          items.length > _maxItemsPerKey ? items.take(_maxItemsPerKey).toList() : items;
      final encoded = jsonEncode(_jsonSafe(capped));
      await prefs.setString('$_prefix$key', encoded);
    } catch (e) {
      debugPrint('PersistentCache write failed for $key: $e');
    }
  }

  Future<void> remove(String key) async {
    await _prefs?.remove('$_prefix$key');
  }

  /// Clear every key written by this service. Used on logout/reset.
  Future<void> clearAll() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Recursively converts Firestore [Timestamp] / [DateTime] values to ISO
  /// 8601 strings so the value is safe for [jsonEncode]. The corresponding
  /// `fromJson` factories in `firestore_models.dart` already accept strings,
  /// so round-tripping works transparently.
  static dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _jsonSafe(v)),
      );
    }
    if (value is List) return value.map(_jsonSafe).toList();
    return value;
  }
}

import 'package:hive_flutter/hive_flutter.dart';

import '../data/models.dart';

/// Local database service built on Hive.
///
/// Works identically on Android, iOS and Web (IndexedDB under the hood).
/// Two boxes:
///   - `ac_history`  : analysis sessions / call records
///   - `ac_settings` : app settings (theme, agora config, sensitivity...)
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _historyBox = 'ac_history';
  static const _settingsBox = 'ac_settings';

  late Box _history;
  late Box _settings;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _history = await Hive.openBox(_historyBox);
    _settings = await Hive.openBox(_settingsBox);
    _ready = true;
  }

  // ---------------- history ----------------

  List<SessionRecord> get records {
    final list = _history.values
        .map((e) => SessionRecord.fromMap(e as Map<dynamic, dynamic>))
        .toList()
      ..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return list;
  }

  Future<void> addRecord(SessionRecord r) =>
      _history.put(r.id, r.toMap());

  Future<void> deleteRecord(String id) => _history.delete(id);

  Future<void> clearRecords() => _history.clear();

  int get recordCount => _history.length;

  // ---------------- settings ----------------

  T? getSetting<T>(String key, {T? fallback}) {
    final v = _settings.get(key);
    if (v is T) return v;
    return fallback;
  }

  Future<void> setSetting(String key, dynamic value) =>
      _settings.put(key, value);

  Future<void> clearSettings() => _settings.clear();
}

/// Well-known setting keys.
class SettingsKeys {
  static const onboarded = 'onboarded';
  static const theme = 'theme_choice';
  static const sensitivity = 'sensitivity'; // human threshold 0.30 .. 0.70
  static const agoraAppId = 'agora_app_id';
  static const agoraToken = 'agora_token';
  static const lastChannel = 'last_channel';
}

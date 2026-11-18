import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/models.dart';

/// Wraps the history table of the local database.
class HistoryController extends ChangeNotifier {
  List<SessionRecord> _records = [];

  HistoryController() {
    reload();
  }

  List<SessionRecord> get records => List.unmodifiable(_records);

  int get totalScans => _records.length;

  int get humanCount =>
      _records.where((r) => r.verdict == Verdict.human).length;

  int get syntheticCount =>
      _records.where((r) => r.verdict == Verdict.synthetic).length;

  int get humanPercent =>
      totalScans == 0 ? 0 : (humanCount * 100 / totalScans).round();

  void reload() {
    _records = DatabaseService.instance.records;
    notifyListeners();
  }

  Future<void> add(SessionRecord r) async {
    await DatabaseService.instance.addRecord(r);
    reload();
  }

  Future<void> remove(String id) async {
    await DatabaseService.instance.deleteRecord(id);
    reload();
  }

  Future<void> clearAll() async {
    await DatabaseService.instance.clearRecords();
    reload();
  }
}

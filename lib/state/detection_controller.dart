import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/sources.dart';
import '../core/utils.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../detection/engine.dart';

/// Drives an [AudioSource] into the [LivenessEngine] and exposes
/// everything the UI needs (score, waveform peaks, elapsed time...).
class DetectionController extends ChangeNotifier {
  final LivenessEngine engine;

  DetectionController({LivenessEngine? engine})
      : engine = engine ?? LivenessEngine() {
    _loadSensitivity();
  }

  AudioSource? source;
  SourceKind? activeKind;
  String externalLabel = '';

  bool running = false;
  DateTime? startedAt;
  Duration elapsed = Duration.zero;
  DetectionResult? latest;
  String? lastError;

  /// Decimated amplitude peaks for the live waveform painter.
  final List<double> peaks = [];
  static const int maxPeaks = 96;

  Timer? _ticker;
  final List<double> _recentScores = [];

  void _loadSensitivity() {
    final t = DatabaseService.instance
        .getSetting<double>(SettingsKeys.sensitivity, fallback: 0.5);
    engine.humanThreshold = (t ?? 0.5).clamp(0.3, 0.7).toDouble();
  }

  double get threshold => engine.humanThreshold;

  Future<void> setThreshold(double t) async {
    engine.humanThreshold = t.clamp(0.3, 0.7).toDouble();
    await DatabaseService.instance
        .setSetting(SettingsKeys.sensitivity, engine.humanThreshold);
    notifyListeners();
  }

  Verdict get verdict =>
      latest?.verdictAt(engine.humanThreshold) ?? Verdict.analyzing;

  /// ---- lifecycle ----------------------------------------------------

  Future<bool> start(SourceKind kind, {String? title}) async {
    await stop(saveRecord: false);
    lastError = null;
    final s = buildSource(kind);
    if (!s.available) {
      lastError = s.unavailableReason;
      notifyListeners();
      return false;
    }
    source = s;
    activeKind = kind;
    engine.reset();
    peaks.clear();
    _recentScores.clear();
    latest = null;
    try {
      await s.start(_onChunk);
    } catch (e) {
      lastError = e.toString();
      source = null;
      activeKind = null;
      notifyListeners();
      return false;
    }
    running = true;
    startedAt = DateTime.now();
    elapsed = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (startedAt != null) {
        elapsed = DateTime.now().difference(startedAt!);
        notifyListeners();
      }
    });
    notifyListeners();
    return true;
  }

  /// External audio (e.g. raw frames from an Agora call) can be fed in
  /// directly without an [AudioSource].
  Future<void> attachExternal({required String label}) async {
    await stop(saveRecord: false);
    lastError = null;
    externalLabel = label;
    engine.reset();
    peaks.clear();
    _recentScores.clear();
    latest = null;
    running = true;
    startedAt = DateTime.now();
    elapsed = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (startedAt != null) {
        elapsed = DateTime.now().difference(startedAt!);
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void feedExternal(AudioChunk chunk) => _onChunk(chunk);

  void _onChunk(AudioChunk chunk) {
    engine.push(chunk);
    _updatePeaks(chunk);
    latest = engine.latest;
    if (latest != null) {
      _recentScores.add(latest!.humanScore);
      if (_recentScores.length > 40) _recentScores.removeAt(0);
    }
    notifyListeners();
  }

  void _updatePeaks(AudioChunk chunk) {
    final n = 6;
    final step = chunk.samples.length ~/ n;
    for (var i = 0; i < n; i++) {
      double maxAbs = 0;
      for (var j = i * step; j < (i + 1) * step && j < chunk.samples.length; j++) {
        final v = chunk.samples[j].abs();
        if (v > maxAbs) maxAbs = v;
      }
      peaks.add(Utils.clamp01(maxAbs * 2.2));
    }
    while (peaks.length > maxPeaks) {
      peaks.removeAt(0);
    }
  }

  /// Stable (smoothed) score for display and saving.
  double get smoothScore {
    if (_recentScores.isEmpty) return 0.5;
    final last = _recentScores.length < 8
        ? _recentScores
        : _recentScores.sublist(_recentScores.length - 8);
    return last.reduce((a, b) => a + b) / last.length;
  }

  SessionRecord? buildRecord({required String title, SourceKind? overrideKind}) {
    if (startedAt == null) return null;
    final duration = DateTime.now().difference(startedAt!);
    final score = smoothScore;
    return SessionRecord(
      id: Utils.newId(),
      title: title,
      source: overrideKind ?? activeKind ?? SourceKind.demoHuman,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      durationSec: duration.inSeconds,
      humanScore: score,
      verdict: engine.warmedUp
          ? (score >= engine.humanThreshold
              ? Verdict.human
              : Verdict.synthetic)
          : Verdict.analyzing,
      samplesAnalyzed: engine.samplesSeen,
    );
  }

  Future<SessionRecord?> stop({bool saveRecord = true, String? title}) async {
    SessionRecord? record;
    if (running && saveRecord) {
      record = buildRecord(
        title: title ??
            source?.label ??
            (externalLabel.isEmpty ? 'Analysis session' : externalLabel),
      );
    }
    _ticker?.cancel();
    _ticker = null;
    await source?.stop();
    source = null;
    running = false;
    externalLabel = '';
    notifyListeners();
    return record;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    source?.stop();
    super.dispose();
  }
}

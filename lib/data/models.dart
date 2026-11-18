/// Data models persisted in the local Hive database.

enum Verdict {
  human('Human voice', 'Sounds like a real person'),
  synthetic('AI voice detected', 'Strong synthetic-speech indicators'),
  analyzing('Analyzing', 'Collecting more audio');

  final String label;
  final String caption;
  const Verdict(this.label, this.caption);

  static Verdict fromName(String? name) =>
      Verdict.values.firstWhere(
        (v) => v.name == name,
        orElse: () => Verdict.analyzing,
      );
}

enum SourceKind {
  liveMic('Live microphone'),
  webMic('Browser microphone'),
  demoHuman('Demo - human speech'),
  demoAI('Demo - AI voice'),
  agoraCall('Secure Agora call'),
  demoCall('Demo call');

  final String label;
  const SourceKind(this.label);
}

/// One analysis session (live scan, demo run or call) stored in history.
class SessionRecord {
  final String id;
  final String title;
  final SourceKind source;
  final int startedAtMs;
  final int durationSec;
  final double humanScore; // 0..1, higher = more human-like
  final Verdict verdict;
  final int samplesAnalyzed;

  SessionRecord({
    required this.id,
    required this.title,
    required this.source,
    required this.startedAtMs,
    required this.durationSec,
    required this.humanScore,
    required this.verdict,
    required this.samplesAnalyzed,
  });

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(startedAtMs);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'source': source.name,
        'startedAtMs': startedAtMs,
        'durationSec': durationSec,
        'humanScore': humanScore,
        'verdict': verdict.name,
        'samplesAnalyzed': samplesAnalyzed,
      };

  factory SessionRecord.fromMap(Map<dynamic, dynamic> m) => SessionRecord(
        id: m['id'] as String? ?? '?',
        title: m['title'] as String? ?? 'Session',
        source: SourceKind.values.firstWhere(
          (s) => s.name == m['source'],
          orElse: () => SourceKind.demoHuman,
        ),
        startedAtMs: m['startedAtMs'] as int? ?? 0,
        durationSec: m['durationSec'] as int? ?? 0,
        humanScore: (m['humanScore'] as num?)?.toDouble() ?? 0.5,
        verdict: Verdict.fromName(m['verdict'] as String?),
        samplesAnalyzed: m['samplesAnalyzed'] as int? ?? 0,
      );
}

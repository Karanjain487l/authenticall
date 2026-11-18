import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/models.dart';
import 'platform_sources.dart' as platform;
import 'simulation_source.dart';

/// A mono PCM chunk delivered by any [AudioSource].
class AudioChunk {
  final Float32List samples; // -1.0 .. 1.0
  final int sampleRate;
  const AudioChunk(this.samples, this.sampleRate);
}

class AudioSourceException implements Exception {
  final String message;
  AudioSourceException(this.message);
  @override
  String toString() => message;
}

/// Anything that can stream live audio into the detection engine.
abstract class AudioSource {
  String get label;
  String get tagline;
  IconData get icon;

  /// Why this source cannot run right now (null = available).
  String? get unavailableReason => null;
  bool get available => unavailableReason == null;

  bool get running;

  Future<void> start(void Function(AudioChunk chunk) onChunk);
  Future<void> stop();
}

/// A source that is greyed-out in the UI with a helpful reason.
class UnavailableSource extends AudioSource {
  @override
  final String label;
  final String reason;
  @override
  final IconData icon;

  UnavailableSource(this.label, this.reason,
      {this.icon = Icons.mic_off_rounded});

  @override
  String get tagline => reason;

  @override
  String? get unavailableReason => reason;

  @override
  bool get running => false;

  @override
  Future<void> start(void Function(AudioChunk chunk) onChunk) =>
      Future.error(AudioSourceException(reason));

  @override
  Future<void> stop() async {}
}

/// Builds a source for the UI selector. Demo sources work everywhere;
/// microphone sources are resolved per-platform via conditional imports.
AudioSource buildSource(SourceKind kind) {
  switch (kind) {
    case SourceKind.demoHuman:
      return SimulationSource.human();
    case SourceKind.demoAI:
      return SimulationSource.synthetic();
    case SourceKind.liveMic:
    case SourceKind.webMic:
      return platform.platformSourceFor(kind);
    default:
      return UnavailableSource(kind.label, 'Not a direct audio source');
  }
}

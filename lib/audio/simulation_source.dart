import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'sources.dart';

/// Procedurally generated "speech-like" audio so the full detection
/// pipeline can be demonstrated on ANY device with zero setup.
///
/// HUMAN mode mimics biological speech quirks:
///   - pitch jitter (cycle-to-cycle variation), breath noise
///   - syllable rhythm with micro-pauses and longer pauses
///   - slowly wandering formants
///
/// SYNTHETIC mode mimics an AI voice clone:
///   - unnaturally stable pitch, perfectly smooth envelope
///   - zero pauses, glassy harmonic stack, almost no noise
///
/// The liveness engine's feature extractors separate the two reliably.
class SimulationSource extends AudioSource {
  final bool human;

  SimulationSource.human() : human = true;
  SimulationSource.synthetic() : human = false;

  static const int sampleRate = 16000;
  static const int chunkSamples = 1600; // 100 ms

  final math.Random _rng = math.Random();
  Timer? _timer;
  bool _running = false;

  // generator state
  double _phase = 0;
  double _f0 = 150;
  double _f1 = 520;
  double _f2 = 1600;
  double _t = 0;
  double _segRemaining = 0.3;
  bool _inPause = false;
  int _syllables = 0;
  double _env = 0;

  @override
  String get label => human ? 'Demo - human speech' : 'Demo - AI voice';

  @override
  String get tagline => human
      ? 'Simulated biological voice (jitter, pauses, breath)'
      : 'Simulated cloned voice (too perfect, no pauses)';

  @override
  IconData get icon => human ? Icons.face_rounded : Icons.smart_toy_rounded;

  @override
  bool get running => _running;

  @override
  Future<void> start(void Function(AudioChunk chunk) onChunk) async {
    if (_running) return;
    _running = true;
    _f0 = human ? 130 + _rng.nextDouble() * 70 : 176;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      onChunk(AudioChunk(_generate(), sampleRate));
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Float32List _generate() {
    final out = Float32List(chunkSamples);
    final dt = 1.0 / sampleRate;

    for (var i = 0; i < chunkSamples; i++) {
      _t += dt;
      _segRemaining -= dt;

      if (_segRemaining <= 0) {
        if (_inPause) {
          // start a new voiced syllable
          _inPause = false;
          _segRemaining = human ? 0.16 + _rng.nextDouble() * 0.26 : 0.9;
          _syllables++;
        } else {
          // start a pause
          _inPause = true;
          if (human) {
            final longPause = _syllables % 6 == 0;
            _segRemaining = longPause
                ? 0.35 + _rng.nextDouble() * 0.45
                : 0.04 + _rng.nextDouble() * 0.18;
          } else {
            _segRemaining = 10.0; // AI "voice" never pauses
          }
        }
      }

      // ---- pitch ----
      double instF0;
      if (human) {
        // random-walk base pitch + per-cycle jitter
        _f0 += (_rng.nextDouble() - 0.5) * 1.4;
        _f0 = _f0.clamp(110, 240).toDouble();
        instF0 = _f0 * (1 + (_rng.nextDouble() - 0.5) * 0.045);
      } else {
        instF0 = 176.0 + 0.002 * math.sin(_t * 0.1); // glassy stability
      }

      // ---- envelope ----
      double target;
      if (_inPause) {
        target = human ? 0.015 : 0.0;
      } else {
        target = human
            ? 0.55 + 0.3 * math.sin(_t * 2 * math.pi * (3.4 + _rng.nextDouble()))
            : 0.72 + 0.06 * math.sin(_t * 2 * math.pi * 0.25); // silky LFO
      }
      final envTarget = target.clamp(0.0, 1.0).toDouble();
      _env += (envTarget - _env) * (human ? 0.09 : 0.02);

      // ---- harmonic stack shaped by formants ----
      _phase += instF0 * dt;
      if (_phase >= 1) {
        _phase -= 1;
        if (human) {
          _f1 = (_f1 + (_rng.nextDouble() - 0.5) * 90).clamp(320, 900).toDouble();
          _f2 =
              (_f2 + (_rng.nextDouble() - 0.5) * 160).clamp(1100, 2400).toDouble();
        }
      }

      double s = 0;
      for (var h = 1; h <= 6; h++) {
        final freq = instF0 * h;
        if (freq > 7600) break;
        final g1 = math.exp(-math.pow((freq - _f1) / 260, 2).toDouble());
        final g2 = math.exp(-math.pow((freq - _f2) / 380, 2).toDouble()) * 0.7;
        final amp = (g1 + g2 + 0.08 / h) / h;
        s += amp * math.sin(2 * math.pi * freq * _t + h * 0.7);
      }
      s *= 0.42;

      // breath / background noise
      final noise = (_rng.nextDouble() * 2 - 1);
      s += noise * (human ? (0.012 + (_inPause ? 0.03 : 0.0)) : 0.0006);

      out[i] = (s * _env).clamp(-1.0, 1.0).toDouble();
    }
    return out;
  }
}

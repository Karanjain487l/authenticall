import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/dsp.dart';
import '../audio/sources.dart';
import '../data/models.dart';
import 'tflite_runner.dart';

class DetectionResult {
  final double humanScore;
  final bool warmedUp;
  final Map<String, double> metrics;
  final DateTime at;

  const DetectionResult({
    required this.humanScore,
    required this.warmedUp,
    required this.metrics,
    required this.at,
  });

  Verdict verdictAt(double threshold) {
    if (!warmedUp) return Verdict.analyzing;
    return humanScore >= threshold ? Verdict.human : Verdict.synthetic;
  }
}

class LivenessEngine {
  double humanThreshold;

  LivenessEngine({this.humanThreshold = 0.5}) {
    _runnerFuture = TfliteRunner.create();
  }

  static const int modelSamples = 80000;
  static const int modelSampleRate = 16000;
  static const int inferenceHopSamples = 16000;

  static const int maxFrames = 56;

  final Queue<FrameFeatures> _frames = Queue();

  final List<double> _modelPcm = <double>[];

  late final Future<TfliteRunner?> _runnerFuture;

  TfliteRunner? _runner;

  bool _modelReady = false;
  bool _inferenceRunning = false;

  int samplesSeen = 0;
  int _inferenceCount = 0;

  double _lastSpoofProbability = 0.5;
  double _lastHumanScore = 0.5;

  double _scoreSum = 0;
  int _scoreCount = 0;

  void reset() {
    _frames.clear();
    _modelPcm.clear();

    samplesSeen = 0;
    _inferenceCount = 0;

    _lastSpoofProbability = 0.5;
    _lastHumanScore = 0.5;

    _scoreSum = 0;
    _scoreCount = 0;
  }

  void push(AudioChunk chunk) {
    samplesSeen += chunk.samples.length;

    // Keep the existing DSP metrics for the UI.
    final f = Dsp.extractFrame(chunk.samples, chunk.sampleRate);

    if (f != null) {
      _frames.addLast(f);

      while (_frames.length > maxFrames) {
        _frames.removeFirst();
      }
    }

    // Feed the actual audio into the TFLite model buffer.
    final samples = _resampleTo16k(
      chunk.samples,
      chunk.sampleRate,
    );

    _modelPcm.addAll(samples);

    // Don't allow the rolling buffer to grow indefinitely.
    if (_modelPcm.length > modelSamples + inferenceHopSamples) {
      final removeCount = _modelPcm.length - modelSamples;
      _modelPcm.removeRange(0, removeCount);
    }

    _maybeRunInference();
  }

  bool get warmedUp =>
      _modelReady && _inferenceCount > 0;

  double get sessionAverage =>
      _scoreCount == 0 ? 0.5 : _scoreSum / _scoreCount;

  DetectionResult? get latest {
    if (_frames.length < 6) return null;

    final m = _metrics();

    final score = _lastHumanScore;

    if (_inferenceCount > 0) {
      _scoreSum += score;
      _scoreCount++;
    }

    return DetectionResult(
      humanScore: score,
      warmedUp: warmedUp,
      metrics: {
        ...m,
        'modelReady': _modelReady ? 1.0 : 0.0,
        'inferenceCount': _inferenceCount.toDouble(),
        'spoofProb': _lastSpoofProbability,
        'modelBufferSamples': _modelPcm.length.toDouble(),
      },
      at: DateTime.now(),
    );
  }

  void _maybeRunInference() {
    if (_inferenceRunning) return;

    if (_modelPcm.length < modelSamples) {
      return;
    }

    final window = Float32List(modelSamples);

    for (var i = 0; i < modelSamples; i++) {
      window[i] = _modelPcm[i];
    }

    // Remove one second worth of audio so inference happens
    // approximately once per second.
    _modelPcm.removeRange(0, inferenceHopSamples);

    _inferenceRunning = true;

    print(
      'AuthentiCall: Running TFLite inference '
      '(window=${window.length} samples)',
    );

    unawaited(_runInference(window));
  }

  Future<void> _runInference(Float32List window) async {
    try {
      _runner ??= await _runnerFuture;

      if (_runner == null) {
        print('AuthentiCall: TFLite runner unavailable');
        return;
      }

      _modelReady = true;

      final spoofProbability = await _runner!.run(window);

      _lastSpoofProbability = spoofProbability;

      // The model output is named "spoof_prob".
      // Therefore human likelihood is the inverse.
      final humanScore = 1.0 - spoofProbability;

      _lastHumanScore = humanScore.clamp(0.0, 1.0);

      _inferenceCount++;

      print(
        '========================================',
      );
      print(
        'AuthentiCall TFLite INFERENCE #$_inferenceCount',
      );
      print(
        'spoof_prob = '
        '${spoofProbability.toStringAsFixed(6)}',
      );
      print(
        'humanScore = '
        '${_lastHumanScore.toStringAsFixed(6)}',
      );
      print(
        '========================================',
      );
    } catch (e, st) {
      print('AuthentiCall TFLite inference ERROR: $e');
      print(st);
    } finally {
      _inferenceRunning = false;

      // If another complete window accumulated while inference
      // was running, process it.
      if (_modelPcm.length >= modelSamples) {
        _maybeRunInference();
      }
    }
  }

  Float32List _resampleTo16k(
    List<double> input,
    int inputRate,
  ) {
    if (input.isEmpty) {
      return Float32List(0);
    }

    if (inputRate == modelSampleRate) {
      return Float32List.fromList(input);
    }

    final outputLength =
        (input.length * modelSampleRate / inputRate).round();

    final output = Float32List(outputLength);

    final ratio = inputRate / modelSampleRate;

    for (var i = 0; i < outputLength; i++) {
      final sourcePosition = i * ratio;

      final left = sourcePosition.floor();
      final right = math.min(left + 1, input.length - 1);

      final fraction = sourcePosition - left;

      output[i] =
          input[left] * (1.0 - fraction) +
          input[right] * fraction;
    }

    return output;
  }

  Map<String, double> _metrics() {
    final active = _frames.where((f) => f.active).toList();
    final voiced = active.where((f) => f.voiced).toList();

    final pauses =
        _frames.where((f) => !f.active).length /
        math.max(1, _frames.length);

    double pitchCv = 0;
    double pitchMean = 0;

    if (voiced.length >= 4) {
      final pitches =
          voiced.map((f) => f.pitchHz).toList();

      pitchMean =
          pitches.reduce((a, b) => a + b) /
          pitches.length;

      final variance =
          pitches
                  .map((p) => math.pow(p - pitchMean, 2))
                  .reduce((a, b) => a + b) /
              pitches.length;

      pitchCv =
          math.sqrt(variance) /
          math.max(1, pitchMean);
    }

    double jitter = 0;

    if (voiced.length >= 4) {
      double acc = 0;
      int n = 0;

      double prev = voiced.first.pitchHz;

      for (var i = 1; i < voiced.length; i++) {
        final p = voiced[i].pitchHz;

        if (prev > 0 && p > 0) {
          acc += (p - prev).abs() / p;
          n++;
        }

        prev = p;
      }

      jitter = n == 0 ? 0 : acc / n;
    }

    double shimmer = 0;

    if (active.length >= 4) {
      final rmsList =
          active.map((f) => f.rms).toList();

      final mean =
          rmsList.reduce((a, b) => a + b) /
          rmsList.length;

      final variance =
          rmsList
                  .map((r) => math.pow(r - mean, 2))
                  .reduce((a, b) => a + b) /
              rmsList.length;

      shimmer =
          math.sqrt(variance) /
          math.max(1e-6, mean);
    }

    double flatnessMean = 0;

    if (active.isNotEmpty) {
      flatnessMean =
          active
                  .map((f) => f.spectralFlatness)
                  .reduce((a, b) => a + b) /
              active.length;
    }

    double centroidMean = 0;
    double centroidStd = 0;

    if (active.length >= 2) {
      final cs =
          active.map((f) => f.spectralCentroid).toList();

      centroidMean =
          cs.reduce((a, b) => a + b) /
          cs.length;

      centroidStd = math.sqrt(
        cs
                .map((c) => math.pow(c - centroidMean, 2))
                .reduce((a, b) => a + b) /
            cs.length,
      );
    }

    return {
      'pitch': pitchMean,
      'pitchCv': pitchCv,
      'jitter': jitter,
      'shimmer': shimmer,
      'pauses': pauses,
      'flatness': flatnessMean,
      'centroid': centroidMean,
      'centroidStd': centroidStd,
      'voicedRatio':
          _frames.isEmpty
              ? 0
              : voiced.length / _frames.length,
      'energy':
          active.isEmpty
              ? 0
              : active
                      .map((f) => f.rms)
                      .reduce((a, b) => a + b) /
                  active.length,
    };
  }

  Future<void> dispose() async {
    _runner?.close();
    _runner = null;
  }
}
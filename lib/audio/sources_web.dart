import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/models.dart';
import 'sources.dart';

// ---- Minimal typed bindings for the Web Audio API ----

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _MediaDevices get mediaDevices;
}

extension type _MediaDevices._(JSObject _) implements JSObject {
  external JSPromise<JSObject> getUserMedia(JSAny? constraints);
}

extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external double get sampleRate;
  external _MediaStreamSource createMediaStreamSource(JSObject stream);
  external _AnalyserNode createAnalyser();
  external JSPromise<JSAny?> resume();
  external void close();
}

extension type _MediaStreamSource._(JSObject _) implements JSObject {
  external void connect(JSObject destination);
}

extension type _AnalyserNode._(JSObject _) implements JSObject {
  external set fftSize(int value);
  external void getFloatTimeDomainData(JSFloat32Array array);
}

/// Real microphone capture in the browser (getUserMedia + AnalyserNode).
class WebMicSource extends AudioSource {
  _AudioContext? _ctx;
  _AnalyserNode? _analyser;
  JSFloat32Array? _jsBuf;
  Timer? _timer;
  bool _running = false;

  int _decim = 3;
  final List<double> _acc = [];

  @override
  String get label => 'Browser microphone';

  @override
  String get tagline => 'Analyze real sound through your mic';

  @override
  IconData get icon => Icons.mic_rounded;

  @override
  bool get running => _running;

  @override
  Future<void> start(void Function(AudioChunk chunk) onChunk) async {
    if (_running) return;
    try {
      final stream = await _navigator.mediaDevices
          .getUserMedia({'audio': true}.jsify())
          .toDart;
      final ctx = _AudioContext();
      try {
        await ctx.resume().toDart;
      } catch (_) {}
      final src = ctx.createMediaStreamSource(stream);
      final analyser = ctx.createAnalyser();
      analyser.fftSize = 2048;
      src.connect(analyser);

      _ctx = ctx;
      _analyser = analyser;
      _jsBuf = JSFloat32Array.withLength(2048);
      _decim = math.max(1, (ctx.sampleRate / 16000).round());

      _running = true;
      _timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
        _pull(onChunk);
      });
    } catch (e) {
      throw AudioSourceException(
          'Could not open the browser microphone. Check site permissions and try again. ($e)');
    }
  }

  void _pull(void Function(AudioChunk) onChunk) {
    final analyser = _analyser;
    final buf = _jsBuf;
    if (analyser == null || buf == null || !_running) return;
    analyser.getFloatTimeDomainData(buf);
    final data = buf.toDart;
    for (var i = 0; i < data.length; i += _decim) {
      _acc.add(data[i]);
    }
    while (_acc.length >= 1600) {
      final chunk = Float32List.fromList(_acc.sublist(0, 1600));
      _acc.removeRange(0, 1600);
      onChunk(AudioChunk(chunk, 16000));
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    try {
      _ctx?.close();
    } catch (_) {}
    _ctx = null;
    _analyser = null;
    _acc.clear();
  }
}

AudioSource platformSourceFor(SourceKind kind) {
  if (kind == SourceKind.webMic) return WebMicSource();
  return UnavailableSource(kind.label, 'Live mic on web uses "Browser mic"');
}

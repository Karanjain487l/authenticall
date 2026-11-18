import 'dart:async';
import 'dart:typed_data';

import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models.dart';

import 'sources.dart';

/// Real microphone capture on Android / iOS via audio_streamer.
class MobileMicSource extends AudioSource {
  StreamSubscription<List<double>>? _sub;
  bool _running = false;
  int _rate = 16000;

  @override
  String get label => 'Live microphone';

  @override
  String get tagline => 'Analyze real sound around you';

  @override
  IconData get icon => Icons.mic_rounded;

  @override
  bool get running => _running;

  @override
  Future<void> start(void Function(AudioChunk chunk) onChunk) async {
    if (_running) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw AudioSourceException(
          'Microphone permission was denied. Enable it in system settings to scan live audio.');
    }

    try {
      AudioStreamer().sampleRate = 16000;
    } catch (_) {}
    try {
      _rate = await AudioStreamer().actualSampleRate;
      if (_rate < 4000) _rate = 16000;
    } catch (_) {
      _rate = 16000;
    }

    _running = true;
    _sub = AudioStreamer().audioStream.listen(
      (buffer) {
        if (!_running) return;
        final samples = Float32List.fromList(buffer);
        onChunk(AudioChunk(samples, _rate));
      },
      onError: (Object e) {
        _running = false;
      },
      cancelOnError: true,
    );
  }

 @override
Future<void> stop() async {
  _running = false;
  await _sub?.cancel();
  _sub = null;
}
}

AudioSource platformSourceFor(SourceKind kind) {
  if (kind == SourceKind.liveMic) return MobileMicSource();
  return UnavailableSource(
      kind.label, 'Browser microphone works on web only');
}

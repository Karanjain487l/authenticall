import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Thin, defensive wrapper around the Agora RTC engine.
///
/// Highlights:
///  - audio-only secure calls (join / leave / mute / speaker)
///  - RAW playback audio frames are decoded in Dart and streamed to the
///    detection engine -> live deepfake analysis of the REMOTE voice,
///    no rooting, no telecom access needed.
class AgoraService {
  RtcEngine? _engine;
  bool _observerAttached = false;

  bool get isInitialized => _engine != null;
  bool get rawAudioAttached => _observerAttached;

  Future<void> ensureInit({
    required String appId,
    void Function()? onJoined,
    void Function(int uid)? onUserJoined,
    void Function(int uid)? onUserLeft,
    void Function(String message)? onError,
    void Function()? onConnectionLost,
  }) async {
    if (_engine != null) return;

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
      areaCode: AreaCode.areaCodeGlob.index,
    ));
    _engine = engine;

    await engine.enableAudio();
    try {
      await engine.setDefaultAudioRouteToSpeakerphone(true);
    } catch (_) {}

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => onJoined?.call(),
      onUserJoined: (connection, remoteUid, elapsed) =>
          onUserJoined?.call(remoteUid),
      onUserOffline: (connection, remoteUid, reason) =>
          onUserLeft?.call(remoteUid),
      onError: (err, msg) => onError?.call('$err'),
      onConnectionLost: (connection) => onConnectionLost?.call(),
    ));
  }

  Future<void> join(String channel, int uid, {String? token}) async {
    await _engine?.joinChannel(
    token: token ?? '',
      channelId: channel,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> leave() async {
    try {
      await _engine?.leaveChannel();
    } catch (_) {}
  }

  Future<void> muteLocal(bool muted) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (_) {}
  }

  Future<void> setSpeakerphone(bool on) async {
    try {
      await _engine?.setDefaultAudioRouteToSpeakerphone(on);
    } catch (_) {}
  }

  /// Registers the raw-audio observer. Returns true on success.
  /// Called dynamically so a signature change in a future SDK version
  /// degrades gracefully instead of breaking the build.
  Future<bool> attachRawAudio(
      void Function(Float32List samples, int sampleRate) onFrame) async {
    final engine = _engine;
    if (engine == null) return false;
    if (_observerAttached) return true;

    final observer = AudioFrameObserver(
      onPlaybackAudioFrame: (String channelId, AudioFrame frame) =>
          _decode(frame, onFrame),
      onMixedAudioFrame: (String channelId, AudioFrame frame) =>
          _decode(frame, onFrame),
    );

    try {
      await (engine as dynamic).registerAudioFrameObserver(observer: observer);
      _observerAttached = true;
    } catch (_) {
      try {
        await (engine as dynamic).registerAudioFrameObserver(observer);
        _observerAttached = true;
      } catch (_) {
        _observerAttached = false;
      }
    }
    return _observerAttached;
  }

  Future<void> detachRawAudio() async {
    if (!_observerAttached) return;
    final engine = _engine;
    if (engine != null) {
      try {
        await (engine as dynamic).unregisterAudioFrameObserver();
      } catch (_) {
        try {
          await (engine as dynamic)
              .registerAudioFrameObserver(observer: null);
        } catch (_) {}
      }
    }
    _observerAttached = false;
  }

  /// PCM (usually int16 interleaved) -> mono float32 -> callback.
  void _decode(
      AudioFrame frame, void Function(Float32List, int) onFrame) {
    final buf = frame.buffer;
    if (buf == null || buf.isEmpty) return;

    final channels = frame.channels ?? 1;
    final rate = frame.samplesPerSec ?? 16000;
    final bytes = (frame.bytesPerSample?.value as int?) ?? 2;
    if (bytes != 2 && bytes != 4) return;

    final frames = buf.length ~/ (bytes * channels);
    if (frames <= 0) return;
    final mono = Float32List(frames);
    final view = ByteData.sublistView(buf);

    if (bytes == 2) {
      for (var i = 0; i < frames; i++) {
        double acc = 0;
        for (var c = 0; c < channels; c++) {
          acc += view.getInt16((i * channels + c) * 2, Endian.little) / 32768;
        }
        mono[i] = acc / channels;
      }
    } else {
      for (var i = 0; i < frames; i++) {
        double acc = 0;
        for (var c = 0; c < channels; c++) {
          acc += view.getInt32((i * channels + c) * 4, Endian.little) /
              2147483648;
        }
        mono[i] = acc / channels;
      }
    }

    // Rough decimation down to ~16 kHz keeps feature extraction happy.
    final decim = rate ~/ 16000;
    if (decim > 1) {
      final out = Float32List(frames ~/ decim);
      for (var i = 0; i < out.length; i++) {
        out[i] = mono[i * decim];
      }
      onFrame(out, rate ~/ decim);
    } else {
      onFrame(mono, rate);
    }
  }

  Future<void> dispose() async {
    await detachRawAudio();
    try {
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }
}

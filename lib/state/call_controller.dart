import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/sources.dart';
import '../core/config.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../services/agora_service.dart';
import 'detection_controller.dart';

enum CallState { idle, connecting, active, demoActive }

/// Orchestrates secure Agora calls + the demo-call fallback, and keeps
/// the detection engine attached to the remote voice.
class CallController extends ChangeNotifier {
  final DetectionController detection;
  final AgoraService agora = AgoraService();

  CallController(this.detection);

  CallState state = CallState.idle;
  String? error;
  String notice = '';

  String channel = 'authenticall-demo';
  final int myUid = 10000 + Random().nextInt(89999);
  final Set<int> remoteUsers = {};

  bool muted = false;
  bool speakerOn = true;
  bool rawAudioActive = false;
  bool demoUsesAI = true;

  DateTime? _startedAt;
  Duration elapsed = Duration.zero;
  Timer? _ticker;

  String get appId {
    final stored = DatabaseService.instance
        .getSetting<String>(SettingsKeys.agoraAppId, fallback: '');
    if ((stored ?? '').trim().isNotEmpty) return stored!;
    return AppConfig.agoraAppId; // fallback baked into the build
  }

  bool get agoraConfigured => appId.trim().isNotEmpty;

  bool get inCall => state == CallState.active || state == CallState.demoActive;

  void loadLastChannel() {
    channel = DatabaseService.instance
            .getSetting<String>(SettingsKeys.lastChannel,
                fallback: 'authenticall-demo') ??
        'authenticall-demo';
  }

  /// Public notify for screens that mutate simple fields.
  void refresh() => notifyListeners();

  /// Aborts a connection attempt.
  Future<void> cancelConnecting() async {
    await agora.leave();
    state = CallState.idle;
    notice = '';
    notifyListeners();
  }

  Future<void> saveAppId(String id, {String token = ''}) async {
    await DatabaseService.instance.setSetting(SettingsKeys.agoraAppId, id.trim());
    await DatabaseService.instance.setSetting(SettingsKeys.agoraToken, token.trim());
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Real Agora call
  // ------------------------------------------------------------------

  Future<String?> join(String channelName) async {
    error = null;
    notice = '';
    if (!agoraConfigured) return 'missing_app_id';

    channel = channelName.trim();
    await DatabaseService.instance
        .setSetting(SettingsKeys.lastChannel, channel);

    state = CallState.connecting;
    notifyListeners();

    try {
      await agora.ensureInit(
        appId: appId,
        onJoined: () {
          state = CallState.active;
          _startTimer();
          notifyListeners();
        },
        onUserJoined: (uid) {
          remoteUsers.add(uid);
          notifyListeners();
        },
        onUserLeft: (uid) {
          remoteUsers.remove(uid);
          notifyListeners();
        },
        onError: (msg) {
          error = msg;
          notifyListeners();
        },
        onConnectionLost: () {
          notice = 'Connection lost - trying to recover...';
          notifyListeners();
        },
      );

      // Hook the RAW remote audio into the detection pipeline.
      rawAudioActive = await agora.attachRawAudio((samples, rate) {
        if (state == CallState.active) {
          detection.feedExternal(AudioChunk(samples, rate));
        }
      });

      await agora.join(
        channel,
        myUid,
        token: DatabaseService.instance
            .getSetting<String>(SettingsKeys.agoraToken, fallback: ''),
      );

      state = CallState.active;
      _startTimer();

      if (rawAudioActive) {
        await detection.attachExternal(label: 'Live call - remote stream');
        notice = 'Analyzing the raw remote voice stream in real time.';
      } else {
        // Fallback: analyze through the device microphone (the speaker
        // audio is picked up), so detection still runs on any platform.
        final micKind = buildSource(SourceKind.liveMic).available
            ? SourceKind.liveMic
            : SourceKind.webMic;
        final ok = await detection.start(micKind,
            title: 'Secure call - $channel');
        notice = ok
            ? 'Raw stream hook unavailable here - analyzing via device microphone. Keep the call on speaker.'
            : 'Raw stream hook unavailable on this platform - detection is paused for this call.';
      }
      notifyListeners();
      return null;
    } catch (e) {
      state = CallState.idle;
      error = 'Could not join the call: $e';
      notifyListeners();
      return error;
    }
  }

  // ------------------------------------------------------------------
  // Demo call (works with zero configuration)
  // ------------------------------------------------------------------

  Future<void> startDemoCall({bool aiVoice = true}) async {
    error = null;
    notice = '';
    demoUsesAI = aiVoice;
    state = CallState.demoActive;
    _startTimer();
    await detection.start(
      aiVoice ? SourceKind.demoAI : SourceKind.demoHuman,
      title: 'Demo call',
    );
    notice = aiVoice
        ? 'Simulated caller is using an AI-cloned voice.'
        : 'Simulated caller is a real human voice.';
    notifyListeners();
  }

  Future<void> switchDemoPersona(bool aiVoice) async {
    if (state != CallState.demoActive) return;
    demoUsesAI = aiVoice;
    await detection.start(
      aiVoice ? SourceKind.demoAI : SourceKind.demoHuman,
      title: 'Demo call',
    );
    notice = aiVoice
        ? 'Simulated caller is using an AI-cloned voice.'
        : 'Simulated caller is a real human voice.';
    notifyListeners();
  }

  // ------------------------------------------------------------------

  void _startTimer() {
    _startedAt = DateTime.now();
    elapsed = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null) {
        elapsed = DateTime.now().difference(_startedAt!);
        notifyListeners();
      }
    });
  }

  Future<void> toggleMute() async {
    muted = !muted;
    if (state == CallState.active) await agora.muteLocal(muted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    if (state == CallState.active) await agora.setSpeakerphone(speakerOn);
    notifyListeners();
  }

  /// Ends the call (real or demo) and returns the record to persist.
  Future<SessionRecord?> hangUp() async {
    final wasDemo = state == CallState.demoActive;
    final hadRaw = rawAudioActive;

    _ticker?.cancel();
    _ticker = null;

    if (state == CallState.active) {
      await agora.detachRawAudio();
      await agora.leave();
    }

    SessionRecord? record;
    if (wasDemo) {
      record = detection.buildRecord(
        title: demoUsesAI ? 'Demo call - AI caller' : 'Demo call - human caller',
        overrideKind: SourceKind.demoCall,
      );
      await detection.stop(saveRecord: false);
    } else {
      record = detection.buildRecord(
        title: hadRaw
            ? 'Secure call - $channel'
            : 'Secure call - $channel (mic fallback)',
        overrideKind: SourceKind.agoraCall,
      );
      await detection.stop(saveRecord: false);
    }

    state = CallState.idle;
    rawAudioActive = false;
    muted = false;
    remoteUsers.clear();
    notice = '';
    error = null;
    notifyListeners();
    return record;
  }
}

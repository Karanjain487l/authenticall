/// Platform router for microphone sources.
///
/// The Dart compiler picks exactly ONE of these implementations:
///   - Android / iOS  -> sources_mobile.dart  (audio_streamer plugin)
///   - Web            -> sources_web.dart     (Web Audio API)
///   - anything else  -> sources_stub.dart    (graceful fallback)
export 'sources_stub.dart'
    if (dart.library.io) 'sources_mobile.dart'
    if (dart.library.js_interop) 'sources_web.dart';

import '../data/models.dart';
import 'sources.dart';

/// Fallback for platforms without microphone support - the UI simply
/// shows these sources as unavailable, demo mode keeps working.
AudioSource platformSourceFor(SourceKind kind) {
  return UnavailableSource(
    kind.label,
    'Microphone capture is not supported on this platform',
  );
}

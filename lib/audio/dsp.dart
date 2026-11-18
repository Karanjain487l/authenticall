import 'dart:math' as math;
import 'dart:typed_data';

/// Acoustic features extracted from a single ~64 ms analysis frame.
class FrameFeatures {
  final double rms;
  final double zeroCrossingRate;
  final double spectralFlatness;
  final double spectralCentroid;
  final double pitchHz; // 0 when unvoiced
  final double pitchConfidence;
  final bool voiced;

  const FrameFeatures({
    required this.rms,
    required this.zeroCrossingRate,
    required this.spectralFlatness,
    required this.spectralCentroid,
    required this.pitchHz,
    required this.pitchConfidence,
    required this.voiced,
  });

  bool get active => rms > 0.008;
}

/// Lightweight digital signal processing: Hann window, radix-2 FFT,
/// spectral features and autocorrelation pitch estimation.
class Dsp {
  static const int frameSize = 1024;

  static final Float32List _hann = _buildHann(frameSize);
  static final Float32List _re = Float32List(frameSize);
  static final Float32List _im = Float32List(frameSize);

  static Float32List _buildHann(int n) {
    final w = Float32List(n);
    for (var i = 0; i < n; i++) {
      w[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
    }
    return w;
  }

  /// Extracts features from the tail of [samples] at [sampleRate] Hz.
  static FrameFeatures? extractFrame(Float32List samples, int sampleRate) {
    if (samples.length < frameSize || sampleRate < 4000) return null;
    final offset = samples.length - frameSize;

    // ---- time-domain features ----
    double sumSq = 0;
    int crossings = 0;
    for (var i = 0; i < frameSize; i++) {
      final v = samples[offset + i];
      sumSq += v * v;
      if (i > 0) {
        final prev = samples[offset + i - 1];
        if ((v >= 0 && prev < 0) || (v < 0 && prev >= 0)) crossings++;
      }
      _re[i] = v * _hann[i];
      _im[i] = 0;
    }
    final rms = math.sqrt(sumSq / frameSize);
    final zcr = crossings / frameSize;

    // ---- spectrum ----
    _fft(_re, _im);
    final half = frameSize ~/ 2;
    double totalMag = 0;
    double logSum = 0;
    double weighted = 0;
    final mags = Float32List(half);
    for (var k = 0; k < half; k++) {
      final m = math.sqrt(_re[k] * _re[k] + _im[k] * _im[k]);
      mags[k] = m;
      totalMag += m;
      logSum += math.log(m + 1e-9);
      weighted += k * m;
    }
    final geoMean = math.exp(logSum / half);
    final arithMean = totalMag / half + 1e-12;
    final flatness = (geoMean / arithMean).clamp(0.0, 1.0).toDouble();
    final binHz = sampleRate / frameSize;
    final centroid = totalMag > 1e-6
    ? (weighted / totalMag) * binHz
    : 0.0;

    // ---- pitch (autocorrelation, 60..420 Hz search) ----
    final minLag = math.max(4, sampleRate ~/ 420);
    final maxLag = math.min(frameSize - 2, sampleRate ~/ 60);
    double best = 0;
    int bestLag = 0;
    double energy = 0;
    for (var i = 0; i < frameSize; i++) {
      energy += _re[i] * _re[i];
    }
    if (energy > 1e-6 && rms > 0.01) {
      for (var lag = minLag; lag <= maxLag; lag++) {
        double acc = 0;
        for (var i = 0; i + lag < frameSize; i += 2) {
          acc += _re[i] * _re[i + lag];
        }
        final norm = acc / (energy * 0.5 + 1e-9);
        if (norm > best) {
          best = norm;
          bestLag = lag;
        }
      }
    }
    final voiced = best > 0.38 && rms > 0.012;
    final pitch = (voiced && bestLag > 0) ? sampleRate / bestLag : 0.0;

    return FrameFeatures(
      rms: rms,
      zeroCrossingRate: zcr,
      spectralFlatness: flatness,
      spectralCentroid: centroid,
      pitchHz: pitch,
      pitchConfidence: best.clamp(0.0, 1.0).toDouble(),
      voiced: voiced,
    );
  }

  /// Iterative in-place radix-2 Cooley-Tukey FFT.
  static void _fft(Float32List re, Float32List im) {
    final n = re.length;
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      for (; (j & bit) != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wr = math.cos(ang);
      final wi = math.sin(ang);
      for (var i = 0; i < n; i += len) {
        double cwr = 1, cwi = 0;
        for (var j = 0; j < len ~/ 2; j++) {
          final ur = re[i + j];
          final ui = im[i + j];
          final vr = re[i + j + len ~/ 2] * cwr - im[i + j + len ~/ 2] * cwi;
          final vi = re[i + j + len ~/ 2] * cwi + im[i + j + len ~/ 2] * cwr;
          re[i + j] = ur + vr;
          im[i + j] = ui + vi;
          re[i + j + len ~/ 2] = ur - vr;
          im[i + j + len ~/ 2] = ui - vi;
          final nwr = cwr * wr - cwi * wi;
          cwi = cwr * wi + cwi * wr;
          cwr = nwr;
        }
      }
    }
  }
}

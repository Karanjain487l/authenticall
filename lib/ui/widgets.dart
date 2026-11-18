import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/palette.dart';
import '../core/utils.dart';
import '../data/models.dart';

// =====================================================================
//  SoftButton - the signature pastel pill button (always visible in
//  both light & dark mode thanks to adaptive palettes)
// =====================================================================

enum SoftButtonVariant { primary, fresh, tonal, outline, danger }

class SoftButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SoftButtonVariant variant;
  final bool expanded;
  final bool large;

  const SoftButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.variant = SoftButtonVariant.primary,
    this.expanded = false,
    this.large = false,
  });

  const SoftButton.primary(
      {super.key,
      required this.label,
      this.icon,
      required this.onPressed,
      this.expanded = false,
      this.large = false})
      : variant = SoftButtonVariant.primary;

  const SoftButton.tonal(
      {super.key,
      required this.label,
      this.icon,
      required this.onPressed,
      this.expanded = false,
      this.large = false})
      : variant = SoftButtonVariant.tonal;

  const SoftButton.outline(
      {super.key,
      required this.label,
      this.icon,
      required this.onPressed,
      this.expanded = false,
      this.large = false})
      : variant = SoftButtonVariant.outline;

  const SoftButton.danger(
      {super.key,
      required this.label,
      this.icon,
      required this.onPressed,
      this.expanded = false,
      this.large = false})
      : variant = SoftButtonVariant.danger;

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    final enabled = widget.onPressed != null;

    BoxDecoration decoration;
    Color foreground;

    switch (widget.variant) {
      case SoftButtonVariant.primary:
        decoration = BoxDecoration(
          gradient: Palette.primaryGradient(context),
          borderRadius: BorderRadius.circular(widget.large ? 26 : 20),
          boxShadow: [
            BoxShadow(
              color: (dark ? Palette.lavenderBright : Palette.lavender)
                  .withOpacity(dark ? 0.25 : 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        );
        foreground = dark ? Palette.darkBackground : Colors.white;
        break;
      case SoftButtonVariant.fresh:
        decoration = BoxDecoration(
          gradient: Palette.freshGradient(context),
          borderRadius: BorderRadius.circular(widget.large ? 26 : 20),
          boxShadow: [
            BoxShadow(
              color: (dark ? Palette.mintBright : Palette.mint)
                  .withOpacity(dark ? 0.20 : 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        );
        foreground = dark ? Palette.darkBackground : Colors.white;
        break;
      case SoftButtonVariant.tonal:
        decoration = BoxDecoration(
          color: Palette.surfaceAlt(context),
          borderRadius: BorderRadius.circular(widget.large ? 26 : 20),
          border: Border.all(color: Palette.outline(context), width: 1),
        );
        foreground = dark ? Palette.lavenderBright : Palette.lavender;
        break;
      case SoftButtonVariant.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.large ? 26 : 20),
          border: Border.all(
              color: dark ? Palette.darkOutline : Palette.lavenderSoft,
              width: 1.6),
        );
        foreground = Palette.ink(context);
        break;
      case SoftButtonVariant.danger:
        decoration = BoxDecoration(
          color: (dark ? Palette.coralBright : Palette.coral).withOpacity(0.16),
          borderRadius: BorderRadius.circular(widget.large ? 26 : 20),
          border: Border.all(
              color: (dark ? Palette.coralBright : Palette.coral)
                  .withOpacity(0.5),
              width: 1.4),
        );
        foreground = dark ? Palette.coralBright : Palette.coral;
        break;
    }

    final child = AnimatedScale(
      scale: _pressed ? 0.955 : 1,
      duration: const Duration(milliseconds: 110),
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: decoration,
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 24 : 20,
            vertical: widget.large ? 17 : 13,
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.large ? 22 : 19, color: foreground),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    fontSize: widget.large ? 16.5 : 14.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                }
              : null,
          child: child,
        ),
      ),
    );
  }
}

// =====================================================================
//  SoftCard
// =====================================================================

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? Palette.surface(context) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: dark
                ? Palette.darkOutline.withOpacity(0.7)
                : Palette.lightOutline,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : Palette.lavender)
                  .withOpacity(dark ? 0.35 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// =====================================================================
//  Chips & badges
// =====================================================================

class PastelChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const PastelChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.18 : 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The green/red "trust" indicator - the soul of AuthentiCall.
class TrustBadge extends StatelessWidget {
  final Verdict verdict;
  final bool active;
  final bool large;

  const TrustBadge(
      {super.key, required this.verdict, this.active = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    late final Color color;
    late final IconData icon;
    switch (verdict) {
      case Verdict.human:
        color = dark ? Palette.mintBright : const Color(0xFF3E9B77);
        icon = Icons.verified_user_rounded;
        break;
      case Verdict.synthetic:
        color = dark ? Palette.coralBright : Palette.coral;
        icon = Icons.gpp_maybe_rounded;
        break;
      case Verdict.analyzing:
        color = dark ? Palette.butterBright : const Color(0xFFC79A2E);
        icon = Icons.auto_awesome_rounded;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 13, vertical: large ? 10 : 7),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.16 : 0.13),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withOpacity(0.55), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 20 : 16, color: color),
          const SizedBox(width: 7),
          Text(
            verdict.label,
            style: GoogleFonts.quicksand(
              fontSize: large ? 15 : 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Liveness gauge
// =====================================================================

class LivenessGauge extends StatelessWidget {
  final double score; // 0..1
  final bool active;
  final double threshold;
  final Verdict verdict;

  const LivenessGauge({
    super.key,
    required this.score,
    required this.active,
    required this.threshold,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: score.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _GaugePainter(
            value: value,
            threshold: threshold,
            verdict: verdict,
            dark: Palette.isDark(context),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: GoogleFonts.quicksand(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink(context),
                  ),
                ),
                Text(
                  'human likelihood',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSub(context),
                  ),
                ),
                const SizedBox(height: 12),
                TrustBadge(verdict: verdict, active: active),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double threshold;
  final Verdict verdict;
  final bool dark;

  _GaugePainter(
      {required this.value,
      required this.threshold,
      required this.verdict,
      required this.dark});

  static const double _deg = math.pi / 180;
  static const double startAngle = 135 * _deg;
  static const double sweepAngle = 270 * _deg;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 26;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..color = dark ? const Color(0xFF3A3358) : const Color(0xFFEEE8F6);
    canvas.drawArc(rect, startAngle, sweepAngle, false, track);

    // decorative ticks
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = (dark ? Palette.darkInkSub : Palette.lightInkSub)
          .withOpacity(0.35);
    for (var i = 0; i <= 27; i++) {
      final a = startAngle + sweepAngle * (i / 27);
      final p1 = center +
          Offset(math.cos(a), math.sin(a)) * (radius + 13);
      final p2 = center +
          Offset(math.cos(a), math.sin(a)) * (radius + 18);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // progress arc
    final colors = switch (verdict) {
      Verdict.human => dark
          ? [Palette.mintBright, Palette.lavenderBright]
          : [Palette.mint, Palette.lavender],
      Verdict.synthetic => dark
          ? [Palette.coralBright, Palette.peachBright]
          : [Palette.coral, Palette.peach],
      Verdict.analyzing => dark
          ? [Palette.butterBright, Palette.peachBright]
          : [Palette.butter, Palette.peach],
    };
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: colors)
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
        rect,
        startAngle,
        (sweepAngle * value.clamp(0.0, 1.0)).toDouble(),
        false,
        progress);

    // threshold marker
    final tAngle =
        startAngle + (sweepAngle * threshold.clamp(0.0, 1.0)).toDouble();
    final tPos = center + Offset(math.cos(tAngle), math.sin(tAngle)) * radius;
    canvas.drawCircle(
        tPos,
        5.5,
        Paint()
          ..color = dark ? Palette.darkInk : Palette.lightInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.threshold != threshold ||
      old.verdict != verdict ||
      old.dark != dark;
}

// =====================================================================
//  Live waveform
// =====================================================================

class WaveformStrip extends StatelessWidget {
  final List<double> peaks;
  final bool active;

  const WaveformStrip({super.key, required this.peaks, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: CustomPaint(
        size: Size.infinite,
        painter: _WavePainter(
          peaks: peaks,
          active: active,
          dark: Palette.isDark(context),
          primary: Theme.of(context).colorScheme.primary,
          tertiary: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> peaks;
  final bool active;
  final bool dark;
  final Color primary;
  final Color tertiary;

  _WavePainter(
      {required this.peaks,
      required this.active,
      required this.dark,
      required this.primary,
      required this.tertiary});

  @override
  void paint(Canvas canvas, Size size) {
    const maxPeaks = 96;
    final barStep = size.width / maxPeaks;
    final mid = size.height / 2;

    final shader = LinearGradient(colors: [primary, tertiary])
        .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 0; i < peaks.length && i < maxPeaks; i++) {
      final fade = 0.25 + 0.75 * (i / maxPeaks);
      final h = math.max(3.5, peaks[i] * size.height * 0.92);
      final paint = Paint()
        ..shader = shader
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = barStep * 0.55;
      paint.colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(fade), BlendMode.modulate);
      final x = size.width - (peaks.length - i) * barStep;
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }

    if (peaks.isEmpty) {
      canvas.drawLine(
        Offset(0, mid),
        Offset(size.width, mid),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = (dark ? Palette.darkOutline : Palette.lightOutline),
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.peaks.length != peaks.length || old.active != active;
}

// =====================================================================
//  Animated pastel blob background
// =====================================================================

class BlobBackground extends StatefulWidget {
  const BlobBackground({super.key});

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BlobPainter(
            t: _controller.value,
            dark: Palette.isDark(context),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  final bool dark;

  _BlobPainter({required this.t, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final tau = math.pi * 2;
    _blob(
      canvas,
      size,
      Offset(
        size.width * 0.86 + math.sin(t * tau) * size.width * 0.03,
        size.height * 0.10 + math.cos(t * tau) * size.height * 0.02,
      ),
      size.width * 0.52,
      dark ? Palette.lavenderBright : Palette.lavenderSoft,
      dark ? 36 : 110,
    );
    _blob(
      canvas,
      size,
      Offset(
        size.width * 0.06 + math.cos(t * tau + 2) * size.width * 0.03,
        size.height * 0.42 + math.sin(t * tau + 1) * size.height * 0.025,
      ),
      size.width * 0.44,
      dark ? Palette.mintBright : Palette.mintSoft,
      dark ? 30 : 96,
    );
    _blob(
      canvas,
      size,
      Offset(
        size.width * 0.68 + math.sin(t * tau + 4) * size.width * 0.025,
        size.height * 0.90 + math.cos(t * tau + 3) * size.height * 0.02,
      ),
      size.width * 0.5,
      dark ? Palette.blushBright : Palette.blushSoft,
      dark ? 30 : 100,
    );
  }

  void _blob(Canvas canvas, Size size, Offset center, double radius,
      Color color, int alpha) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        color.withOpacity(alpha / 255),
        color.withOpacity(0),
      ]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.dark != dark;
}

// =====================================================================
//  Segmented selector
// =====================================================================

class PastelSegmented<T> extends StatelessWidget {
  final List<T> values;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final T selected;
  final ValueChanged<T> onSelected;

  const PastelSegmented({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.iconOf,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Palette.surfaceAlt(context),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Palette.outline(context)),
      ),
      child: Row(
        children: values.map((v) {
          final isSel = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(v);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? Palette.surface(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: (dark ? Colors.black : Palette.lavender)
                                .withOpacity(dark ? 0.4 : 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                  border: isSel
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconOf != null) ...[
                      Icon(iconOf!(v),
                          size: 16,
                          color: isSel
                              ? Theme.of(context).colorScheme.primary
                              : Palette.inkSub(context)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        labelOf(v),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel
                              ? Palette.ink(context)
                              : Palette.inkSub(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =====================================================================
//  Small building blocks
// =====================================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Palette.ink(context),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBubble(
      {super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.2 : 0.17),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

InputDecoration pastelField(BuildContext context,
    {String? label, String? hint, IconData? icon}) {
  final dark = Palette.isDark(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    labelStyle: GoogleFonts.nunito(fontSize: 13.5),
    filled: true,
    fillColor: Palette.surfaceAlt(context),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
          color: dark ? Palette.darkOutline : Palette.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary, width: 1.6),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

// =====================================================================
//  History list tile (shared by Home & History screens)
// =====================================================================

class HistoryTile extends StatelessWidget {
  final dynamic record; // SessionRecord
  final VoidCallback? onDelete;

  const HistoryTile({super.key, required this.record, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = record;
    final dark = Palette.isDark(context);
    final verdictColor = switch (r.verdict as Verdict) {
      Verdict.human => dark ? Palette.mintBright : const Color(0xFF3E9B77),
      Verdict.synthetic => dark ? Palette.coralBright : Palette.coral,
      Verdict.analyzing => dark ? Palette.butterBright : const Color(0xFFC79A2E),
    };
    final score = (r.humanScore as double);
    final time = Utils.timeAgo(r.startedAt as DateTime);

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconBubble(
            icon: (r.verdict as Verdict) == Verdict.human
                ? Icons.verified_user_rounded
                : (r.verdict as Verdict) == Verdict.synthetic
                    ? Icons.gpp_maybe_rounded
                    : Icons.auto_awesome_rounded,
            color: verdictColor,
            size: 44,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(r.source as SourceKind).label} · $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSub(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(score * 100).round()}%',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: verdictColor,
                ),
              ),
              Text(
                'human',
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Palette.inkSub(context),
                ),
              ),
            ],
          ),
          if (onDelete != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 19, color: Palette.inkSub(context)),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Feedback helpers
// =====================================================================

void showPastelSnack(BuildContext context, String message,
    {IconData icon = Icons.check_circle_rounded}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(icon, size: 18, color: Palette.mintSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  ));
}

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes, do it',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Palette.surface(ctx),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Palette.outline(ctx)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink(ctx)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.nunito(
                  fontSize: 13.5, color: Palette.inkSub(ctx), height: 1.45),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SoftButton.outline(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SoftButton(
                    label: confirmLabel,
                    variant: danger
                        ? SoftButtonVariant.danger
                        : SoftButtonVariant.primary,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

void showPastelSheet(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: child,
    ),
  );
}

/// "How it works" explainer modal.
void showInfoModal(BuildContext context) {
  showPastelSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Palette.outline(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How AuthentiCall works',
            style: GoogleFonts.quicksand(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Palette.ink(context)),
          ),
          const SizedBox(height: 16),
          ...[
            (Icons.graphic_eq_rounded, 'Listen',
                'Audio frames are captured live - from your mic, the browser, or the raw stream of an Agora call.'),
            (Icons.memory_rounded, 'Analyze on-device',
                'A lightweight liveness model measures jitter, shimmer, pauses and spectral texture. Nothing leaves your device.'),
            (Icons.verified_user_rounded, 'Show the verdict',
                'A trust score updates every second: green means human, red flags synthetic AI speech.'),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(icon: e.$1, color: Theme.of(context).colorScheme.primary, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$2,
                            style: GoogleFonts.quicksand(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Palette.ink(context))),
                        const SizedBox(height: 3),
                        Text(e.$3,
                            style: GoogleFonts.nunito(
                                fontSize: 12.8,
                                height: 1.4,
                                color: Palette.inkSub(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SoftButton.primary(
            label: 'Got it',
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

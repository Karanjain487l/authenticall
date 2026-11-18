import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../audio/sources.dart';
import '../../core/palette.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/detection_controller.dart';
import '../../state/history_controller.dart';
import '../widgets.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  SourceKind _selected = SourceKind.demoHuman;

  @override
  void initState() {
    super.initState();
    // Prefer the real microphone when the platform supports it.
    final mic = buildSource(SourceKind.liveMic);
    final webMic = buildSource(SourceKind.webMic);
    if (mic.available) {
      _selected = SourceKind.liveMic;
    } else if (webMic.available) {
      _selected = SourceKind.webMic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DetectionController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
      children: [
        const SectionTitle(title: 'Voice source'),
        _SourceGrid(selected: _selected, onSelected: (k) {
          HapticFeedback.selectionClick();
          setState(() => _selected = k);
        }),

        const SizedBox(height: 20),

        // ---------- gauge ----------
        SoftCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              SizedBox(
                width: 240,
                child: LivenessGauge(
                  score: d.running || d.latest != null ? d.smoothScore : 0.5,
                  active: d.running,
                  threshold: d.threshold,
                  verdict: d.running ? d.verdict : Verdict.analyzing,
                ),
              ),
              const SizedBox(height: 18),
              WaveformStrip(peaks: d.peaks, active: d.running),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PastelChip(
                    label: d.running
                        ? Utils.mmss(d.elapsed)
                        : d.lastError != null
                            ? 'idle'
                            : 'ready',
                    color: d.running
                        ? Theme.of(context).colorScheme.primary
                        : Palette.inkSub(context),
                    icon: d.running
                        ? Icons.timer_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  if (d.running && d.source != null) ...[
                    const SizedBox(width: 8),
                    PastelChip(
                      label: d.source!.label,
                      color: Theme.of(context).colorScheme.tertiary,
                      icon: d.source!.icon,
                    ),
                  ],
                  if (d.running && d.source == null && d.externalLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    PastelChip(
                      label: d.externalLabel,
                      color: Theme.of(context).colorScheme.tertiary,
                      icon: Icons.call_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ---------- error banner ----------
        if (d.lastError != null) ...[
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconBubble(
                    icon: Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.lastError!,
                    style: GoogleFonts.nunito(
                      fontSize: 12.8,
                      height: 1.4,
                      color: Palette.ink(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ---------- live metrics ----------
        const SectionTitle(title: 'What the model hears'),
        _MetricsRow(metrics: d.latest?.metrics),

        // ---------- sensitivity ----------
        const SectionTitle(title: 'Sensitivity'),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            children: [
              Slider(
                value: d.threshold,
                min: 0.30,
                max: 0.70,
                divisions: 8,
                label: 'threshold ${(d.threshold * 100).round()}%',
                onChanged: (v) => d.setThreshold(v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Relaxed',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Palette.inkSub(context))),
                  Text(
                    _sensitivityLabel(d.threshold),
                    style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  Text('Strict',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Palette.inkSub(context))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ---------- start / stop ----------
        if (!d.running)
          SoftButton.primary(
            label: 'Start analysis',
            icon: Icons.play_arrow_rounded,
            expanded: true,
            large: true,
            onPressed: () async {
              final ok = await d.start(_selected);
              if (!ok && mounted) {
                showPastelSnack(
                  context,
                  d.lastError ?? 'Could not start the audio source',
                  icon: Icons.error_outline_rounded,
                );
              }
            },
          )
        else
          SoftButton.danger(
            label: 'Stop & save to history',
            icon: Icons.stop_rounded,
            expanded: true,
            large: true,
            onPressed: () async {
              final record = await d.stop();
              if (record != null && mounted) {
                await context.read<HistoryController>().add(record);
                showPastelSnack(context,
                    'Saved - verdict: ${record.verdict.label}');
              }
            },
          ),
      ],
    );
  }

  String _sensitivityLabel(double t) {
    if (t <= 0.38) return 'Relaxed';
    if (t <= 0.52) return 'Balanced';
    if (t <= 0.62) return 'Careful';
    return 'Strict';
  }
}

class _SourceGrid extends StatelessWidget {
  final SourceKind selected;
  final ValueChanged<SourceKind> onSelected;

  const _SourceGrid({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final kinds = [
      SourceKind.liveMic,
      SourceKind.webMic,
      SourceKind.demoHuman,
      SourceKind.demoAI,
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.52,
      children: kinds.map((kind) {
        final src = buildSource(kind);
        final isSel = kind == selected;
        final available = src.available;
        final color = switch (kind) {
          SourceKind.liveMic =>
            Palette.isDark(context) ? Palette.lavenderBright : Palette.lavender,
          SourceKind.webMic =>
            Palette.isDark(context) ? Palette.peachBright : Palette.peach,
          SourceKind.demoHuman =>
            Palette.isDark(context) ? Palette.mintBright : Palette.mint,
          _ => Palette.isDark(context) ? Palette.blushBright : Palette.blush,
        };
        return GestureDetector(
          onTap: available ? () => onSelected(kind) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.surface(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSel
                    ? Theme.of(context).colorScheme.primary
                    : Palette.outline(context),
                width: isSel ? 1.8 : 1,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: available ? 1 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconBubble(icon: src.icon, color: color, size: 36),
                      const Spacer(),
                      if (isSel)
                        Icon(Icons.check_circle_rounded,
                            size: 19,
                            color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        src.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink(context),
                        ),
                      ),
                      Text(
                        available ? src.tagline : (src.unavailableReason ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Palette.inkSub(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final Map<String, double>? metrics;

  const _MetricsRow({this.metrics});

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final items = <(IconData, String, String)>[
      (
        Icons.music_note_rounded,
        'Pitch',
        m == null ? '—' : '${(m['pitch'] ?? 0).round()} Hz'
      ),
      (
        Icons.show_chart_rounded,
        'Jitter',
        m == null ? '—' : '${((m['jitter'] ?? 0) * 100).toStringAsFixed(2)}%'
      ),
      (
        Icons.pause_circle_outline_rounded,
        'Pauses',
        m == null ? '—' : '${((m['pauses'] ?? 0) * 100).round()}%'
      ),
      (
        Icons.waves_rounded,
        'Texture',
        m == null ? '—' : (m['flatness'] ?? 0).toStringAsFixed(3)
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: items.map((e) {
        return SoftCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(e.$1,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 7),
              Text(
                e.$3,
                maxLines: 1,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink(context),
                ),
              ),
              Text(
                e.$2,
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.inkSub(context),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../state/detection_controller.dart';
import '../../state/history_controller.dart';
import '../shell.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryController>();
    final shell = context.read<ShellController>();
    final detection = context.read<DetectionController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
      children: [
        // ---------- greeting ----------
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Utils.greeting()} ☁️',
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Utils.todayLabel(),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Palette.inkSub(context),
                    ),
                  ),
                ],
              ),
            ),
            const PastelChip(
              label: 'Shield on',
              color: Color(0xFF3E9B77),
              icon: Icons.verified_user_rounded,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ---------- hero ----------
        SoftCard(
          gradient: Palette.heroGradient(context),
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              _ShieldOrb(),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your voice shield is ready',
                      style: GoogleFonts.quicksand(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan any voice - live mic, browser, or the raw stream of a secure Agora call.',
                      style: GoogleFonts.nunito(
                        fontSize: 12.8,
                        height: 1.45,
                        color: Palette.inkSub(context),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SoftButton.primary(
                      label: 'Run a scan',
                      icon: Icons.graphic_eq_rounded,
                      onPressed: () => shell.jumpTo(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---------- stats ----------
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.radar_rounded,
                color: Palette.isDark(context)
                    ? Palette.lavenderBright
                    : Palette.lavender,
                value: '${history.totalScans}',
                label: 'Total scans',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.face_rounded,
                color: Palette.isDark(context)
                    ? Palette.mintBright
                    : const Color(0xFF3E9B77),
                value: '${history.humanPercent}%',
                label: 'Human',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.smart_toy_rounded,
                color: Palette.isDark(context)
                    ? Palette.coralBright
                    : Palette.coral,
                value: '${history.syntheticCount}',
                label: 'AI flags',
              ),
            ),
          ],
        ),

        // ---------- quick actions (bento grid) ----------
        const SectionTitle(title: 'Quick actions'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.62,
          children: [
            _ActionCard(
              icon: Icons.mic_rounded,
              title: 'Live scan',
              subtitle: 'Use your microphone',
              color: Palette.isDark(context)
                  ? Palette.lavenderBright
                  : Palette.lavender,
              onTap: () => shell.jumpTo(1),
            ),
            _ActionCard(
              icon: Icons.smart_toy_rounded,
              title: 'Try an AI voice',
              subtitle: 'Instant demo',
              color: Palette.isDark(context)
                  ? Palette.blushBright
                  : Palette.blush,
              onTap: () {
                shell.jumpTo(1);
                detection.start(SourceKind.demoAI, title: 'AI voice demo');
              },
            ),
            _ActionCard(
              icon: Icons.face_rounded,
              title: 'Try a human voice',
              subtitle: 'Instant demo',
              color: Palette.isDark(context)
                  ? Palette.mintBright
                  : Palette.mint,
              onTap: () {
                shell.jumpTo(1);
                detection.start(SourceKind.demoHuman,
                    title: 'Human voice demo');
              },
            ),
            _ActionCard(
              icon: Icons.call_rounded,
              title: 'Secure call',
              subtitle: 'Agora-powered',
              color: Palette.isDark(context)
                  ? Palette.peachBright
                  : Palette.peach,
              onTap: () => shell.jumpTo(2),
            ),
          ],
        ),

        // ---------- how it works ----------
        const SizedBox(height: 20),
        SoftCard(
          onTap: () => showInfoModal(context),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              IconBubble(
                icon: Icons.lightbulb_rounded,
                color: Palette.isDark(context)
                    ? Palette.butterBright
                    : const Color(0xFFC79A2E),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'How does the detection actually work?',
                  style: GoogleFonts.quicksand(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink(context),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Palette.inkSub(context)),
            ],
          ),
        ),

        // ---------- recent activity ----------
        SectionTitle(
          title: 'Recent activity',
          actionLabel: history.records.isEmpty ? null : 'View all',
          onAction: () => shell.jumpTo(3),
        ),
        if (history.records.isEmpty)
          SoftCard(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '🌱',
                    style: GoogleFonts.nunito(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No scans yet. Run your first one!',
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkSub(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...history.records.take(3).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HistoryTile(record: r),
                ),
              ),
      ],
    );
  }
}

class _ShieldOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                width: 1.6,
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.4),
                width: 1.4,
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: Palette.primaryGradient(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              color: Palette.isDark(context)
                  ? Palette.darkBackground
                  : Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color, size: 36),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Palette.ink(context),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Palette.inkSub(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconBubble(icon: icon, color: color, size: 38),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink(context),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.inkSub(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

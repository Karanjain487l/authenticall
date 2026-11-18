import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../data/database.dart';
import '../../state/call_controller.dart';
import '../../state/detection_controller.dart';
import '../../state/history_controller.dart';
import '../../state/theme_controller.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final detection = context.watch<DetectionController>();
    final call = context.watch<CallController>();
    final history = context.watch<HistoryController>();
    final dark = Palette.isDark(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BlobBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 22, 0),
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Palette.surfaceAlt(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Palette.outline(context)),
                          ),
                        ),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: Palette.ink(context)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Settings',
                        style: GoogleFonts.quicksand(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 60),
                    children: [
                      // ---------- appearance ----------
                      const SectionTitle(title: 'Appearance'),
                      SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _ThemeOption(
                              icon: Icons.light_mode_rounded,
                              title: 'Light',
                              subtitle: 'Warm cream & pastels',
                              color: dark
                                  ? Palette.butterBright
                                  : const Color(0xFFC79A2E),
                              selected:
                                  theme.choice == ThemeModeChoice.light,
                              onTap: () => theme.setChoice(ThemeModeChoice.light),
                            ),
                            const SizedBox(height: 8),
                            _ThemeOption(
                              icon: Icons.dark_mode_rounded,
                              title: 'Dark',
                              subtitle: 'Deep plum night sky',
                              color: dark
                                  ? Palette.lavenderBright
                                  : Palette.lavender,
                              selected:
                                  theme.choice == ThemeModeChoice.dark,
                              onTap: () => theme.setChoice(ThemeModeChoice.dark),
                            ),
                            const SizedBox(height: 8),
                            _ThemeOption(
                              icon: Icons.brightness_auto_rounded,
                              title: 'System',
                              subtitle: 'Follows your device',
                              color: dark
                                  ? Palette.mintBright
                                  : Palette.mint,
                              selected:
                                  theme.choice == ThemeModeChoice.system,
                              onTap: () =>
                                  theme.setChoice(ThemeModeChoice.system),
                            ),
                          ],
                        ),
                      ),

                      // ---------- detection ----------
                      const SectionTitle(title: 'Detection'),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Decision threshold',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Palette.ink(context),
                                  ),
                                ),
                                const Spacer(),
                                PastelChip(
                                  label:
                                      '${(detection.threshold * 100).round()}%',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Higher = stricter proof needed before a voice is called human.',
                              style: GoogleFonts.nunito(
                                fontSize: 12.3,
                                color: Palette.inkSub(context),
                              ),
                            ),
                            Slider(
                              value: detection.threshold,
                              min: 0.30,
                              max: 0.70,
                              divisions: 8,
                              onChanged: (v) => detection.setThreshold(v),
                            ),
                          ],
                        ),
                      ),

                      // ---------- agora ----------
                      const SectionTitle(title: 'Agora secure calls'),
                      _AgoraCard(call: call),

                      // ---------- data ----------
                      const SectionTitle(title: 'Data & privacy'),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconBubble(
                                  icon: Icons.storage_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'On-device database',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Palette.ink(context),
                                        ),
                                      ),
                                      Text(
                                        '${history.totalScans} sessions stored locally. Nothing ever leaves this device.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12.2,
                                          color: Palette.inkSub(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SoftButton.danger(
                                    label: 'Clear history',
                                    icon: Icons.delete_outline_rounded,
                                    expanded: true,
                                    onPressed: () async {
                                      final ok = await showConfirm(
                                        context,
                                        title: 'Clear history?',
                                        message:
                                            'All saved sessions will be deleted.',
                                        confirmLabel: 'Clear',
                                        danger: true,
                                      );
                                      if (ok && context.mounted) {
                                        await history.clearAll();
                                        showPastelSnack(
                                            context, 'History cleared');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SoftButton.outline(
                                    label: 'Reset settings',
                                    icon: Icons.restore_rounded,
                                    expanded: true,
                                    onPressed: () async {
                                      final ok = await showConfirm(
                                        context,
                                        title: 'Reset all settings?',
                                        message:
                                            'Theme, sensitivity and Agora configuration will return to defaults.',
                                        confirmLabel: 'Reset',
                                      );
                                      if (ok && context.mounted) {
                                        await DatabaseService.instance
                                            .clearSettings();
                                        theme.load();
                                        detection.setThreshold(0.5);
                                        call.refresh();
                                        showPastelSnack(
                                            context, 'Settings reset');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ---------- about ----------
                      const SectionTitle(title: 'About'),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AuthentiCall AI · v1.0.0',
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Palette.ink(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Edge-based real-time deepfake voice authentication research prototype. The shipped detector is a transparent acoustic-liveness model - swap in your trained SincNet/LCNN TFLite model for publication-grade accuracy. Not a substitute for professional security tooling.',
                              style: GoogleFonts.nunito(
                                fontSize: 12.3,
                                height: 1.5,
                                color: Palette.inkSub(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                PastelChip(
                                    label: 'Flutter',
                                    color: Palette.lavenderSoft,
                                    icon: Icons.flutter_dash_rounded),
                                PastelChip(
                                    label: 'Agora SD-RTN',
                                    color: Palette.mintSoft,
                                    icon: Icons.hub_rounded),
                                PastelChip(
                                    label: 'Hive DB',
                                    color: Palette.blushSoft,
                                    icon: Icons.storage_rounded),
                                PastelChip(
                                    label: 'On-device AI',
                                    color: Palette.peach,
                                    icon: Icons.memory_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(
                  Palette.isDark(context) ? 0.18 : 0.09)
              : Palette.surfaceAlt(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            IconBubble(icon: icon, color: color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                      fontSize: 12,
                      color: Palette.inkSub(context),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Palette.outline(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Palette.isDark(context)
                          ? Palette.darkBackground
                          : Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgoraCard extends StatefulWidget {
  final CallController call;
  const _AgoraCard({required this.call});

  @override
  State<_AgoraCard> createState() => _AgoraCardState();
}

class _AgoraCardState extends State<_AgoraCard> {
  late final TextEditingController _appIdCtrl =
      TextEditingController(text: widget.call.appId);
  late final TextEditingController _tokenCtrl = TextEditingController(
      text: DatabaseService.instance.getSetting<String>(
              SettingsKeys.agoraToken,
              fallback: '') ??
          '');

  @override
  void dispose() {
    _appIdCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = widget.call.agoraConfigured;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                icon: Icons.hub_rounded,
                color: configured
                    ? (Palette.isDark(context)
                        ? Palette.mintBright
                        : const Color(0xFF3E9B77))
                    : (Palette.isDark(context)
                        ? Palette.butterBright
                        : const Color(0xFFC79A2E)),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configured ? 'Agora configured' : 'Agora not configured',
                      style: GoogleFonts.quicksand(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink(context),
                      ),
                    ),
                    Text(
                      configured
                          ? 'Calls will stream raw audio into the detector'
                          : 'Paste your App ID from console.agora.io',
                      style: GoogleFonts.nunito(
                        fontSize: 12.2,
                        color: Palette.inkSub(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appIdCtrl,
            decoration: pastelField(context,
                label: 'Agora App ID', icon: Icons.key_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenCtrl,
            decoration: pastelField(context,
                label: 'Token (optional)', icon: Icons.lock_outline_rounded),
          ),
          const SizedBox(height: 16),
          SoftButton.primary(
            label: 'Save Agora settings',
            icon: Icons.save_rounded,
            expanded: true,
            onPressed: () async {
              await widget.call
                  .saveAppId(_appIdCtrl.text, token: _tokenCtrl.text);
              if (mounted) {
                showPastelSnack(
                  context,
                  _appIdCtrl.text.trim().isEmpty
                      ? 'Agora App ID cleared'
                      : 'Agora settings saved',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

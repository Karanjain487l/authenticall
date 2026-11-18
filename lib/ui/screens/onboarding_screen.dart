import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/palette.dart';
import '../widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.hearing_rounded,
      'Is it really them?',
      'AI can now clone anyone\'s voice in seconds. AuthentiCall listens to conversations and tells you if the voice on the other side is synthetic - before you get fooled.'
    ),
    (
      Icons.memory_rounded,
      'Tiny AI, on your device',
      'A featherweight liveness model studies pitch jitter, micro-pauses and spectral texture in real time. No cloud, no uploads, no waiting.'
    ),
    (
      Icons.lock_rounded,
      'Private by design',
      'Audio is analyzed locally and never stored. Your call history stays in a small on-device database only you can read.'
    ),
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _pages.length - 1) {
      _pager.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic);
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BlobBackground()),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: TextButton(
                      onPressed: widget.onFinished,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Palette.inkSub(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: _pages.length,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: i == 0
                                    ? Palette.primaryGradient(context)
                                    : i == 1
                                        ? Palette.freshGradient(context)
                                        : LinearGradient(
                                            colors: [
                                              Palette.isDark(context)
                                                  ? Palette.blushBright
                                                  : Palette.blush,
                                              Palette.isDark(context)
                                                  ? Palette.peachBright
                                                  : Palette.peach,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary
                                        .withOpacity(Palette.isDark(context) ? 0.25 : 0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Icon(p.$1,
                                  size: 58,
                                  color: Palette.isDark(context)
                                      ? Palette.darkBackground
                                      : Colors.white),
                            ),
                            const SizedBox(height: 44),
                            Text(
                              p.$2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.quicksand(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Palette.ink(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.$3,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                height: 1.55,
                                color: Palette.inkSub(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 34),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 26 : 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: active
                                  ? scheme.primary
                                  : scheme.primary.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 26),
                      SoftButton.primary(
                        label: _page == _pages.length - 1
                            ? 'Get started'
                            : 'Next',
                        icon: _page == _pages.length - 1
                            ? Icons.spa_rounded
                            : Icons.arrow_forward_rounded,
                        expanded: true,
                        large: true,
                        onPressed: _next,
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

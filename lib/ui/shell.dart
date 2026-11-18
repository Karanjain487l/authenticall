import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/palette.dart';
import 'screens/analyze_screen.dart';
import 'screens/call_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets.dart';

/// Which tab is on screen.
class ShellController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void jumpTo(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _items = [
    _NavItem('Home', Icons.cottage_rounded),
    _NavItem('Scan', Icons.auto_awesome_rounded),
    _NavItem('Call', Icons.call_rounded),
    _NavItem('History', Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Palette.isDark(context)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            const Positioned.fill(child: BlobBackground()),
            SafeArea(
              child: Column(
                children: [
                  _Header(),
                  Expanded(
                    child: IndexedStack(
                      index: shell.index,
                      children: const [
                        HomeScreen(),
                        AnalyzeScreen(),
                        CallScreen(),
                        HistoryScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: _NavBar(index: shell.index),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 14, 2),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: Palette.primaryGradient(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Palette.lavender
                      .withOpacity(Palette.isDark(context) ? 0.3 : 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AuthentiCall',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink(context),
                  ),
                ),
                Text(
                  'your AI-voice shield',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Palette.inkSub(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: Palette.surfaceAlt(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Palette.outline(context)),
              ),
            ),
            icon: Icon(Icons.tune_rounded,
                color: Palette.ink(context), size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  const _NavBar({required this.index});

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    final shell = context.read<ShellController>();

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Palette.surface(context).withOpacity(dark ? 0.96 : 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Palette.outline(context)),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Palette.lavender)
                .withOpacity(dark ? 0.45 : 0.13),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: List.generate(AppShell._items.length, (i) {
          final item = AppShell._items[i];
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                shell.jumpTo(i);
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(dark ? 0.22 : 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 21,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Palette.inkSub(context),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        child: selected
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(left: 8),
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Palette.ink(context),
                                  ),
                                ),
                              )
                            : const SizedBox(width: 0, height: 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

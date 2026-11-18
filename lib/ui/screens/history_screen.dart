import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../data/models.dart';
import '../../state/history_controller.dart';
import '../shell.dart';
import '../widgets.dart';

enum _Filter { all, human, ai }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryController>();
    final dark = Palette.isDark(context);

    final filtered = history.records.where((r) {
      switch (_filter) {
        case _Filter.human:
          return r.verdict == Verdict.human;
        case _Filter.ai:
          return r.verdict == Verdict.synthetic;
        case _Filter.all:
          return true;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
      children: [
        // ---------- summary strip ----------
        SoftCard(
          gradient: Palette.heroGradient(context),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                value: '${history.totalScans}',
                label: 'Scans',
                color: Theme.of(context).colorScheme.primary,
              ),
              _SummaryItem(
                value: '${history.humanCount}',
                label: 'Human',
                color: dark ? Palette.mintBright : const Color(0xFF3E9B77),
              ),
              _SummaryItem(
                value: '${history.syntheticCount}',
                label: 'AI',
                color: dark ? Palette.coralBright : Palette.coral,
              ),
              _SummaryItem(
                value: '${history.humanPercent}%',
                label: 'Trust rate',
                color: dark ? Palette.butterBright : const Color(0xFFC79A2E),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        PastelSegmented<_Filter>(
          values: _Filter.values,
          selected: _filter,
          labelOf: (f) => switch (f) {
            _Filter.all => 'All',
            _Filter.human => 'Human',
            _Filter.ai => 'AI flags',
          },
          iconOf: (f) => switch (f) {
            _Filter.all => Icons.bubble_chart_rounded,
            _Filter.human => Icons.face_rounded,
            _Filter.ai => Icons.smart_toy_rounded,
          },
          onSelected: (f) {
            HapticFeedback.selectionClick();
            setState(() => _filter = f);
          },
        ),

        const SizedBox(height: 18),

        if (history.records.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: Icon(Icons.delete_sweep_rounded,
                  size: 18, color: Theme.of(context).colorScheme.error),
              label: Text(
                'Clear all',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: () async {
                final ok = await showConfirm(
                  context,
                  title: 'Clear entire history?',
                  message:
                      'All ${history.totalScans} saved sessions will be removed from the on-device database. This cannot be undone.',
                  confirmLabel: 'Clear all',
                  danger: true,
                );
                if (ok && mounted) {
                  await history.clearAll();
                  showPastelSnack(context, 'History cleared');
                }
              },
            ),
          ),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 46),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(dark ? 0.16 : 0.1),
                  ),
                  child: Icon(
                    history.records.isEmpty
                        ? Icons.shield_rounded
                        : Icons.search_off_rounded,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  history.records.isEmpty
                      ? 'Nothing here yet'
                      : 'No sessions match this filter',
                  style: GoogleFonts.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  history.records.isEmpty
                      ? 'Every scan and call you run is saved here privately.'
                      : 'Try switching the filter above.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Palette.inkSub(context),
                  ),
                ),
                if (history.records.isEmpty) ...[
                  const SizedBox(height: 22),
                  SoftButton.primary(
                    label: 'Run your first scan',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () =>
                        context.read<ShellController>().jumpTo(1),
                  ),
                ],
              ],
            ),
          )
        else
          ...filtered.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 26),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error),
                ),
                onDismissed: (_) async {
                  await history.remove(r.id);
                  if (context.mounted) {
                    showPastelSnack(context, 'Session deleted');
                  }
                },
                child: HistoryTile(
                  record: r,
                  onDelete: () async {
                    final ok = await showConfirm(
                      context,
                      title: 'Delete this session?',
                      message: '"${r.title}" will be removed from history.',
                      confirmLabel: 'Delete',
                      danger: true,
                    );
                    if (ok) {
                      await history.remove(r.id);
                      if (mounted) {
                        showPastelSnack(context, 'Session deleted');
                      }
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Palette.inkSub(context),
          ),
        ),
      ],
    );
  }
}

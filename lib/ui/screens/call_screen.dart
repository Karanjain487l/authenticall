import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/utils.dart';
import '../../state/call_controller.dart';
import '../../state/detection_controller.dart';
import '../../state/history_controller.dart';
import '../widgets.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _channelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final call = context.read<CallController>();
    call.loadLastChannel();
    _channelCtrl.text = call.channel;
  }

  @override
  void dispose() {
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<void> _join(CallController call) async {
    HapticFeedback.selectionClick();
    final result = await call.join(_channelCtrl.text.trim());
    if (!mounted) return;
    if (result == 'missing_app_id') {
      _showAppIdSheet(call);
    } else if (result != null) {
      showPastelSnack(context, result, icon: Icons.error_outline_rounded);
    }
  }

  void _showAppIdSheet(CallController call) {
    final appIdCtrl = TextEditingController(text: call.appId);
    final tokenCtrl = TextEditingController();

    showPastelSheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
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
            const SizedBox(height: 18),
            Text(
              'Connect your Agora account',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a free project at console.agora.io and paste the App ID below. Calls then flow through Agora\'s encrypted network and AuthentiCall analyzes the raw remote audio.',
              style: GoogleFonts.nunito(
                  fontSize: 12.8,
                  height: 1.45,
                  color: Palette.inkSub(context)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: appIdCtrl,
              decoration: pastelField(context,
                  label: 'Agora App ID', icon: Icons.key_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: pastelField(context,
                  label: 'Token (optional for testing)',
                  icon: Icons.lock_outline_rounded),
            ),
            const SizedBox(height: 20),
            SoftButton.primary(
              label: 'Save & continue',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: () async {
                if (appIdCtrl.text.trim().isEmpty) {
                  showPastelSnack(context, 'Please paste your App ID first',
                      icon: Icons.error_outline_rounded);
                  return;
                }
                await call.saveAppId(appIdCtrl.text, token: tokenCtrl.text);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showPastelSnack(context, 'Agora configured - ready to call!');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallController>();
    final d = context.watch<DetectionController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
      children: [
        if (call.inCall)
          _ActiveCallView(call: call, d: d)
        else if (call.state == CallState.connecting)
          _ConnectingView(call: call, channel: _channelCtrl.text.trim())
        else
          _IdleView(
            call: call,
            channelCtrl: _channelCtrl,
            onJoin: () => _join(call),
            onConfigure: () => _showAppIdSheet(call),
          ),
      ],
    );
  }
}

// =====================================================================

class _IdleView extends StatelessWidget {
  final CallController call;
  final TextEditingController channelCtrl;
  final VoidCallback onJoin;
  final VoidCallback onConfigure;

  const _IdleView({
    required this.call,
    required this.channelCtrl,
    required this.onJoin,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          gradient: Palette.heroGradient(context),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconBubble(
                icon: Icons.lock_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Calls run over Agora\'s secure network - and the remote voice is checked for AI cloning in real time.',
                  style: GoogleFonts.nunito(
                    fontSize: 12.8,
                    height: 1.45,
                    color: Palette.ink(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'Start a secure call'),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: channelCtrl,
                decoration: pastelField(context,
                    label: 'Channel name',
                    hint: 'authenticall-demo',
                    icon: Icons.tag_rounded),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  PastelChip(
                    label: 'You: #${call.myUid}',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(width: 8),
                  PastelChip(
                    label: call.agoraConfigured ? 'Agora ready' : 'Agora not set',
                    color: call.agoraConfigured
                        ? (Palette.isDark(context)
                            ? Palette.mintBright
                            : const Color(0xFF3E9B77))
                        : (Palette.isDark(context)
                            ? Palette.butterBright
                            : const Color(0xFFC79A2E)),
                    icon: call.agoraConfigured
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SoftButton.primary(
                label: 'Join secure call',
                icon: Icons.call_rounded,
                expanded: true,
                large: true,
                onPressed: onJoin,
              ),
              const SizedBox(height: 10),
              SoftButton.outline(
                label: call.agoraConfigured ? 'Change Agora App ID' : 'Configure Agora',
                icon: Icons.key_rounded,
                expanded: true,
                onPressed: onConfigure,
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'No App ID? Try a demo call'),
        SoftCard(
          child: Column(
            children: [
              Text(
                'Simulated conversations with instant detection - perfect for demos.',
                style: GoogleFonts.nunito(
                  fontSize: 12.8,
                  color: Palette.inkSub(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SoftButton(
                      label: 'AI caller',
                      icon: Icons.smart_toy_rounded,
                      variant: SoftButtonVariant.danger,
                      expanded: true,
                      onPressed: () => call.startDemoCall(aiVoice: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftButton.tonal(
                      label: 'Human caller',
                      icon: Icons.face_rounded,
                      expanded: true,
                      onPressed: () => call.startDemoCall(aiVoice: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (call.error != null) ...[
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    call.error!,
                    style: GoogleFonts.nunito(
                        fontSize: 12.8, color: Palette.ink(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =====================================================================

class _ConnectingView extends StatelessWidget {
  final CallController call;
  final String channel;

  const _ConnectingView({required this.call, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Icon(Icons.call_rounded,
                    size: 40, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Connecting to "$channel"...',
            style: GoogleFonts.quicksand(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Palette.ink(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up the encrypted channel',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Palette.inkSub(context),
            ),
          ),
          const SizedBox(height: 34),
          SoftButton.outline(
            label: 'Cancel',
            icon: Icons.close_rounded,
            onPressed: () => call.cancelConnecting(),
          ),
        ],
      ),
    );
  }
}

// =====================================================================

class _ActiveCallView extends StatelessWidget {
  final CallController call;
  final DetectionController d;

  const _ActiveCallView({required this.call, required this.d});

  @override
  Widget build(BuildContext context) {
    final isDemo = call.state == CallState.demoActive;
    final dark = Palette.isDark(context);

    return Column(
      children: [
        // status row
        Row(
          children: [
            PastelChip(
              label: isDemo ? 'Demo call' : 'Live · ${call.channel}',
              color: isDemo
                  ? (dark ? Palette.butterBright : const Color(0xFFC79A2E))
                  : Theme.of(context).colorScheme.primary,
              icon: isDemo ? Icons.science_rounded : Icons.lock_rounded,
            ),
            const Spacer(),
            PastelChip(
              label: isDemo
                  ? 'simulated line'
                  : '${call.remoteUsers.length} remote',
              color: Palette.inkSub(context),
              icon: Icons.people_rounded,
            ),
          ],
        ),
        const SizedBox(height: 30),

        // avatar orb
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDemo && call.demoUsesAI
                            ? Palette.coral
                            : Theme.of(context).colorScheme.primary)
                        .withOpacity(0.35),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDemo && call.demoUsesAI
                      ? LinearGradient(
                          colors: dark
                              ? [Palette.coralBright, Palette.peachBright]
                              : [Palette.coral, Palette.peach])
                      : Palette.primaryGradient(context),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isDemo && call.demoUsesAI
                      ? Icons.smart_toy_rounded
                      : Icons.person_rounded,
                  size: 52,
                  color: dark ? Palette.darkBackground : Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          Utils.mmss(call.elapsed),
          style: GoogleFonts.quicksand(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Palette.ink(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isDemo
              ? (call.demoUsesAI ? 'AI-cloned caller' : 'Human caller')
              : 'Voice call in progress',
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Palette.inkSub(context),
          ),
        ),

        if (call.notice.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              call.notice,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                height: 1.4,
                color: Palette.inkSub(context),
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        // live detection card
        SoftCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Live voice analysis',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink(context),
                    ),
                  ),
                  const Spacer(),
                  TrustBadge(
                    verdict: d.verdict,
                    active: d.running,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WaveformStrip(peaks: d.peaks, active: d.running),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'human likelihood: ',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Palette.inkSub(context)),
                  ),
                  Text(
                    '${(d.smoothScore * 100).round()}%',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // demo persona switch
        if (isDemo) ...[
          const SizedBox(height: 16),
          PastelSegmented<bool>(
            values: const [true, false],
            selected: call.demoUsesAI,
            labelOf: (v) => v ? 'AI caller' : 'Human caller',
            iconOf: (v) =>
                v ? Icons.smart_toy_rounded : Icons.face_rounded,
            onSelected: (v) => call.switchDemoPersona(v),
          ),
        ],

        const SizedBox(height: 26),

        // controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlBubble(
              icon: call.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              active: call.muted,
              onTap: call.toggleMute,
            ),
            const SizedBox(width: 22),
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final record = await call.hangUp();
                if (record != null && context.mounted) {
                  await context.read<HistoryController>().add(record);
                  if (context.mounted) {
                    showPastelSnack(context,
                        'Call ended - saved as "${record.title}"');
                  }
                }
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: dark
                        ? [Palette.coralBright, Palette.blushBright]
                        : [Palette.coral, Palette.blush],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.coral.withOpacity(0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.call_end_rounded,
                    size: 32, color: dark ? Palette.darkBackground : Colors.white),
              ),
            ),
            const SizedBox(width: 22),
            _ControlBubble(
              icon: call.speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              active: call.speakerOn,
              onTap: call.toggleSpeaker,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlBubble extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlBubble(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Palette.isDark(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Theme.of(context).colorScheme.primary.withOpacity(dark ? 0.3 : 0.18)
              : Palette.surfaceAlt(context),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Palette.outline(context),
            width: 1.4,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: active
              ? Theme.of(context).colorScheme.primary
              : Palette.inkSub(context),
        ),
      ),
    );
  }
}

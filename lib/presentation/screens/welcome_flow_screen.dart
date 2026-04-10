import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/debug_flags.dart';
import '../../core/theme/app_theme.dart';
import '../viewmodels/app_controller.dart';
import '../widgets/melon_logo.dart';

class WelcomeFlowScreen extends ConsumerStatefulWidget {
  const WelcomeFlowScreen({
    super.key,
    this.replayMode = false,
  });

  final bool replayMode;

  static Future<void> openReplay(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const WelcomeFlowScreen(replayMode: true),
      ),
    );
  }

  @override
  ConsumerState<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends ConsumerState<WelcomeFlowScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _finishing = false;

  static const _slideCount = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppThemePalette>();
    final accent = theme.colorScheme.primary;
    final accentAlt = theme.colorScheme.secondary;
    final welcomeBadgeLabel = ref.watch(appVersionProvider).maybeWhen(
          data: (version) => 'Melon $version Welcome',
          orElse: () => 'Melon Welcome',
        );

    return Container(
      decoration: AppTheme.appBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final uiScale = _computeUiScale(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final pagePadding = (20 * uiScale).clamp(18, 28).toDouble();
            final shellMaxWidth =
                (constraints.maxWidth * 0.88).clamp(980.0, 1320.0).toDouble();
            final shellHeight =
                (constraints.maxHeight * 0.82).clamp(620.0, 760.0).toDouble();
            final gapLg = (24 * uiScale).clamp(18, 28).toDouble();
            final gapMd = (14 * uiScale).clamp(10, 18).toDouble();

            return Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -80,
                  child: _GlowOrb(
                    size: 320,
                    color: accent.withValues(alpha: 0.16),
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -100,
                  child: _GlowOrb(
                    size: 360,
                    color: accentAlt.withValues(alpha: 0.14),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(pagePadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: shellMaxWidth),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: shellHeight,
                            padding: EdgeInsets.all(
                              (24 * uiScale).clamp(20, 32).toDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: (palette?.panelColor ??
                                      const Color(0xFF101A21))
                                  .withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: (palette?.panelBorderColor ??
                                        Colors.white12)
                                    .withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  blurRadius: 34,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _HeaderBar(
                                  currentIndex: _currentIndex,
                                  slideCount: _slideCount,
                                  replayMode: widget.replayMode,
                                  showDebugBadge:
                                      DebugFlags.showWelcomeFlowPreview,
                                  onClose: widget.replayMode
                                      ? () => Navigator.of(context).pop()
                                      : null,
                                ),
                                SizedBox(height: gapLg),
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (value) =>
                                        setState(() => _currentIndex = value),
                                    children: [
                                      _buildWelcomeSlide(
                                        accent,
                                        accentAlt,
                                        welcomeBadgeLabel,
                                      ),
                                      _buildFeatureSlide(
                                        accent,
                                        accentAlt,
                                        welcomeBadgeLabel,
                                      ),
                                      _buildFlowSlide(
                                        accent,
                                        accentAlt,
                                        welcomeBadgeLabel,
                                      ),
                                      _buildLimitSlide(
                                        accent,
                                        accentAlt,
                                        welcomeBadgeLabel,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: gapMd),
                                _BottomBar(
                                  currentIndex: _currentIndex,
                                  slideCount: _slideCount,
                                  replayMode: widget.replayMode,
                                  busy: _finishing,
                                  onBack: _currentIndex == 0 ? null : _goBack,
                                  onSkip: _finishing ? null : _finishFlow,
                                  onNext: _finishing
                                      ? null
                                      : (_currentIndex == _slideCount - 1
                                          ? _finishFlow
                                          : _goNext),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(
    Color accent,
    Color accentAlt,
    String badgeLabel,
  ) {
    return _SlideFrame(
      badgeLabel: badgeLabel,
      headline: 'Welcome to Melon Mod Manager',
      subhead:
          'Thanks for downloading Melon. This quick tour will show what the app does before you set up your Minecraft folder.',
      accent: accent,
      accentAlt: accentAlt,
      side: _HeroWelcomeVisual(
        accent: accent,
        accentAlt: accentAlt,
      ),
      body: const [
        'Manage mods, resource packs, and shader packs in one desktop app.',
        'Cut down folder hunting and manual guesswork.',
        'Start with the basics now, then go straight into setup.',
      ],
    );
  }

  Widget _buildFeatureSlide(
    Color accent,
    Color accentAlt,
    String badgeLabel,
  ) {
    return _SlideFrame(
      badgeLabel: badgeLabel,
      headline: 'Built for a faster mod workflow',
      subhead:
          'Melon keeps the most useful actions close so you can spend less time sorting files and more time building your setup.',
      accent: accent,
      accentAlt: accentAlt,
      side: _HeroFeatureVisual(
        accent: accent,
        accentAlt: accentAlt,
      ),
      body: const [
        'Search and install mods, shaders, and resource packs from Modrinth.',
        'Track what came from Modrinth, what was added manually, and what may have updates.',
        'Import, export, drag in local files, and manage your library from one place.',
      ],
    );
  }

  Widget _buildFlowSlide(
    Color accent,
    Color accentAlt,
    String badgeLabel,
  ) {
    return _SlideFrame(
      badgeLabel: badgeLabel,
      headline: 'How Melon works',
      subhead:
          'Melon starts by helping you point to the right Minecraft folder, then it reads the local content already available on your machine.',
      accent: accent,
      accentAlt: accentAlt,
      side: _HeroFlowVisual(
        accent: accent,
        accentAlt: accentAlt,
      ),
      body: const [
        'It can auto-detect common Minecraft instance paths and loaders when available.',
        'After you choose the folder, Melon scans local mods, shader packs, and resource packs already in that instance.',
        'Items linked to Modrinth can be identified more deeply than external manual files.',
      ],
    );
  }

  Widget _buildLimitSlide(
    Color accent,
    Color accentAlt,
    String badgeLabel,
  ) {
    return _SlideFrame(
      badgeLabel: badgeLabel,
      headline: 'What Melon can and cannot do',
      subhead:
          'Melon works with live online services for some features, while local file management stays available on your computer.',
      accent: accent,
      accentAlt: accentAlt,
      side: _HeroLimitVisual(
        accent: accent,
        accentAlt: accentAlt,
      ),
      body: const [
        'Mod browsing, downloads, dependency lookups, and tracked content updates rely on the Modrinth API.',
        'App update checks and developer or repository details rely on GitHub.',
        'Manual files can still be scanned and managed locally, but they cannot always be updated automatically.',
        'Offline use still works for local library scanning, but online browsing and update checks need internet access.',
      ],
    );
  }

  Future<void> _finishFlow() async {
    if (_finishing) {
      return;
    }
    setState(() => _finishing = true);
    if (widget.replayMode) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    await ref.read(appControllerProvider.notifier).completeWelcomeFlow();
    if (mounted) {
      setState(() => _finishing = false);
    }
  }

  Future<void> _goNext() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  double _computeUiScale({required double width, required double height}) {
    const baseWidth = 1280.0;
    const baseHeight = 760.0;
    final widthScale = (width / baseWidth).clamp(0.86, 1.18);
    final heightScale = (height / baseHeight).clamp(0.86, 1.12);
    return widthScale < heightScale ? widthScale : heightScale;
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.currentIndex,
    required this.slideCount,
    required this.replayMode,
    required this.showDebugBadge,
    required this.onClose,
  });

  final int currentIndex;
  final int slideCount;
  final bool replayMode;
  final bool showDebugBadge;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        const MelonLogo(size: 34),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              replayMode ? 'Melon Welcome Guide' : 'First-Time Welcome',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Step ${currentIndex + 1} of $slideCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.64),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (showDebugBadge)
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.34)),
            ),
            child: Text(
              'Debug Preview Enabled',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (onClose != null)
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              foregroundColor: Colors.white.withValues(alpha: 0.86),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.slideCount,
    required this.replayMode,
    required this.busy,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
  });

  final int currentIndex;
  final int slideCount;
  final bool replayMode;
  final bool busy;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isLast = currentIndex == slideCount - 1;

    return Row(
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(
            slideCount,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == currentIndex ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: index == currentIndex
                    ? accent
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const Spacer(),
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton.icon(
              onPressed: busy ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ),
        TextButton(
          onPressed: busy ? null : onSkip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.54),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: Text(replayMode ? 'Close' : 'Skip'),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: busy ? null : onNext,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isLast
                      ? (replayMode
                          ? Icons.check_circle_rounded
                          : Icons.rocket_launch_rounded)
                      : Icons.arrow_forward_rounded,
                ),
          label: Text(isLast ? (replayMode ? 'Done' : 'Start Setup') : 'Next'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(148, 50)),
        ),
      ],
    );
  }
}

class _SlideFrame extends StatelessWidget {
  const _SlideFrame({
    required this.badgeLabel,
    required this.headline,
    required this.subhead,
    required this.body,
    required this.side,
    required this.accent,
    required this.accentAlt,
  });

  final String badgeLabel;
  final String headline;
  final String subhead;
  final List<String> body;
  final Widget side;
  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final headlineSize = compact ? 34.0 : 46.0;
        final textWidget = Flexible(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.only(right: compact ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accentAlt.withValues(alpha: 0.14),
                      ],
                    ),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: headlineSize,
                    fontWeight: FontWeight.w800,
                    height: 0.98,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subhead,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 15.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                for (final line in body) ...[
                  _FeatureLine(accent: accent, text: line),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );

        if (compact) {
          return Column(
            children: [
              Expanded(child: textWidget),
              const SizedBox(height: 16),
              SizedBox(height: 220, child: side),
            ],
          );
        }

        return Row(
          children: [
            textWidget,
            const SizedBox(width: 18),
            Flexible(flex: 5, child: side),
          ],
        );
      },
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.accent,
    required this.text,
  });

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.38),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({
    required this.accent,
    required this.accentAlt,
    required this.child,
  });

  final Color accent;
  final Color accentAlt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: _GlowOrb(size: 140, color: accent.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -28,
            left: -16,
            child:
                _GlowOrb(size: 120, color: accentAlt.withValues(alpha: 0.14)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _HeroWelcomeVisual extends StatelessWidget {
  const _HeroWelcomeVisual({
    required this.accent,
    required this.accentAlt,
  });

  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return _VisualCard(
      accent: accent,
      accentAlt: accentAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Center(child: MelonLogo(size: 122)),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'One desktop home for your Minecraft content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.22,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Mods',
                  icon: Icons.extension_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'Shaders',
                  icon: Icons.auto_awesome_rounded,
                  color: accentAlt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatChip(
            label: 'Resource Packs',
            icon: Icons.layers_rounded,
            color: accent.withValues(alpha: 0.86),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _HeroFeatureVisual extends StatelessWidget {
  const _HeroFeatureVisual({
    required this.accent,
    required this.accentAlt,
  });

  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return _VisualCard(
      accent: accent,
      accentAlt: accentAlt,
      child: Column(
        children: [
          _PanelStrip(
            accent: accent,
            icon: Icons.travel_explore_rounded,
            title: 'Search Modrinth',
            subtitle: 'Find compatible content faster',
          ),
          const SizedBox(height: 12),
          _PanelStrip(
            accent: accentAlt,
            icon: Icons.system_update_alt_rounded,
            title: 'Track updates',
            subtitle: 'See what is current and what is external',
          ),
          const SizedBox(height: 12),
          _PanelStrip(
            accent: accent,
            icon: Icons.upload_file_rounded,
            title: 'Import or drag files',
            subtitle: 'Bring in local jars and zip content',
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _BadgeBlock(
                  accent: accent,
                  icon: Icons.link_rounded,
                  label: 'Tracked',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BadgeBlock(
                  accent: accentAlt,
                  icon: Icons.offline_bolt_rounded,
                  label: 'Local',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFlowVisual extends StatelessWidget {
  const _HeroFlowVisual({
    required this.accent,
    required this.accentAlt,
  });

  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return _VisualCard(
      accent: accent,
      accentAlt: accentAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepPill(
            color: accent,
            icon: Icons.my_location_rounded,
            title: 'Detect path',
          ),
          _FlowConnector(color: accent.withValues(alpha: 0.4)),
          _StepPill(
            color: accentAlt,
            icon: Icons.folder_open_rounded,
            title: 'Scan local content',
          ),
          _FlowConnector(color: accentAlt.withValues(alpha: 0.4)),
          _StepPill(
            color: accent,
            icon: Icons.widgets_rounded,
            title: 'Show library',
          ),
          _FlowConnector(color: accent.withValues(alpha: 0.4)),
          _StepPill(
            color: accentAlt,
            icon: Icons.tips_and_updates_rounded,
            title: 'Track supported updates',
          ),
        ],
      ),
    );
  }
}

class _HeroLimitVisual extends StatelessWidget {
  const _HeroLimitVisual({
    required this.accent,
    required this.accentAlt,
  });

  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return _VisualCard(
      accent: accent,
      accentAlt: accentAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ApiPanel(
            accent: accent,
            title: 'Modrinth API',
            lines: const [
              'Search',
              'Downloads',
              'Dependencies',
              'Tracked updates',
            ],
          ),
          const SizedBox(height: 12),
          _ApiPanel(
            accent: accentAlt,
            title: 'GitHub API',
            lines: const [
              'App updates',
              'Developer profile',
              'Repository info',
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Local scans still work offline. Online content and update checks do not.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelStrip extends StatelessWidget {
  const _PanelStrip({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12.5,
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

class _BadgeBlock extends StatelessWidget {
  const _BadgeBlock({
    required this.accent,
    required this.icon,
    required this.label,
  });

  final Color accent;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.color,
    required this.icon,
    required this.title,
  });

  final Color color;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 20,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: color,
    );
  }
}

class _ApiPanel extends StatelessWidget {
  const _ApiPanel({
    required this.accent,
    required this.title,
    required this.lines,
  });

  final Color accent;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Row(
              children: [
                Icon(Icons.check_rounded, color: accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  line,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

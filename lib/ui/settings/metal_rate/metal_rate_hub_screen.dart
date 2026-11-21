import 'package:flutter/material.dart';

import '../../../logic/setting/metal_rate/metal_rate_controller.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/settings/metal_rate/metal_rate_theme.dart';
import 'metal_rate_app_bar.dart';
import 'metal_rate_detail_screen.dart';
import 'widgets/metal_rate_hub_card.dart';
import 'widgets/metal_rate_hub_intro.dart';

class MetalRateHubScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MetalRateHubScreen({super.key, this.onBack});

  @override
  State<MetalRateHubScreen> createState() => _MetalRateHubScreenState();
}

class _MetalRateHubScreenState extends State<MetalRateHubScreen> {
  late final MetalRateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MetalRateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMetal(MetalRateMetal metal) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MetalRateDetailScreen(
          metal: metal,
          controller: _controller,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: MetalRateColors.bodyBg,
        appBar: MetalRateAppBar(
          screenTitle: MetalRateStrings.hubTitle,
          onBack: widget.onBack ??
              () => Navigator.of(context, rootNavigator: true).maybePop(),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.state == MetalRateLoadState.loading ||
                  _controller.state == MetalRateLoadState.idle) {
                return const Center(
                  child: CircularProgressIndicator(color: MetalRateColors.gold),
                );
              }
              if (_controller.state == MetalRateLoadState.error) {
                return _LoadError(
                  message: _controller.errorMessage ?? 'Unable to load rates.',
                  onRetry: _controller.refresh,
                );
              }

              final profiles = _controller.profiles;
              return RefreshIndicator(
                onRefresh: _controller.refresh,
                color: MetalRateColors.gold,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: MetalRateHubStyles.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MetalRateHubIntro(metalCount: profiles.length),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 1120
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final profile in profiles)
                                SizedBox(
                                  width: width,
                                  child: MetalRateHubCard(
                                    profile: profile,
                                    onTap: () => _openMetal(profile.metal),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                MetalRateIcons.warning,
                color: MetalRateColors.danger,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: MetalRateHubStyles.description,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

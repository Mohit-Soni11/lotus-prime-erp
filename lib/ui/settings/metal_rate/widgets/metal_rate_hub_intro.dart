import 'package:flutter/material.dart';

import '../../../../theme/settings/metal_rate/metal_rate_theme.dart';

class MetalRateHubIntro extends StatelessWidget {
  const MetalRateHubIntro({super.key, required this.metalCount});

  final int metalCount;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: MetalRateStyles.softPanel(MetalRateColors.gold),
          child: const Icon(
            Icons.tune_rounded,
            color: MetalRateColors.gold,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MetalRateStrings.selectMetal,
                style: MetalRateHubStyles.heading,
              ),
              const SizedBox(height: 3),
              Text(
                MetalRateStrings.hubSub,
                style: MetalRateHubStyles.description,
              ),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: MetalRateStyles.softPanel(MetalRateColors.gold),
          child: Text(
            '$metalCount METALS',
            style: MetalRateHubStyles.metricLabel.copyWith(
              color: MetalRateColors.textDark,
            ),
          ),
        );
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 12), count],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            count,
          ],
        );
      },
    );
  }
}

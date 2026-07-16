part of '../stock_summary_screen.dart';

class _StockSummaryBody extends StatelessWidget {
  final StockSummaryController controller;

  const _StockSummaryBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StockSummaryHero(overview: controller.overview),
              const SizedBox(height: 18),
              _StockSummaryMetricGrid(overview: controller.overview),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 11,
                    child: _MetalSummaryPanel(metals: controller.metals),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 9,
                    child: _GradeSummaryPanel(grades: controller.grades),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RecentMovementPanel(records: controller.recentMovements),
            ],
          ),
        ),
        if (controller.isLoading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: InvColors.bodyBg.withValues(alpha: 0.45),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 18),
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: InvColors.brandGold,
                  ),
                ),
              ),
            ),
          ),
        if (controller.errorMessage != null && !controller.isLoading)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _SummaryErrorBanner(message: controller.errorMessage!),
          ),
      ],
    );
  }
}

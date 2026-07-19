part of '../stock_summary_screen.dart';

class _StockSummaryBody extends StatefulWidget {
  final StockSummaryController controller;

  const _StockSummaryBody({super.key, required this.controller});

  @override
  State<_StockSummaryBody> createState() => _StockSummaryBodyState();
}

class _StockSummaryBodyState extends State<_StockSummaryBody> {
  String? _selectedMetal;
  String? _selectedGrade;

  StockSummaryController get controller => widget.controller;

  void _openMetal(String metal) {
    setState(() {
      _selectedMetal = metal;
      _selectedGrade = null;
    });
  }

  void _openGrade(String grade) {
    setState(() => _selectedGrade = grade);
  }

  void _backToMetals() {
    setState(() {
      _selectedMetal = null;
      _selectedGrade = null;
    });
  }

  void _backToGrades() {
    setState(() => _selectedGrade = null);
  }

  bool handleInternalBack() {
    if (_selectedGrade != null) {
      _backToGrades();
      return true;
    }
    if (_selectedMetal != null) {
      _backToMetals();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StockSummaryHero(overview: controller.overview),
                  const SizedBox(height: 18),
                  _StockSummaryMetricGrid(overview: controller.overview),
                  const SizedBox(height: 18),
                  _buildSummaryLevel(),
                  const SizedBox(height: 18),
                  _RecentMovementPanel(records: controller.recentMovements),
                ],
              ),
            );
          },
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

  Widget _buildSummaryLevel() {
    final selectedMetal = _selectedMetal;
    final selectedGrade = _selectedGrade;
    if (selectedMetal == null) {
      return _MetalSummaryPanel(
        metals: controller.metals,
        onOpen: _openMetal,
      );
    }

    final metalGrades = controller.grades
        .where(
          (grade) =>
              grade.metal.trim().toLowerCase() ==
              selectedMetal.trim().toLowerCase(),
        )
        .toList(growable: false);

    if (selectedGrade == null) {
      return _GradeSummaryPanel(
        title: '$selectedMetal Grade Summary',
        subtitle:
            'Opening, inward, outward and closing stock grouped by purity grade.',
        grades: metalGrades,
        onBack: _backToMetals,
        onOpen: _openGrade,
      );
    }

    final gradeItems = controller.items
        .where(
          (item) =>
              item.metal.trim().toLowerCase() ==
                  selectedMetal.trim().toLowerCase() &&
              item.gradeLabel.trim().toLowerCase() ==
                  selectedGrade.trim().toLowerCase(),
        )
        .toList(growable: false);

    return _ItemSummaryPanel(
      title: '$selectedGrade Item Summary',
      subtitle:
          'Available item-wise stock for $selectedMetal with sold and closing weight.',
      items: gradeItems,
      onBack: _backToGrades,
    );
  }
}

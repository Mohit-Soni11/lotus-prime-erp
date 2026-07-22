part of '../stock_summary_screen.dart';

class _SummaryPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Widget child;

  const _SummaryPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DDC9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryIconBox(icon: icon, accent: InvColors.brandGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PanelActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DDC9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: InvColors.textDark),
              const SizedBox(width: 8),
              Text(label, style: _summaryStrongStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;

  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 292,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(icon: icon, accent: accent),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _summaryMutedStyle()),
                const SizedBox(height: 4),
                Text(value, style: _summaryStrongStyle(fontSize: 20)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryMutedStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _HeroSummaryTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _summaryMutedStyle(fontSize: 10)),
          const SizedBox(height: 5),
          Text(value, style: _summaryStrongStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _BlockMetric extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;

  const _BlockMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _summaryMutedStyle(fontSize: 10.5)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryStrongStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InlineMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _summaryMutedStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _summaryStrongStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _FooterMetric({
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _summaryMutedStyle(fontSize: 10.5)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _summaryStrongStyle(fontSize: 12.5).copyWith(
            color: accent ?? InvColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFEADCC5),
    );
  }
}

class _SummaryIconBox extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _SummaryIconBox({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: 21),
    );
  }
}

class _SummaryEmptyState extends StatelessWidget {
  final String message;

  const _SummaryEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: _summaryMutedStyle(),
      ),
    );
  }
}

class _SummaryErrorBanner extends StatelessWidget {
  final String message;

  const _SummaryErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: InvColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: InvColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _summaryStrongStyle({double fontSize = 14}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w900,
    color: InvColors.textDark,
  );
}

TextStyle _summaryMutedStyle({double fontSize = 12}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: InvColors.textMuted,
  );
}

String _summaryWeight(double value) => _summaryWeightFormat.format(value);

String _summaryDate(DateTime? value) {
  if (value == null) return 'Not recorded';
  return _summaryDateFormat.format(value);
}

String _fallback(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value.trim();
}

String _itemSubtitle(StockSummaryItem item) {
  final companyCount =
      item.companyNames.isEmpty ? item.companyCount : item.companyNames.length;
  final companyText = companyCount <= 0
      ? 'company not tagged'
      : companyCount == 1
          ? '1 company'
          : '$companyCount companies';
  final purityText = item.purityGroupCount <= 0
      ? 'purity not tagged'
      : item.purityGroupCount == 1
          ? '1 purity group'
          : '${item.purityGroupCount} purity groups';
  final sets = item.totalSets > 0
      ? ' | ${item.availableSets}/${item.totalSets} set'
      : '';
  return '${_fallback(item.itemType, 'General')} | ${_fallback(item.segment, 'General')} | $companyText | $purityText$sets';
}

String _titleCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Stock Item';
  return text.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

StockCategory _stockCategoryFromMetal(String metal) {
  switch (metal.trim().toLowerCase()) {
    case 'gold':
      return StockCategory.gold;
    case 'silver':
      return StockCategory.silver;
    case 'diamond':
      return StockCategory.diamond;
    case 'platinum':
      return StockCategory.platinum;
    default:
      return StockCategory.other;
  }
}

part of '../girvi_account_detail_screen.dart';

class _AccountBalanceLine {
  const _AccountBalanceLine(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.lines = const [],
    this.note,
    this.compact = false,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final List<_AccountBalanceLine> lines;
  final String? note;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 156 : 214),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AccountIconBox(icon: icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: GoogleFonts.inter(
                color: GirviColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: GirviColors.cardBorder),
            const SizedBox(height: 10),
            for (var index = 0; index < lines.length; index++) ...[
              if (index > 0) const SizedBox(height: 7),
              _AccountBalanceDetailRow(line: lines[index]),
            ],
          ],
        ],
      ),
    );
  }
}

class _AccountBalanceDetailRow extends StatelessWidget {
  const _AccountBalanceDetailRow({required this.line});

  final _AccountBalanceLine line;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            line.label,
            style: GoogleFonts.inter(
              color: line.color ?? GirviColors.textBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          line.value,
          style: GoogleFonts.inter(
            color: line.color ?? GirviColors.textDark,
            fontSize: 12.8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

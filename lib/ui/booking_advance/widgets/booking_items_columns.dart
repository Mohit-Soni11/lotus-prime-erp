part of '../booking_items_table.dart';

class _BookingItemsColumnRow extends StatelessWidget {
  const _BookingItemsColumnRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BookingItemGridMetrics.horizontalPadding,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        border: Border(
          bottom: BorderSide(
            color: BookingAdvanceColors.bodyBorder,
            width: 1.5,
          ),
        ),
      ),
      child: const Row(
        children: [
          _HeaderCell('S.NO', BookingItemGridMetrics.serial, center: true),
          SizedBox(width: 6),
          _HeaderCell('METAL', BookingItemGridMetrics.metal),
          SizedBox(width: 6),
          _HeaderCell('DESCRIPTION', BookingItemGridMetrics.description),
          SizedBox(width: 6),
          _HeaderCell('PCS', BookingItemGridMetrics.pieces, center: true),
          SizedBox(width: 6),
          _HeaderCell('PURITY', BookingItemGridMetrics.purity, center: true),
          SizedBox(width: 6),
          _HeaderCell(
            'GR. WT',
            BookingItemGridMetrics.grossWeight,
            center: true,
          ),
          SizedBox(width: 6),
          _HeaderCell('LESS', BookingItemGridMetrics.lessWeight, center: true),
          SizedBox(width: 6),
          _HeaderCell('NET WT', BookingItemGridMetrics.netWeight, center: true),
          SizedBox(width: 6),
          _HeaderCell('RATE', BookingItemGridMetrics.rate, right: true),
          SizedBox(width: 6),
          _HeaderCell('MAKING', BookingItemGridMetrics.making, center: true),
          SizedBox(width: 6),
          _HeaderCell('TOTAL', BookingItemGridMetrics.total, right: true),
          SizedBox(width: 6),
          _HeaderCell(
            'DELIVERY',
            BookingItemGridMetrics.deliveryDate,
            center: true,
          ),
          SizedBox(width: 6),
          _HeaderCell('ACT', BookingItemGridMetrics.action, center: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text,
    this.width, {
    this.right = false,
    this.center = false,
  });

  final String text;
  final double width;
  final bool right;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: BookingAdvanceColors.textDark,
          letterSpacing: 0.4,
          height: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

part of '../girvi_account_detail_screen.dart';

class _AccountLifecycleItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _AccountLifecycleItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}

class _AccountLifecycleRail extends StatelessWidget {
  final List<_AccountLifecycleItem> items;

  const _AccountLifecycleRail({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: stacked
              ? Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _AccountLifecycleCell(item: items[index]),
                      if (index != items.length - 1)
                        const Divider(
                          height: 1,
                          color: GirviColors.cardBorder,
                        ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(
                        child: _AccountLifecycleCell(item: items[index]),
                      ),
                      if (index != items.length - 1)
                        Container(
                          width: 1,
                          height: 58,
                          color: GirviColors.cardBorder,
                        ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _AccountLifecycleCell extends StatelessWidget {
  final _AccountLifecycleItem item;

  const _AccountLifecycleCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: item.color.withValues(alpha: 0.16)),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: item.color,
                    fontSize: 14.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: GirviColors.textBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

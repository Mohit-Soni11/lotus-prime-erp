part of 'defaulter_data_table.dart';

class _AccountIdentity extends StatelessWidget {
  final DefaulterModel account;
  final bool mobileVisible;
  final VoidCallback onRevealMobile;

  const _AccountIdentity({
    required this.account,
    required this.mobileVisible,
    required this.onRevealMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: account.customerName, level: account.riskLevel),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      account.referenceNo,
                      style: DefaulterStyles.refNumber.copyWith(
                        color: DefaulterColors.brandGoldDark,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: _RiskBadge(level: account.riskLevel)),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                account.customerName,
                style: DefaulterStyles.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: DefaulterIcons.phoneCall,
                    label: mobileVisible ? account.mobile : 'Show mobile',
                    onTap: onRevealMobile,
                    tooltip: mobileVisible
                        ? 'Mobile number'
                        : 'Click to show mobile number',
                  ),
                  _InfoChip(
                    icon: DefaulterIcons.cityPin,
                    label: account.city,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _itemSummary(account),
                style: DefaulterStyles.customerCity.copyWith(
                  color: DefaulterColors.bodyTextMain,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                account.address,
                style: DefaulterStyles.customerCity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _itemSummary(DefaulterModel account) {
    final itemCount = account.pledgedItemCount <= 1
        ? '1 item'
        : '${account.pledgedItemCount} items';
    return '$itemCount - ${account.itemName} - ${account.metalType} ${account.purity} - ${account.netWeight.toStringAsFixed(3)} g';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final DefaulterRiskLevel level;

  const _Avatar({
    required this.name,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final config = _riskConfig(level);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.border.withValues(alpha: 0.55)),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: config.text,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

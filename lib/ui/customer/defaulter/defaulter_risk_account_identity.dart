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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 5,
                children: [
                  Text(
                    account.referenceNo,
                    style: DefaulterStyles.refNumber.copyWith(
                      color: DefaulterColors.brandGoldDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  account.isRecoverySettled
                      ? _RecoveryClosedBadge(
                          disposition: account.recoveryDispositionStatus,
                        )
                      : account.isNoticeFollowUpActionDue
                          ? const _FollowUpDueBadge()
                          : account.isNoticeFollowUpMonitoring
                              ? const _PromiseMonitoringBadge()
                              : _RiskBadge(
                                  level: account.riskLevel,
                                  label: account.riskLevel ==
                                              DefaulterRiskLevel.medium &&
                                          !account.isPaymentMonitoring
                                      ? 'WATCHLIST'
                                      : null,
                                ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                account.customerName,
                style: DefaulterStyles.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _itemSummary(account),
                style: DefaulterStyles.customerCity.copyWith(
                  color: DefaulterColors.bodyTextMain,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: DefaulterIcons.phoneCall,
                    label: mobileVisible ? account.mobile : 'Show mobile',
                    onTap: mobileVisible ? null : onRevealMobile,
                    tooltip:
                        mobileVisible ? null : 'Show customer mobile number',
                  ),
                  if (account.city.trim().isNotEmpty)
                    _InfoChip(
                      icon: DefaulterIcons.cityPin,
                      label: account.city,
                    ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: account.isRecoverySettled &&
                            account.recoverySettledAt != null
                        ? 'Closed ${DateFormat('dd MMM yyyy').format(account.recoverySettledAt!)}'
                        : account.riskAgeLabel,
                  ),
                  if (account.isRecoverySettled &&
                      account.recoveryDispositionStatus != null)
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: switch (account.recoveryDispositionStatus) {
                        'MELTED' => 'Item melted',
                        'SOLD' => 'Item sold',
                        _ => 'Item recovered',
                      },
                    ),
                  if (!account.isRecoverySettled &&
                      account.noticePromisedDate != null)
                    _InfoChip(
                      icon: Icons.event_available_rounded,
                      label:
                          '${account.noticeFollowUpKind == GirviCustomerResponseKind.willVisit ? 'Visit promised' : 'More time until'} ${DateFormat('dd MMM yyyy').format(account.noticePromisedDate!)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _itemSummary(DefaulterModel account) {
    final count = account.pledgedItemCount;
    final countLabel = count == 1 ? '1 item' : '$count items';
    return '$countLabel · ${account.itemName} · '
        '${account.metalType} ${account.purity} · '
        '${account.netWeight.toStringAsFixed(3)} g';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final DefaulterRiskLevel level;

  const _Avatar({required this.name, required this.level});

  @override
  Widget build(BuildContext context) {
    final config = _riskConfig(level);
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = name.trim().isEmpty
        ? '?'
        : parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : parts.first[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: config.border.withValues(alpha: 0.55)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: config.text,
        ),
      ),
    );
  }
}

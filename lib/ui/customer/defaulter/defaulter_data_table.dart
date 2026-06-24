// =============================================================================
// FILE        : defaulter_data_table.dart
// MODULE      : Risk & Collections
// DESCRIPTION : Premium collection queue for live Girvi risk accounts.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../logic/customer/defaulter_logic.dart';
import '../../../models/customer/defaulter_model.dart';
import '../../../theme/customer/defaulter/defaulter_theme.dart';

class DefaulterDataTable extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<DefaulterModel> onOpenAccount;
  final ValueChanged<DefaulterModel> onOpenInterestEntry;
  final ValueChanged<DefaulterModel> onOpenNoticeAuction;

  const DefaulterDataTable({
    super.key,
    required this.defaulters,
    required this.isLoading,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenNoticeAuction,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Container(
        decoration: DefaulterStyles.tableContainerDecoration,
        child: Column(
          children: [
            _QueueHeader(count: defaulters.length),
            Expanded(
              child: _QueueBody(
                defaulters: defaulters,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onOpenAccount: onOpenAccount,
                onOpenInterestEntry: onOpenInterestEntry,
                onOpenNoticeAuction: onOpenNoticeAuction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final int count;

  const _QueueHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: DefaulterStyles.tableHeaderDecoration,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DefaulterColors.brandGoldLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DefaulterColors.brandGold.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              DefaulterIcons.defaulterShield,
              size: 18,
              color: DefaulterColors.brandGoldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection Queue',
                  style: DefaulterStyles.customerName.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count live Girvi account${count == 1 ? '' : 's'} requiring control',
                  style: DefaulterStyles.customerCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const _HeaderBadge(label: 'Live Risk View'),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;

  const _HeaderBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DefaulterColors.shellBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: DefaulterStyles.riskBadgeText.copyWith(
          color: DefaulterColors.shellTextTitle,
        ),
      ),
    );
  }
}

class _QueueBody extends StatelessWidget {
  final List<DefaulterModel> defaulters;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<DefaulterModel> onOpenAccount;
  final ValueChanged<DefaulterModel> onOpenInterestEntry;
  final ValueChanged<DefaulterModel> onOpenNoticeAuction;

  const _QueueBody({
    required this.defaulters,
    required this.isLoading,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenNoticeAuction,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _ShimmerRows();
    if (errorMessage != null) return _ErrorState(message: errorMessage!);
    if (defaulters.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: defaulters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = defaulters[index];
        return _RiskAccountCard(
          key: ValueKey(account.loanId),
          account: account,
          onOpenAccount: () => onOpenAccount(account),
          onOpenInterestEntry: () => onOpenInterestEntry(account),
          onOpenNoticeAuction: () => onOpenNoticeAuction(account),
        );
      },
    );
  }
}

class _RiskAccountCard extends StatefulWidget {
  final DefaulterModel account;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInterestEntry;
  final VoidCallback onOpenNoticeAuction;

  const _RiskAccountCard({
    super.key,
    required this.account,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenNoticeAuction,
  });

  @override
  State<_RiskAccountCard> createState() => _RiskAccountCardState();
}

class _RiskAccountCardState extends State<_RiskAccountCard> {
  bool _hovered = false;
  bool _mobileVisible = false;

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? DefaulterColors.riskCardHoverBg
              : DefaulterColors.riskCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _riskBorder(account.riskLevel).withValues(
              alpha: _hovered ? 0.70 : 0.38,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? DefaulterColors.shadowMedium
                  : DefaulterColors.shadowLight,
              blurRadius: _hovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: _riskBorder(account.riskLevel).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AccountIdentity(
                    account: account,
                    dateFmt: _dateFmt,
                    mobileVisible: _mobileVisible,
                    onRevealMobile: _revealMobile,
                  ),
                  const SizedBox(height: 12),
                  _AccountMetrics(account: account),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _AccountActions(
                      account: account,
                      onOpenAccount: widget.onOpenAccount,
                      onOpenInterestEntry: widget.onOpenInterestEntry,
                      onOpenNoticeAuction: widget.onOpenNoticeAuction,
                      onRevealMobile: _revealMobile,
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _AccountIdentity(
                    account: account,
                    dateFmt: _dateFmt,
                    mobileVisible: _mobileVisible,
                    onRevealMobile: _revealMobile,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 7,
                  child: _AccountMetrics(account: account),
                ),
                const SizedBox(width: 14),
                _AccountActions(
                  account: account,
                  onOpenAccount: widget.onOpenAccount,
                  onOpenInterestEntry: widget.onOpenInterestEntry,
                  onOpenNoticeAuction: widget.onOpenNoticeAuction,
                  onRevealMobile: _revealMobile,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _riskBorder(DefaulterRiskLevel level) {
    switch (level) {
      case DefaulterRiskLevel.critical:
        return DefaulterColors.riskCriticalBorder;
      case DefaulterRiskLevel.high:
        return DefaulterColors.riskHighBorder;
      case DefaulterRiskLevel.medium:
        return DefaulterColors.riskMediumBorder;
      case DefaulterRiskLevel.low:
        return DefaulterColors.riskLowBorder;
    }
  }

  void _revealMobile() async {
    await Clipboard.setData(ClipboardData(text: widget.account.mobile));
    if (!mounted) return;
    if (_mobileVisible) return;
    setState(() => _mobileVisible = true);
  }
}

class _AccountIdentity extends StatelessWidget {
  final DefaulterModel account;
  final DateFormat dateFmt;
  final bool mobileVisible;
  final VoidCallback onRevealMobile;

  const _AccountIdentity({
    required this.account,
    required this.dateFmt,
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
                  Expanded(
                    child: Text(
                      account.customerName,
                      style: DefaulterStyles.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RiskBadge(level: account.riskLevel),
                ],
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: DefaulterIcons.loanTag,
                    label: account.referenceNo,
                  ),
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
              const SizedBox(height: 10),
              _PledgedItemStrip(account: account),
              const SizedBox(height: 5),
              Text(
                account.address,
                style: DefaulterStyles.customerCity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusPill(label: account.statusLabel),
                  _TinyMeta(
                    icon: DefaulterIcons.calendar,
                    label:
                        'Maturity ${account.maturityDate == null ? 'Not set' : dateFmt.format(account.maturityDate!)}',
                  ),
                  _TinyMeta(
                    icon: DefaulterIcons.trending,
                    label:
                        'Last activity ${dateFmt.format(account.lastActivityAt)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PledgedItemStrip extends StatelessWidget {
  final DefaulterModel account;

  const _PledgedItemStrip({required this.account});

  @override
  Widget build(BuildContext context) {
    final tokens = <Widget>[
      _ItemDetailToken(label: 'Item', value: account.itemName, prominent: true),
      if (account.pledgedItemCount > 1)
        _ItemDetailToken(label: 'Items', value: '${account.pledgedItemCount}'),
      _ItemDetailToken(label: 'Metal', value: account.metalType),
      _ItemDetailToken(label: 'Purity', value: account.purity),
      _ItemDetailToken(label: 'Pieces', value: '${account.pieces} pcs'),
      _ItemDetailToken(label: 'Gross Wt', value: _weight(account.grossWeight)),
      if (account.lessWeight > 0.001)
        _ItemDetailToken(label: 'Less Wt', value: _weight(account.lessWeight)),
      _ItemDetailToken(
        label: 'Net Wt',
        value: _weight(account.netWeight),
        prominent: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: DefaulterColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DefaulterColors.bodyBorder),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tokens,
      ),
    );
  }

  String _weight(double value) => '${value.toStringAsFixed(3)} g';
}

class _ItemDetailToken extends StatelessWidget {
  final String label;
  final String value;
  final bool prominent;

  const _ItemDetailToken({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: prominent
            ? DefaulterColors.brandGoldLight
            : DefaulterColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: prominent
              ? DefaulterColors.brandGold.withValues(alpha: 0.45)
              : DefaulterColors.bodyBorder,
        ),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: DefaulterStyles.customerCity.copyWith(
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
                color: DefaulterColors.bodyTextHint,
              ),
            ),
            TextSpan(
              text: value,
              style: DefaulterStyles.refNumber.copyWith(
                fontSize: 12.2,
                color: prominent
                    ? DefaulterColors.brandGoldDark
                    : DefaulterColors.bodyTextMain,
              ),
            ),
          ],
        ),
      ),
    );
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

class _AccountMetrics extends StatelessWidget {
  final DefaulterModel account;

  const _AccountMetrics({required this.account});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetricTile(
          label: 'Principal Due',
          value: DefaulterLogic.formatAmountCompact(
            account.principalOutstanding,
          ),
          color: DefaulterColors.statPrincipalText,
        ),
        _MetricTile(
          label: 'Interest Due',
          value: DefaulterLogic.formatAmountCompact(
            account.interestOutstanding,
          ),
          color: DefaulterColors.riskHighText,
          subLabel: '${account.interestRate.toStringAsFixed(2)}% monthly',
        ),
        _MetricTile(
          label: 'Total Payable',
          value: DefaulterLogic.formatAmountCompact(account.totalDue),
          color: DefaulterColors.riskCriticalText,
        ),
        _MetricTile(
          label: 'Risk Age',
          value: account.riskAgeLabel,
          color: _riskConfig(account.riskLevel).text,
          subLabel: account.collectionStage,
        ),
        _MetricTile(
          label: 'Collected',
          value: DefaulterLogic.formatAmountCompact(account.totalReceived),
          color: DefaulterColors.statReceivedText,
          subLabel:
              account.hasPaymentHistory ? 'Payment history' : 'No payment',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DefaulterColors.riskMetricBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DefaulterColors.riskMetricBorder),
        boxShadow: const [
          BoxShadow(
            color: DefaulterColors.shadowLight,
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DefaulterStyles.customerCity.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: DefaulterStyles.amountText.copyWith(color: color),
              maxLines: 1,
            ),
          ),
          Text(
            subLabel ?? '',
            style: DefaulterStyles.interestRate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatefulWidget {
  final DefaulterModel account;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInterestEntry;
  final VoidCallback onOpenNoticeAuction;
  final VoidCallback onRevealMobile;

  const _AccountActions({
    required this.account,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenNoticeAuction,
    required this.onRevealMobile,
  });

  @override
  State<_AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<_AccountActions> {
  static final DateFormat _noticeDateFmt = DateFormat('dd MMMM yyyy');

  String? _inlineFeedback;
  Color _feedbackColor = DefaulterColors.statReceivedText;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return SizedBox(
      width: 182,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            icon: DefaulterIcons.openAccount,
            label: DefaulterStrings.btnView,
            color: DefaulterColors.shellBg,
            onTap: widget.onOpenAccount,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: DefaulterIcons.collectInterest,
            label: DefaulterStrings.btnInterest,
            color: DefaulterColors.brandGoldDark,
            onTap: widget.onOpenInterestEntry,
          ),
          if (account.riskLevel == DefaulterRiskLevel.critical) ...[
            const SizedBox(height: 8),
            _ActionButton(
              icon: DefaulterIcons.defaulterAlert,
              label: 'Notice Review',
              color: DefaulterColors.riskCriticalText,
              onTap: widget.onOpenNoticeAuction,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IconActionButton(
                  icon: DefaulterIcons.phoneCall,
                  tooltip: DefaulterStrings.btnCall,
                  color: DefaulterColors.callBtnBg,
                  onTap: _showMobile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IconActionButton(
                  icon: DefaulterIcons.notify,
                  tooltip: DefaulterStrings.btnNotify,
                  color: DefaulterColors.notifyBtnBg,
                  onTap: _copyNotice,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _inlineFeedback == null
                ? const SizedBox(height: 10)
                : Padding(
                    key: ValueKey(_inlineFeedback),
                    padding: const EdgeInsets.only(top: 8),
                    child: _InlineActionFeedback(
                      label: _inlineFeedback!,
                      color: _feedbackColor,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            account.nextActionLabel,
            style: DefaulterStyles.customerCity.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMobile() {
    widget.onRevealMobile();
    setState(() {
      _feedbackColor = DefaulterColors.callBtnBg;
      _inlineFeedback = 'Mobile number shown above and copied.';
    });
  }

  Future<void> _copyNotice() async {
    final account = widget.account;
    final notice = _buildNoticeMessage(account);
    await Clipboard.setData(ClipboardData(text: notice));
    if (!mounted) return;
    setState(() {
      _feedbackColor = DefaulterColors.notifyBtnBg;
      _inlineFeedback = 'Professional payment reminder copied.';
    });
  }

  String _buildNoticeMessage(DefaulterModel account) {
    final due = DefaulterLogic.formatAmountCompact(account.totalDue);
    final principal =
        DefaulterLogic.formatAmountCompact(account.principalOutstanding);
    final interest =
        DefaulterLogic.formatAmountCompact(account.interestOutstanding);
    final pieceLabel = account.pieces == 1 ? 'piece' : 'pieces';

    return [
      'Subject: Girvi Payment Reminder',
      '',
      'Dear ${account.customerName},',
      '',
      'This is a formal payment reminder for your Girvi account. Please review the account details below and clear the pending amount at the earliest.',
      '',
      'Ticket Number: ${account.referenceNo}',
      'Pledged Item: ${account.itemName}',
      'Metal Type: ${account.metalType}',
      'Purity: ${account.purity}',
      'Pieces: ${account.pieces} $pieceLabel',
      'Net Weight: ${account.netWeight.toStringAsFixed(3)} grams',
      '',
      'Total Payable: $due',
      'Principal Outstanding: $principal',
      'Interest Outstanding: $interest',
      'Monthly Interest Rate: ${account.interestRate.toStringAsFixed(2)} percent per month',
      '',
      'Collection Status: ${account.collectionStage}',
      'Risk Age: ${account.riskAgeFullLabel}',
      'Last Activity Date: ${_noticeDateFmt.format(account.lastActivityAt)}',
      '',
      'Please visit the store or contact us to regularise this account.',
      '',
      'Thank you.',
    ].join('\n');
  }
}

class _InlineActionFeedback extends StatelessWidget {
  final String label;
  final Color color;

  const _InlineActionFeedback({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: DefaulterStyles.customerCity.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: DefaulterColors.bodyTextMain,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DefaulterColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DefaulterColors.bodyBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DefaulterColors.bodyTextMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              style: DefaulterStyles.customerMobile.copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    final clickable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
    if (tooltip == null) return clickable;
    return Tooltip(message: tooltip!, child: clickable);
  }
}

class _TinyMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyMeta({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: DefaulterColors.bodyTextHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: DefaulterStyles.customerCity.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final isPending = label.toLowerCase().contains('settlement');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPending
            ? DefaulterColors.riskHighBg
            : DefaulterColors.riskCriticalBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPending
              ? DefaulterColors.riskHighBorder
              : DefaulterColors.riskCriticalBorder,
        ),
      ),
      child: Text(
        label,
        style: DefaulterStyles.riskBadgeText.copyWith(
          color: isPending
              ? DefaulterColors.riskHighText
              : DefaulterColors.riskCriticalText,
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final DefaulterRiskLevel level;

  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final config = _riskConfig(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.dot,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: DefaulterStyles.riskBadgeText.copyWith(color: config.text),
          ),
        ],
      ),
    );
  }
}

_RiskConfig _riskConfig(DefaulterRiskLevel level) {
  switch (level) {
    case DefaulterRiskLevel.critical:
      return const _RiskConfig(
        label: DefaulterStrings.riskCritical,
        bg: DefaulterColors.riskCriticalBg,
        border: DefaulterColors.riskCriticalBorder,
        text: DefaulterColors.riskCriticalText,
        dot: DefaulterColors.riskCriticalDot,
      );
    case DefaulterRiskLevel.high:
      return const _RiskConfig(
        label: DefaulterStrings.riskHigh,
        bg: DefaulterColors.riskHighBg,
        border: DefaulterColors.riskHighBorder,
        text: DefaulterColors.riskHighText,
        dot: DefaulterColors.riskHighDot,
      );
    case DefaulterRiskLevel.medium:
      return const _RiskConfig(
        label: DefaulterStrings.riskMedium,
        bg: DefaulterColors.riskMediumBg,
        border: DefaulterColors.riskMediumBorder,
        text: DefaulterColors.riskMediumText,
        dot: DefaulterColors.riskMediumDot,
      );
    case DefaulterRiskLevel.low:
      return const _RiskConfig(
        label: DefaulterStrings.riskLow,
        bg: DefaulterColors.riskLowBg,
        border: DefaulterColors.riskLowBorder,
        text: DefaulterColors.riskLowText,
        dot: DefaulterColors.riskLowDot,
      );
  }
}

class _RiskConfig {
  final String label;
  final Color bg;
  final Color border;
  final Color text;
  final Color dot;

  const _RiskConfig({
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
    required this.dot,
  });
}

class _ShimmerRows extends StatelessWidget {
  const _ShimmerRows();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 134,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: DefaulterColors.riskLowBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              DefaulterIcons.emptyState,
              size: 38,
              color: DefaulterColors.riskLowText,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            DefaulterStrings.emptyTitle,
            style: DefaulterStyles.emptyTitle,
          ),
          const SizedBox(height: 8),
          const Text(
            DefaulterStrings.emptySubtitle,
            style: DefaulterStyles.emptySubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: DefaulterColors.riskCriticalText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: DefaulterStyles.emptyTitle.copyWith(
              color: DefaulterColors.riskCriticalText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

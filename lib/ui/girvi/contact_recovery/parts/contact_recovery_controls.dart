part of '../contact_recovery_screen.dart';

class _ContactRecoveryControls extends StatelessWidget {
  final ContactRecoveryState state;
  final TextEditingController searchController;
  final ValueChanged<ContactRecoveryFilter> onFilterChanged;

  const _ContactRecoveryControls({
    required this.state,
    required this.searchController,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: GirviStyles.caption,
            decoration: InputDecoration(
              hintText:
                  'Search customer, mobile, invoice, item or recovery status',
              hintStyle:
                  GirviStyles.caption.copyWith(color: GirviColors.textHint),
              filled: true,
              fillColor: GirviColors.cardBg,
              prefixIcon: const Icon(GirviIcons.search, size: 19),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: GirviColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: GirviColors.brandGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContactRecoveryFilter.values
                  .map(
                    (filter) => _FilterChip(
                      label: _labelFor(filter),
                      count: state.countForFilter(filter),
                      active: state.filter == filter,
                      onTap: () => onFilterChanged(filter),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(ContactRecoveryFilter filter) {
    switch (filter) {
      case ContactRecoveryFilter.all:
        return 'Notice Queue';
      case ContactRecoveryFilter.firstNotice:
        return 'First Notice';
      case ContactRecoveryFilter.secondNotice:
        return 'Second Notice';
      case ContactRecoveryFilter.finalNotice:
        return 'Final Notice';
      case ContactRecoveryFilter.disposalReady:
        return 'Recovery Approval';
      case ContactRecoveryFilter.recoveryInProgress:
        return 'Collateral Recovery';
      case ContactRecoveryFilter.settled:
        return 'Closed';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? GirviColors.shellBg : GirviColors.cardBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? GirviColors.shellBg : GirviColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: active ? Colors.white : GirviColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.16)
                    : GirviColors.bodyBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.22)
                      : GirviColors.cardBorder,
                ),
              ),
              child: Text(
                count.toString(),
                style: GirviStyles.caption.copyWith(
                  fontSize: 12.5,
                  color: active ? Colors.white : GirviColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InlineMessage({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.infoBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.info.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(GirviIcons.info, size: 18, color: GirviColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GirviStyles.caption.copyWith(fontSize: 12.5),
              ),
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

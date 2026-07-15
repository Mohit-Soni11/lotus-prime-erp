part of '../../inventory_screen.dart';

class _InventoryBatchCleanupDialog extends StatelessWidget {
  final String batchCode;
  final Future<void> Function() onCleanupConfirmed;

  const _InventoryBatchCleanupDialog({
    required this.batchCode,
    required this.onCleanupConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final service = InventoryBatchCleanupService(AppDatabase());
    return FutureBuilder<InventoryBatchCleanupAudit>(
      future: service.auditBatch(batchCode),
      builder: (context, snapshot) {
        final audit = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: InvColors.dangerBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: InvColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safe Test Batch Cleanup',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: InvColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      batchCode,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: InvColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: InvColors.brandGold,
                        strokeWidth: 2.4,
                      ),
                    ),
                  )
                : audit == null
                    ? const _CleanupAuditMessage(
                        icon: Icons.error_outline_rounded,
                        color: InvColors.danger,
                        title: 'Audit Failed',
                        message:
                            'Batch safety details could not be loaded right now.',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _CleanupAuditMetric(
                                label: 'Total Units',
                                value: audit.totalUnits.toString(),
                                accent: InvColors.brandGold,
                              ),
                              _CleanupAuditMetric(
                                label: 'Available',
                                value: audit.availableUnits.toString(),
                                accent: InvColors.success,
                              ),
                              _CleanupAuditMetric(
                                label: 'Locked / Sold',
                                value: audit.nonAvailableUnits.toString(),
                                accent: InvColors.danger,
                              ),
                              _CleanupAuditMetric(
                                label: 'Sales Links',
                                value:
                                    '${audit.linkedSalesRows + audit.saleMovements}',
                                accent: InvColors.danger,
                              ),
                              _CleanupAuditMetric(
                                label: 'Finance Links',
                                value:
                                    '${audit.cashEntries + audit.bankEntries}',
                                accent: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (audit.canDelete)
                            const _CleanupAuditMessage(
                              icon: Icons.verified_rounded,
                              color: InvColors.success,
                              title: 'Safe To Clean',
                              message:
                                  'This looks like an unsold test batch. Cleanup will remove stock and voucher records, and void auto finance entries.',
                            )
                          else
                            _CleanupBlockerList(blockers: audit.blockers),
                        ],
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: InvColors.textMuted,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: loading || audit == null || !audit.canDelete
                  ? null
                  : onCleanupConfirmed,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                'Clean Test Batch',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: InvColors.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: InvColors.textMuted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CleanupAuditMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _CleanupAuditMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: InvColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanupAuditMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _CleanupAuditMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: InvColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: InvColors.textMuted,
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

class _CleanupBlockerList extends StatelessWidget {
  final List<String> blockers;

  const _CleanupBlockerList({required this.blockers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvColors.dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvColors.danger.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleanup Blocked',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: InvColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final blocker in blockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.block_rounded,
                    color: InvColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blocker,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: InvColors.textDark,
                      ),
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

part of '../contact_recovery_screen.dart';

class _CustomerResponseTimelineDialog extends StatelessWidget {
  const _CustomerResponseTimelineDialog({
    required this.item,
    required this.onResolveFollowUp,
  });

  final ContactRecoveryCase item;
  final Future<bool> Function({
    required GirviCustomerResponse response,
    required GirviPromiseStatus status,
    String? resolutionNote,
  }) onResolveFollowUp;

  @override
  Widget build(BuildContext context) {
    final responses = [...item.responseTimeline]
      ..sort((left, right) => right.receivedAt.compareTo(left.receivedAt));
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 6),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Response Timeline',
                  style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.loan.ticketNo} · factual contact and promise record',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: GirviColors.textDark,
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: responses.isEmpty
            ? _ResponseTimelineEmptyState()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: responses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CustomerResponseTimelineCard(
                    response: responses[index],
                    onResolve: responses[index].status.isOpen
                        ? () async {
                            final result =
                                await showDialog<_FollowUpResolutionResult>(
                              context: context,
                              builder: (context) => _FollowUpResolutionDialog(
                                response: responses[index],
                              ),
                            );
                            if (result == null || !context.mounted) return;
                            final updated = await onResolveFollowUp(
                              response: responses[index],
                              status: result.status,
                              resolutionNote: result.note,
                            );
                            if (updated && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: GirviColors.textDark,
            backgroundColor: GirviColors.inputBgLocked,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ResponseTimelineEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              color: GirviColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              'No customer response recorded yet.',
              style: GirviStyles.caption.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Record a factual response from the notice document card.',
              textAlign: TextAlign.center,
              style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
            ),
          ],
        ),
      );
}

class _CustomerResponseTimelineCard extends StatelessWidget {
  const _CustomerResponseTimelineCard({
    required this.response,
    required this.onResolve,
  });

  final GirviCustomerResponse response;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final isPastDue =
        response.requiresFollowUpDate && response.isDueOn(DateTime.now());
    final statusColor = isPastDue
        ? GirviColors.danger
        : response.status.isOpen
            ? GirviColors.brandGold
            : GirviColors.success;
    final statusLabel =
        isPastDue ? 'Follow-up date passed' : response.status.label;
    final stageLabel = response.noticeStage == null
        ? 'General account contact'
        : 'Response to approved notice';
    final details = <String>[
      '${response.channel.label} · ${DateFormat('dd MMM yyyy, hh:mm a').format(response.receivedAt)}',
      if (response.promiseDueAt != null)
        'Follow-up date: ${DateFormat('dd MMM yyyy').format(response.promiseDueAt!)}',
      if ((response.resolutionNote ?? '').trim().isNotEmpty)
        'Resolution: ${response.resolutionNote!.trim()}',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  response.kind.label,
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GirviStyles.caption.copyWith(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stageLabel,
            style: GirviStyles.caption.copyWith(
              color: GirviColors.info,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.responseText,
            style: GirviStyles.caption.copyWith(
              color: GirviColors.textDark,
              fontSize: 12.5,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 9),
          for (final detail in details) ...[
            Text(
              detail,
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textMuted,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
          ],
          if (onResolve != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.task_alt_rounded, size: 16),
                label: const Text('Close follow-up'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GirviColors.shellBg,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowUpResolutionResult {
  const _FollowUpResolutionResult({required this.status, this.note});

  final GirviPromiseStatus status;
  final String? note;
}

class _FollowUpResolutionDialog extends StatefulWidget {
  const _FollowUpResolutionDialog({required this.response});

  final GirviCustomerResponse response;

  @override
  State<_FollowUpResolutionDialog> createState() =>
      _FollowUpResolutionDialogState();
}

class _FollowUpResolutionDialogState extends State<_FollowUpResolutionDialog> {
  final _noteController = TextEditingController();
  GirviPromiseStatus _status = GirviPromiseStatus.fulfilled;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: GirviColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Close Customer Follow-up',
          style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
        ),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.response.responseText,
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GirviPromiseStatus>(
                initialValue: _status,
                dropdownColor: Colors.white,
                iconEnabledColor: GirviColors.textDark,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'Outcome',
                  labelStyle: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                  filled: true,
                  fillColor: GirviColors.bodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                items: const [
                  GirviPromiseStatus.fulfilled,
                  GirviPromiseStatus.missed,
                  GirviPromiseStatus.cancelled,
                ]
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.label,
                          style: GoogleFonts.inter(
                            color: GirviColors.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                style: GoogleFonts.inter(
                  color: GirviColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: GirviColors.shellBg,
                decoration: InputDecoration(
                  labelText: 'Resolution note (optional)',
                  hintText:
                      'State what actually happened; do not overwrite the original response.',
                  labelStyle: GoogleFonts.inter(
                    color: GirviColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                  hintStyle: GoogleFonts.inter(
                    color: GirviColors.textDark.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: GirviColors.bodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: GirviColors.textDark,
              backgroundColor: GirviColors.inputBgLocked,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              _FollowUpResolutionResult(
                status: _status,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GirviColors.shellBg,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save outcome'),
          ),
        ],
      );
}

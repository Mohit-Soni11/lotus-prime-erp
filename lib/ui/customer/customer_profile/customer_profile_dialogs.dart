part of 'customer_profile_screen.dart';

extension _ProfileDialogs on _CustomerProfileScreenState {
  Future<void> _openCustomerEditor(CustomerProfileModel profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (editorContext) => AddCustomerScreen(
          customerId: profile.id,
          onBack: () => Navigator.of(editorContext).pop(false),
          onSaved: () => Navigator.of(editorContext).pop(true),
        ),
      ),
    );

    if (updated == true && mounted) await _logic.refresh();
  }

  Future<void> _showDeleteDialog(CustomerProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF718096).withValues(alpha: 0.22),
      builder: (dialogContext) => _CustomerDeleteConfirmation(
        customerName: profile.name,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await _logic.deleteCustomer();
    if (!deleted && mounted) {
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: _logic.deleteError ?? CustomerProfileStrings.deleteError,
      );
    }
  }
}

class _CustomerDeleteConfirmation extends StatelessWidget {
  const _CustomerDeleteConfirmation({
    required this.customerName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String customerName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CustomerProfileColors.bodyPanelBg,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: CustomerProfileColors.bodyBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: CustomerProfileColors.deleteBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: CustomerProfileColors.deleteText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      CustomerProfileStrings.deleteTitle,
                      style: TextStyle(
                        color: CustomerProfileColors.bodyTextMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: CustomerProfileColors.bodyBg,
                  border: Border.all(color: CustomerProfileColors.bodyBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  customerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerProfileColors.bodyTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                CustomerProfileStrings.deleteMsg,
                style: TextStyle(
                  color: CustomerProfileColors.bodyTextMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomerProfileColors.bodyTextMain,
                        side: const BorderSide(
                          color: CustomerProfileColors.bodyBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text(CustomerProfileStrings.deleteCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomerProfileColors.deleteText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(CustomerProfileStrings.deleteConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

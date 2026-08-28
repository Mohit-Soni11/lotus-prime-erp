import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/media/captured_photo_storage.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'purchase_seller_camera_dialog.dart';

class PurchaseSellerPhotoCard extends StatelessWidget {
  final PurchaseEntryController ctrl;

  const PurchaseSellerPhotoCard({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final path = ctrl.sellerPhotoPath?.trim() ?? '';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasPhoto
            ? PurchaseEntryColors.success.withValues(alpha: 0.06)
            : PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPhoto
              ? PurchaseEntryColors.success.withValues(alpha: 0.24)
              : PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          _PhotoPreview(path: path, hasPhoto: hasPhoto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? 'Seller Photo Attached' : 'Seller Photo',
                  style: PurchaseEntryStyles.inputText.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  hasPhoto
                      ? 'This photo will be saved with the purchase and printed on the invoice.'
                      : 'Capture a live seller photo for invoice proof.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PurchaseEntryStyles.subTitleMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PhotoActionButton(
            title: hasPhoto ? 'Retake' : 'Capture',
            icon: Icons.photo_camera_outlined,
            onTap: () => _capturePhoto(context),
          ),
          if (hasPhoto) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remove Photo',
              onPressed: ctrl.clearSellerPhoto,
              icon: const Icon(Icons.delete_outline_rounded),
              color: PurchaseEntryColors.danger,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _capturePhoto(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final capturedPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PurchaseSellerCameraDialog(),
    );
    if (capturedPath == null ||
        capturedPath.trim().isEmpty ||
        !context.mounted) {
      return;
    }

    try {
      final savedPath = await CapturedPhotoStorage.persistJpeg(
        sourcePath: capturedPath,
        module: 'customer_metal_purchase',
        fileStem: ctrl.formattedPurchaseNo,
      );
      if (!context.mounted) return;
      ctrl.setSellerPhoto(savedPath);
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: 'Seller photo captured for this invoice.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: 'Seller photo could not be saved. Please try again.',
      );
    }
  }
}

class _PhotoPreview extends StatelessWidget {
  final String path;
  final bool hasPhoto;

  const _PhotoPreview({
    required this.path,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 62,
        height: 68,
        decoration: BoxDecoration(
          color: PurchaseEntryColors.formInputBg,
          border: Border.all(color: PurchaseEntryColors.bodyBorder),
        ),
        child: hasPhoto
            ? Image.file(File(path), fit: BoxFit.cover)
            : const Icon(
                Icons.person_pin_outlined,
                color: PurchaseEntryColors.purchaseAccent,
                size: 30,
              ),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PhotoActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: PurchaseEntryColors.purchaseAccent,
          side: BorderSide(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

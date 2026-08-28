import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/media/captured_photo_storage.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'purchase_seller_camera_dialog.dart';
import 'purchase_seller_photo_editor_dialog.dart';
import 'purchase_seller_photo_preview_dialog.dart';

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PhotoPreview(path: path, hasPhoto: hasPhoto),
          const SizedBox(width: 14),
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
          hasPhoto
              ? _buildAttachedActions(context, path)
              : _buildCaptureAction(context),
        ],
      ),
    );
  }

  Widget _buildCaptureAction(BuildContext context) {
    return _PhotoActionButton(
      title: 'Capture',
      icon: Icons.photo_camera_outlined,
      onTap: () => _capturePhoto(context),
    );
  }

  Widget _buildAttachedActions(BuildContext context, String path) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _PhotoActionButton(
          title: 'Preview',
          icon: Icons.visibility_outlined,
          compact: true,
          onTap: () => PurchaseSellerPhotoPreviewDialog.show(context, path),
        ),
        _PhotoActionButton(
          title: 'Edit',
          icon: Icons.crop_rounded,
          compact: true,
          onTap: () => _editPhoto(context, path),
        ),
        _PhotoActionButton(
          title: 'Retake',
          icon: Icons.photo_camera_outlined,
          compact: true,
          onTap: () => _capturePhoto(context),
        ),
        _PhotoIconButton(
          tooltip: 'Remove Photo',
          icon: Icons.delete_outline_rounded,
          color: PurchaseEntryColors.danger,
          onTap: ctrl.clearSellerPhoto,
        ),
      ],
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

  Future<void> _editPhoto(BuildContext context, String path) async {
    FocusScope.of(context).unfocus();
    if (!File(path).existsSync()) {
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: 'Seller photo file was not found. Please retake the photo.',
      );
      return;
    }

    final croppedBytes = await PurchaseSellerPhotoEditorDialog.show(
      context,
      path,
    );
    if (croppedBytes == null || croppedBytes.isEmpty || !context.mounted) {
      return;
    }

    try {
      final savedPath = await CapturedPhotoStorage.persistJpegBytes(
        bytes: croppedBytes,
        module: 'customer_metal_purchase',
        fileStem: '${ctrl.formattedPurchaseNo}_seller_photo_edit',
      );
      if (!context.mounted) return;
      ctrl.setSellerPhoto(savedPath);
      AppFeedback.show(
        context,
        type: AppFeedbackType.success,
        message: 'Seller photo updated for this invoice.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: 'Edited photo could not be saved. Please try again.',
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
        width: 92,
        height: 76,
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
  final bool compact;

  const _PhotoActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 36 : 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: PurchaseEntryColors.purchaseAccent,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}

class _PhotoIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PhotoIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}

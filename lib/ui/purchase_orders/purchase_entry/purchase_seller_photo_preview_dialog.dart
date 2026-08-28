import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseSellerPhotoPreviewDialog extends StatelessWidget {
  final String photoPath;

  const PurchaseSellerPhotoPreviewDialog({
    super.key,
    required this.photoPath,
  });

  static Future<void> show(BuildContext context, String photoPath) {
    return showDialog<void>(
      context: context,
      builder: (_) => PurchaseSellerPhotoPreviewDialog(photoPath: photoPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        decoration: BoxDecoration(
          color: PurchaseEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PurchaseEntryColors.bodyBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: InteractiveViewer(
                      minScale: 0.6,
                      maxScale: 5,
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 10, 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.image_search_rounded,
              color: PurchaseEntryColors.purchaseAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seller Photo Preview',
              style: PurchaseEntryStyles.inputText.copyWith(fontSize: 16),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

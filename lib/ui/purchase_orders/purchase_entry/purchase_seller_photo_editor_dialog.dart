import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseSellerPhotoEditorDialog extends StatefulWidget {
  final String photoPath;

  const PurchaseSellerPhotoEditorDialog({
    super.key,
    required this.photoPath,
  });

  static Future<Uint8List?> show(BuildContext context, String photoPath) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PurchaseSellerPhotoEditorDialog(photoPath: photoPath),
    );
  }

  @override
  State<PurchaseSellerPhotoEditorDialog> createState() =>
      _PurchaseSellerPhotoEditorDialogState();
}

class _PurchaseSellerPhotoEditorDialogState
    extends State<PurchaseSellerPhotoEditorDialog> {
  final CropController _cropController = CropController();
  late Future<Uint8List> _imageBytes;
  bool _saving = false;
  double? _aspectRatio = 4 / 3;

  @override
  void initState() {
    super.initState();
    _imageBytes = File(widget.photoPath).readAsBytes();
  }

  void _crop() {
    if (_saving) return;
    setState(() => _saving = true);
    _cropController.crop();
  }

  void _changeAspectRatio(double? value) {
    setState(() => _aspectRatio = value);
    _cropController.aspectRatio = value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 780),
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
            _buildHeader(),
            const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _imageBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _EditorStateMessage(
                      icon: Icons.broken_image_outlined,
                      message: 'Photo could not be opened for editing.',
                    );
                  }
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: PurchaseEntryColors.purchaseAccent,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Crop(
                            image: bytes,
                            controller: _cropController,
                            aspectRatio: _aspectRatio,
                            initialSize: 0.92,
                            interactive: true,
                            baseColor: Colors.black,
                            maskColor: Colors.black.withValues(alpha: 0.50),
                            radius: 8,
                            progressIndicator: const CircularProgressIndicator(
                              color: PurchaseEntryColors.purchaseAccent,
                            ),
                            onCropped: (croppedBytes) {
                              if (!mounted) return;
                              Navigator.pop(context, croppedBytes);
                            },
                          ),
                          if (_saving)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.28),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: PurchaseEntryColors.purchaseAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: PurchaseEntryColors.bodyBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.crop_rounded,
              color: PurchaseEntryColors.purchaseAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Seller Photo',
                  style: PurchaseEntryStyles.inputText.copyWith(fontSize: 16),
                ),
                Text(
                  'Drag, zoom and crop the photo used on the invoice.',
                  style: PurchaseEntryStyles.subTitleMuted,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _AspectButton(
            label: '4:3',
            active: _aspectRatio == 4 / 3,
            onTap: _saving ? null : () => _changeAspectRatio(4 / 3),
          ),
          const SizedBox(width: 8),
          _AspectButton(
            label: 'Portrait',
            active: _aspectRatio == 3 / 4,
            onTap: _saving ? null : () => _changeAspectRatio(3 / 4),
          ),
          const SizedBox(width: 8),
          _AspectButton(
            label: 'Free',
            active: _aspectRatio == null,
            onTap: _saving ? null : () => _changeAspectRatio(null),
          ),
          const Spacer(),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: PurchaseEntryColors.textDark,
                side: BorderSide(
                  color: PurchaseEntryColors.textDark.withValues(alpha: 0.22),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _saving ? null : _crop,
              style: FilledButton.styleFrom(
                backgroundColor: PurchaseEntryColors.purchaseAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? 'Saving...' : 'Apply Crop'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _AspectButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active
              ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12)
              : null,
          foregroundColor: active
              ? PurchaseEntryColors.purchaseAccent
              : PurchaseEntryColors.textDark,
          side: BorderSide(
            color: active
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.bodyBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EditorStateMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EditorStateMessage({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: PurchaseEntryColors.danger),
          const SizedBox(height: 12),
          Text(
            message,
            style: PurchaseEntryStyles.inputText.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

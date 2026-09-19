part of '../new_girvi_screen.dart';

extension NewGirviPhotoActions on _NewGirviScreenState {
  Future<void> _pickPledgedItemPhoto(_PledgedItemDraft item) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      dialogTitle: 'Select Pledged Item Photos',
    );
    final selectedPaths = result?.files
            .map((file) => file.path)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList() ??
        const <String>[];
    if (selectedPaths.isEmpty || !mounted) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir =
          Directory(p.join(appDir.path, 'lotus_erp', 'girvi_item_photos'));
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final safeTicket = _ctrl.ticketNo
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final savedPaths = <String>[];
      for (var i = 0; i < selectedPaths.length; i++) {
        final path = selectedPaths[i];
        final source = File(path);
        final extension =
            p.extension(path).isEmpty ? '.jpg' : p.extension(path);
        final fileName =
            '${safeTicket}_item_${item.serialNo}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
        final savedPath = p.join(photoDir.path, fileName);
        await source.copy(savedPath);
        savedPaths.add(savedPath);
      }

      if (!mounted) return;
      _addPledgedItemPhotoPaths(item, savedPaths);
    } catch (e) {
      AppLogger.debug('NewGirviScreen._pickPledgedItemPhoto error: $e');
      if (mounted) {
        _showError('Item photos could not be attached. Please try again.');
      }
    }
  }

  void _removePledgedItemPhoto(_PledgedItemDraft item) {
    if (!mounted) return;
    _clearPledgedItemPhotos(item);
  }

  void _showPledgedItemPhotoPreview(_PledgedItemDraft item, String path) {
    if (!mounted || !File(path).existsSync()) return;
    final description = item.descriptionCtrl.text.trim();
    final title =
        description.isEmpty ? 'Pledged Item ${item.serialNo}' : description;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
            decoration: BoxDecoration(
              color: GirviColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GirviColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: GirviColors.brandGoldLight,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: GirviColors.brandGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: GirviColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Item #${item.serialNo} photo preview',
                              style: GirviStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: GirviColors.divider),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _pickItemPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Select Pledged Item Photo',
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    try {
      final source = File(path);
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir =
          Directory(p.join(appDir.path, 'lotus_erp', 'girvi_item_photos'));
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final extension = p.extension(path).isEmpty ? '.jpg' : p.extension(path);
      final safeTicket = _ctrl.ticketNo
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName =
          '${safeTicket}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = p.join(photoDir.path, fileName);
      await source.copy(savedPath);

      if (!mounted) return;
      _setItemPhotoPath(savedPath);
    } catch (e) {
      AppLogger.debug('NewGirviScreen._pickItemPhoto error: $e');
      if (mounted) {
        _showError('Item photo could not be attached. Please try again.');
      }
    }
  }

  // ignore: unused_element
  void _removeItemPhoto() {
    if (!mounted) return;
    _setItemPhotoPath(null);
  }

  // Supports legacy direct-print entry points that bypass the invoice hub.
  // ignore: unused_element
}

part of '../girvi_account_detail_screen.dart';

class _PledgedPhotoStrip extends StatelessWidget {
  final List<String> photoPaths;
  final Color color;

  const _PledgedPhotoStrip({
    required this.photoPaths,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final paths = photoPaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          paths.length == 1 ? 'Photo' : 'Photos',
          style: GoogleFonts.inter(
            color: GirviColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _PledgedPhotoThumb(
              path: paths[index],
              index: index + 1,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _PledgedPhotoThumb extends StatelessWidget {
  final String path;
  final int index;
  final Color color;

  const _PledgedPhotoThumb({
    required this.path,
    required this.index,
    required this.color,
  });

  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF111827),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(260),
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Image could not be opened',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.62),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: Material(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scroll or pinch to zoom',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openPreview(context),
        child: Container(
          width: 122,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: GirviColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(path),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: color.withValues(alpha: 0.07),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                top: 7,
                left: 7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 7,
                bottom: 7,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

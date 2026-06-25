part of '../interest_calc_screen.dart';

class _GirviReceiptFlipPreview extends StatefulWidget {
  const _GirviReceiptFlipPreview({
    required this.sides,
    required this.onClose,
  });

  final List<PdfRaster> sides;
  final VoidCallback onClose;

  @override
  State<_GirviReceiptFlipPreview> createState() =>
      _GirviReceiptFlipPreviewState();
}

class _GirviReceiptFlipPreviewState extends State<_GirviReceiptFlipPreview>
    with SingleTickerProviderStateMixin {
  static const double _minZoom = 0.70;
  static const double _maxZoom = 4.0;

  late final AnimationController _flipController;
  late final TransformationController _viewController;
  DateTime? _lastPointerDownAt;
  Offset? _lastPointerDownPosition;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _viewController = TransformationController();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _viewController.dispose();
    super.dispose();
  }

  void _toggleSide() {
    if (widget.sides.length < 2 || _flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final lastAt = _lastPointerDownAt;
    final lastPosition = _lastPointerDownPosition;
    final isDoubleClick = lastAt != null &&
        now.difference(lastAt) <= const Duration(milliseconds: 360) &&
        lastPosition != null &&
        (event.position - lastPosition).distance <= 16;

    _lastPointerDownAt = now;
    _lastPointerDownPosition = event.position;

    if (isDoubleClick) {
      _lastPointerDownAt = null;
      _lastPointerDownPosition = null;
      _toggleSide();
    }
  }

  void _zoomBy(double factor) {
    final currentScale = _viewController.value.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final nextScale =
        (currentScale * factor).clamp(_minZoom, _maxZoom).toDouble();
    if ((nextScale - currentScale).abs() < 0.01) return;
    final scaleDelta = nextScale / currentScale;
    _viewController.value = _viewController.value.clone()
      ..scaleByDouble(scaleDelta, scaleDelta, scaleDelta, 1.0);
  }

  void _resetZoom() {
    _viewController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF111827)),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final firstSide = widget.sides.first;
                final aspectRatio = firstSide.width / firstSide.height;
                return Listener(
                  onPointerDown: _handlePointerDown,
                  child: InteractiveViewer(
                    transformationController: _viewController,
                    minScale: _minZoom,
                    maxScale: _maxZoom,
                    scaleFactor: 160,
                    trackpadScrollCausesScale: true,
                    boundaryMargin: const EdgeInsets.all(320),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              math.min(constraints.maxWidth * 0.94, 1180.0),
                          maxHeight: constraints.maxHeight * 0.94,
                        ),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: MouseRegion(
                            cursor: widget.sides.length > 1
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, _) {
                                final angle = _flipController.value * math.pi;
                                final showingBack = angle > math.pi / 2 &&
                                    widget.sides.length > 1;
                                final side = showingBack
                                    ? widget.sides[1]
                                    : widget.sides.first;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showingBack
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _GirviReceiptFlipSide(
                                            raster: side,
                                          ),
                                        )
                                      : _GirviReceiptFlipSide(raster: side),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close preview',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _FlipHint(canFlip: widget.sides.length > 1),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _FlipPreviewToolbar(
              canFlip: widget.sides.length > 1,
              onFlip: _toggleSide,
              onZoomIn: () => _zoomBy(1.18),
              onZoomOut: () => _zoomBy(0.84),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipHint extends StatelessWidget {
  const _FlipHint({required this.canFlip});

  final bool canFlip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canFlip ? Icons.touch_app_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              canFlip ? 'Double click to flip front/back' : 'Invoice preview',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipPreviewToolbar extends StatelessWidget {
  const _FlipPreviewToolbar({
    required this.canFlip,
    required this.onFlip,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final bool canFlip;
  final VoidCallback onFlip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlipPreviewToolButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Reset zoom',
              icon: Icons.center_focus_strong_rounded,
              onPressed: onReset,
            ),
            _FlipPreviewToolButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
            if (canFlip)
              _FlipPreviewToolButton(
                tooltip: 'Flip page',
                icon: Icons.flip_rounded,
                onPressed: onFlip,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlipPreviewToolButton extends StatelessWidget {
  const _FlipPreviewToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

class _GirviReceiptFlipSide extends StatelessWidget {
  const _GirviReceiptFlipSide({required this.raster});

  final PdfRaster raster;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image(
          image: PdfRasterImage(raster),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

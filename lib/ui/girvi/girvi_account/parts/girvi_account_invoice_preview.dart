part of '../girvi_account_detail_screen.dart';

class _GirviInvoicePagesPreview extends StatefulWidget {
  const _GirviInvoicePagesPreview({
    required this.pages,
    required this.onClose,
  });

  final List<PdfRaster> pages;
  final VoidCallback onClose;

  @override
  State<_GirviInvoicePagesPreview> createState() =>
      _GirviInvoicePagesPreviewState();
}

class _GirviInvoicePagesPreviewState extends State<_GirviInvoicePagesPreview> {
  static const double _minZoom = 0.70;
  static const double _maxZoom = 2.60;

  double _zoom = 1;

  void _zoomBy(double factor) {
    final next = (_zoom * factor).clamp(_minZoom, _maxZoom).toDouble();
    if ((next - _zoom).abs() < 0.01) return;
    setState(() => _zoom = next);
  }

  void _resetZoom() {
    if ((_zoom - 1).abs() < 0.01) return;
    setState(() => _zoom = 1);
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
                final baseWidth = math.min(constraints.maxWidth * 0.90, 1040.0);
                final pageWidth = baseWidth * _zoom;
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 82, 24, 92),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < widget.pages.length;
                            index++) ...[
                          _GirviInvoicePreviewPage(
                            page: widget.pages[index],
                            pageNumber: index + 1,
                            pageCount: widget.pages.length,
                            width: pageWidth,
                          ),
                          if (index != widget.pages.length - 1)
                            const SizedBox(height: 22),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: _InvoicePagesHint(pageCount: widget.pages.length),
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
            right: 18,
            bottom: 18,
            child: _InvoicePagesToolbar(
              onZoomIn: () => _zoomBy(1.16),
              onZoomOut: () => _zoomBy(0.86),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    );
  }
}

class _GirviInvoicePreviewPage extends StatelessWidget {
  const _GirviInvoicePreviewPage({
    required this.page,
    required this.pageNumber,
    required this.pageCount,
    required this.width,
  });

  final PdfRaster page;
  final int pageNumber;
  final int pageCount;
  final double width;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = page.width / page.height;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints.tightFor(width: width),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image(
                  image: PdfRasterImage(page),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Page $pageNumber of $pageCount',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePagesHint extends StatelessWidget {
  const _InvoicePagesHint({required this.pageCount});

  final int pageCount;

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
            const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              pageCount <= 1
                  ? 'Invoice preview'
                  : 'Scroll to view all $pageCount pages',
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

class _InvoicePagesToolbar extends StatelessWidget {
  const _InvoicePagesToolbar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

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
            _InvoicePagesToolButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            _InvoicePagesToolButton(
              tooltip: 'Reset zoom',
              icon: Icons.center_focus_strong_rounded,
              onPressed: onReset,
            ),
            _InvoicePagesToolButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicePagesToolButton extends StatelessWidget {
  const _InvoicePagesToolButton({
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

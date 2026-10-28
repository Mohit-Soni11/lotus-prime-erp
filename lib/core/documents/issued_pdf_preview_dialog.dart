import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> showIssuedPdfPreview({
  required BuildContext context,
  required Uint8List pdfBytes,
  String title = 'Issued Invoice PDF',
}) {
  var scale = 1.0;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.74),
    useSafeArea: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, update) {
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final readablePageWidth = (viewportWidth * 0.8).clamp(480.0, 1500.0);
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF111827),
          child: Stack(
            children: [
              Positioned.fill(
                child: PdfPreview(
                  key: ValueKey((pdfBytes, scale)),
                  build: (_) async => pdfBytes,
                  shouldRepaint: true,
                  initialPageFormat: PdfPageFormat.a4,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false,
                  maxPageWidth: readablePageWidth * scale,
                  dpi: (250 * scale).clamp(200, 375).toDouble(),
                  scrollViewDecoration: const BoxDecoration(
                    color: Color(0xFF111827),
                  ),
                  onError: (_, __) => const Center(
                    child: Text(
                      'PDF preview could not be displayed.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: scale <= 0.75
                            ? null
                            : () => update(() => scale =
                                (scale - 0.25).clamp(0.75, 1.5).toDouble()),
                        icon: const Icon(Icons.remove_rounded),
                        color: Colors.white,
                      ),
                      Text(
                        '${(scale * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: scale >= 1.5
                            ? null
                            : () => update(() => scale =
                                (scale + 0.25).clamp(0.75, 1.5).toDouble()),
                        icon: const Icon(Icons.add_rounded),
                        color: Colors.white,
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

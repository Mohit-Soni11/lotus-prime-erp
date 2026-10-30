import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> showIssuedPdfPreview({
  required BuildContext context,
  Uint8List? pdfBytes,
  Future<Uint8List?>? pdfBytesFuture,
  String title = 'Issued Invoice PDF',
}) {
  assert((pdfBytes == null) != (pdfBytesFuture == null));
  var scale = 1.0;
  Widget pdfContent(Uint8List bytes, double readablePageWidth) => PdfPreview(
        key: ValueKey((bytes, scale)),
        build: (_) async => bytes,
        shouldRepaint: true,
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
        maxPageWidth: readablePageWidth * scale,
        dpi: (200 * scale).clamp(200, 300).toDouble(),
        scrollViewDecoration: const BoxDecoration(
          color: Color(0xFF111827),
        ),
        onError: (_, __) => const Center(
          child: Text(
            'PDF preview could not be displayed.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

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
                child: pdfBytes != null
                    ? pdfContent(pdfBytes, readablePageWidth)
                    : FutureBuilder<Uint8List?>(
                        future: pdfBytesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFFD8B331),
                                  ),
                                  SizedBox(height: 18),
                                  Text(
                                    'Opening issued invoice PDF...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final loadedBytes = snapshot.data;
                          if (snapshot.hasError || loadedBytes == null) {
                            return const Center(
                              child: Text(
                                'Issued invoice PDF could not be opened.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }
                          return pdfContent(loadedBytes, readablePageWidth);
                        },
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

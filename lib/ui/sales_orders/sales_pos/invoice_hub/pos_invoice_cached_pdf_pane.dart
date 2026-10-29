import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PosInvoiceCachedPdfPane extends StatefulWidget {
  const PosInvoiceCachedPdfPane({
    super.key,
    required this.bytes,
    required this.pageFormat,
  });

  final Uint8List bytes;
  final PdfPageFormat pageFormat;

  @override
  State<PosInvoiceCachedPdfPane> createState() =>
      _PosInvoiceCachedPdfPaneState();
}

class _PosInvoiceCachedPdfPaneState extends State<PosInvoiceCachedPdfPane> {
  late final LayoutCallback _buildDocument;

  Future<Uint8List> _readBytes(PdfPageFormat _) async => widget.bytes;

  @override
  void initState() {
    super.initState();
    _buildDocument = _readBytes;
  }

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: _buildDocument,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      initialPageFormat: widget.pageFormat,
      maxPageWidth: 1200,
      dpi: 250,
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pos_invoice_policy_copy.dart';

class PosInvoicePdfTextRenderer {
  static const _devanagariFamily = 'LotusPdfDevanagari';
  static const _devanagariAsset =
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
  static Future<void>? _fontLoad;

  final bool _enabled;
  final _cache = <_TextKey, _RenderedText>{};

  PosInvoicePdfTextRenderer._({required bool enabled}) : _enabled = enabled;

  static Future<PosInvoicePdfTextRenderer> create() async {
    final enabled = await _tryEnsureDevanagariFontLoaded();
    return PosInvoicePdfTextRenderer._(enabled: enabled);
  }

  static Future<bool> _tryEnsureDevanagariFontLoaded() async {
    try {
      await (_fontLoad ??= () async {
        final loader = FontLoader(_devanagariFamily)
          ..addFont(rootBundle.load(_devanagariAsset));
        await loader.load();
      }());
      return true;
    } catch (_) {
      _fontLoad = null;
      return false;
    }
  }

  Future<void> warmPolicyLines(
    Iterable<String> lines, {
    required Iterable<PosInvoicePdfTextSpec> specs,
  }) async {
    if (!_enabled) return;
    for (final line in lines) {
      if (!PosInvoicePolicyCopy.containsDevanagari(line)) continue;
      for (final spec in specs) {
        await _render(line, spec);
      }
    }
  }

  pw.Widget text(
    String value, {
    required pw.TextStyle style,
    required double maxWidth,
    pw.TextAlign? textAlign,
    int? maxLines,
    pw.TextOverflow? overflow,
  }) {
    if (!_enabled || !PosInvoicePolicyCopy.containsDevanagari(value)) {
      return pw.Text(
        value,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }

    final spec = PosInvoicePdfTextSpec.fromStyle(
      style,
      maxWidth: maxWidth,
    );
    final rendered = _cache[_TextKey(value, spec)];
    if (rendered == null) {
      return pw.Text(
        value,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }

    return pw.Image(
      rendered.image,
      width: rendered.width,
      height: rendered.height,
      fit: pw.BoxFit.contain,
    );
  }

  Future<void> _render(String value, PosInvoicePdfTextSpec spec) async {
    final key = _TextKey(value, spec);
    if (_cache.containsKey(key)) return;

    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: value,
        style: painting.TextStyle(
          color: spec.flutterColor,
          fontFamily: _devanagariFamily,
          fontSize: spec.fontSize,
          fontWeight:
              spec.bold ? painting.FontWeight.w700 : painting.FontWeight.w400,
          height: spec.lineHeight,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: spec.maxWidth);

    final logicalWidth = spec.maxWidth;
    final logicalHeight =
        textPainter.height <= 0 ? spec.fontSize : textPainter.height;
    const scale = 3.0;
    final imageWidth = (logicalWidth * scale).ceil().clamp(1, 4000);
    final imageHeight = (logicalHeight * scale).ceil().clamp(1, 4000);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale);
    textPainter.paint(canvas, ui.Offset.zero);

    final picture = recorder.endRecording();
    final image = await picture.toImage(imageWidth, imageHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    _cache[key] = _RenderedText(
      image: pw.MemoryImage(byteData.buffer.asUint8List()),
      width: logicalWidth,
      height: logicalHeight,
    );
  }
}

class PosInvoicePdfTextSpec {
  final double fontSize;
  final bool bold;
  final PdfColor color;
  final double maxWidth;
  final double lineHeight;

  const PosInvoicePdfTextSpec({
    required this.fontSize,
    required this.bold,
    required this.color,
    required this.maxWidth,
    this.lineHeight = 1.25,
  });

  factory PosInvoicePdfTextSpec.fromStyle(
    pw.TextStyle style, {
    required double maxWidth,
  }) {
    return PosInvoicePdfTextSpec(
      fontSize: style.fontSize ?? 10,
      bold: style.fontWeight == pw.FontWeight.bold,
      color: style.color ?? PdfColors.black,
      maxWidth: maxWidth,
    );
  }

  ui.Color get flutterColor {
    int channel(double value) => (value * 255).round().clamp(0, 255);
    return ui.Color.fromARGB(
      channel(color.alpha),
      channel(color.red),
      channel(color.green),
      channel(color.blue),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PosInvoicePdfTextSpec &&
        other.fontSize == fontSize &&
        other.bold == bold &&
        other.color == color &&
        other.maxWidth == maxWidth &&
        other.lineHeight == lineHeight;
  }

  @override
  int get hashCode => Object.hash(fontSize, bold, color, maxWidth, lineHeight);
}

class _TextKey {
  final String text;
  final PosInvoicePdfTextSpec spec;

  const _TextKey(this.text, this.spec);

  @override
  bool operator ==(Object other) {
    return other is _TextKey && other.text == text && other.spec == spec;
  }

  @override
  int get hashCode => Object.hash(text, spec);
}

class _RenderedText {
  final pw.MemoryImage image;
  final double width;
  final double height;

  const _RenderedText({
    required this.image,
    required this.width,
    required this.height,
  });
}

import 'dart:ui' as ui;

import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LotusPdfTextRenderer {
  static const _devanagariFamily = 'LotusPdfDevanagari';
  static const _devanagariAsset =
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
  static Future<void>? _fontLoad;

  final bool _enabled;
  final _cache = <_TextKey, _RenderedText>{};

  LotusPdfTextRenderer._({required bool enabled}) : _enabled = enabled;

  static Future<LotusPdfTextRenderer> create() async {
    final enabled = await _tryEnsureDevanagariFontLoaded();
    return LotusPdfTextRenderer._(enabled: enabled);
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

  Future<void> warmTextLines(
    Iterable<String> lines, {
    required Iterable<LotusPdfTextSpec> specs,
  }) async {
    if (!_enabled) return;
    for (final line in lines) {
      if (!containsDevanagari(line)) continue;
      for (final spec in specs) {
        await _render(line, spec);
      }
    }
  }

  Future<void> warmPolicyLines(
    Iterable<String> lines, {
    required Iterable<LotusPdfTextSpec> specs,
  }) {
    return warmTextLines(lines, specs: specs);
  }

  pw.Widget text(
    String value, {
    required pw.TextStyle style,
    required double maxWidth,
    pw.TextAlign? textAlign,
    int? maxLines,
    pw.TextOverflow? overflow,
  }) {
    if (!_enabled || !containsDevanagari(value)) {
      return pw.Text(
        value,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }

    final spec = LotusPdfTextSpec.fromStyle(style, maxWidth: maxWidth);
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

  static bool containsDevanagari(String value) {
    return value.runes.any((codePoint) =>
        (codePoint >= 0x0900 && codePoint <= 0x097F) ||
        (codePoint >= 0xA8E0 && codePoint <= 0xA8FF));
  }

  Future<void> _render(String value, LotusPdfTextSpec spec) async {
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
    final contentHeight =
        textPainter.height <= 0 ? spec.fontSize : textPainter.height;
    final topPadding = spec.fontSize * 0.32;
    final bottomPadding = spec.fontSize * 0.22;
    final logicalHeight = contentHeight + topPadding + bottomPadding;
    const scale = 3.0;
    final imageWidth = (logicalWidth * scale).ceil().clamp(1, 4000);
    final imageHeight = (logicalHeight * scale).ceil().clamp(1, 4000);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale);
    textPainter.paint(canvas, ui.Offset(0, topPadding));

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

class LotusPdfTextSpec {
  final double fontSize;
  final bool bold;
  final PdfColor color;
  final double maxWidth;
  final double lineHeight;

  const LotusPdfTextSpec({
    required this.fontSize,
    required this.bold,
    required this.color,
    required this.maxWidth,
    this.lineHeight = 1.35,
  });

  factory LotusPdfTextSpec.fromStyle(
    pw.TextStyle style, {
    required double maxWidth,
  }) {
    return LotusPdfTextSpec(
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
    return other is LotusPdfTextSpec &&
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
  final LotusPdfTextSpec spec;

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

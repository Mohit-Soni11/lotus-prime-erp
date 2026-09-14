import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class LotusPdfTheme {
  LotusPdfTheme._();

  static const String devanagariFontAsset =
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';

  static Future<pw.ThemeData> reportTheme() async {
    WidgetsFlutterBinding.ensureInitialized();
    final devanagariFont = await loadDevanagariFont();
    final fallback = devanagariFont == null ? null : <pw.Font>[devanagariFont];

    final systemTheme = await _windowsSystemTheme(fontFallback: fallback);
    if (systemTheme != null) return systemTheme;

    if (devanagariFont != null) {
      return pw.ThemeData.withFont(
        base: devanagariFont,
        bold: devanagariFont,
        italic: devanagariFont,
        boldItalic: devanagariFont,
        fontFallback: fallback,
      );
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }

  static Future<pw.Font?> loadDevanagariFont() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      return pw.Font.ttf(await rootBundle.load(devanagariFontAsset));
    } catch (_) {
      try {
        final file = File(devanagariFontAsset);
        if (!file.existsSync()) return null;
        return pw.Font.ttf(_asByteData(await file.readAsBytes()));
      } catch (_) {
        return null;
      }
    }
  }

  static Future<pw.ThemeData?> _windowsSystemTheme({
    required List<pw.Font>? fontFallback,
  }) async {
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory == null) return null;

    final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
    final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
    if (!regularFile.existsSync() || !boldFile.existsSync()) return null;

    try {
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
        bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
        fontFallback: fontFallback,
      );
    } catch (_) {
      return null;
    }
  }

  static ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
  }
}

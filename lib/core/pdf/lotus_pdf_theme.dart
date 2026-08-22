import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LotusPdfTheme {
  LotusPdfTheme._();

  static Future<pw.ThemeData> reportTheme() async {
    WidgetsFlutterBinding.ensureInitialized();
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
      italic: await PdfGoogleFonts.notoSansItalic(),
      boldItalic: await PdfGoogleFonts.notoSansBoldItalic(),
    );
  }
}

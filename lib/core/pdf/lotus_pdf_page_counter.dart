import 'dart:convert';
import 'dart:typed_data';

class LotusPdfPageCounter {
  const LotusPdfPageCounter._();

  static int? tryCountPages(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;

    final content = latin1.decode(bytes);
    final count =
        RegExp(r'/Type\s*/Page(?![A-Za-z])').allMatches(content).length;
    return count <= 0 ? null : count;
  }

  static int? pagesPerCopy({
    required int? totalPages,
    required int copies,
  }) {
    if (totalPages == null || totalPages <= 0) return null;
    final safeCopies = copies.clamp(1, 5).toInt();
    if (totalPages % safeCopies != 0) return totalPages;
    return totalPages ~/ safeCopies;
  }

  static String copyLabel(int copies) {
    return '$copies ${copies == 1 ? 'copy' : 'copies'}';
  }

  static String pageLabel(int pages) {
    return '$pages ${pages == 1 ? 'page' : 'pages'}';
  }
}

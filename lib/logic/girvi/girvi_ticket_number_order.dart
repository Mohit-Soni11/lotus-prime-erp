/// Orders ticket identifiers by their text and numeric parts, so 9 precedes 10.
class GirviTicketNumberOrder {
  const GirviTicketNumberOrder._();

  static final RegExp _parts = RegExp(r'\d+|\D+');
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _leadingZeroes = RegExp(r'^0+(?=\d)');

  static int compare(String first, String second) {
    final left = _parts
        .allMatches(first.trim().toLowerCase())
        .map((m) => m[0]!)
        .toList();
    final right = _parts
        .allMatches(second.trim().toLowerCase())
        .map((m) => m[0]!)
        .toList();
    final count = left.length < right.length ? left.length : right.length;

    for (var index = 0; index < count; index++) {
      final leftPart = left[index];
      final rightPart = right[index];
      final result = _digits.hasMatch(leftPart) && _digits.hasMatch(rightPart)
          ? _compareNumbers(leftPart, rightPart)
          : leftPart.compareTo(rightPart);
      if (result != 0) return result;
    }

    final lengthOrder = left.length.compareTo(right.length);
    return lengthOrder != 0 ? lengthOrder : first.compareTo(second);
  }

  static int compareNewestFirst(String first, String second) =>
      compare(second, first);

  static int _compareNumbers(String first, String second) {
    final left = first.replaceFirst(_leadingZeroes, '');
    final right = second.replaceFirst(_leadingZeroes, '');
    final lengthOrder = left.length.compareTo(right.length);
    return lengthOrder != 0 ? lengthOrder : left.compareTo(right);
  }
}

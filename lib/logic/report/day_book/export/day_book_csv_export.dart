import 'day_book_report_model.dart';

class DayBookCsvExport {
  const DayBookCsvExport._();

  static String build(DateTime date, List<DayBookReportSection> sections) {
    final rows = <List<String>>[
      ['Section', 'Record', 'Field', 'Value'],
      [
        'Report',
        'Day Book',
        'Date',
        '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}'
      ],
    ];
    for (final section in sections) {
      if (section.rows.isEmpty) {
        rows.add([section.title, '-', 'Status', 'No records']);
        continue;
      }
      for (final row in section.rows) {
        if (row.length != section.headers.length) {
          throw StateError('Invalid Day Book export section: ${section.title}');
        }
        final record = row.first.raw;
        for (var index = 0; index < row.length; index++) {
          rows.add([
            section.title,
            record,
            section.headers[index],
            row[index].raw,
          ]);
        }
      }
    }
    return rows.map((row) => row.map(_escape).join(',')).join('\r\n');
  }

  static String _escape(String value) {
    final trimmed = value.trimLeft();
    final unsafe = trimmed.isNotEmpty &&
        ('=+@'.contains(trimmed[0]) ||
            (trimmed[0] == '-' &&
                trimmed.length > 1 &&
                double.tryParse(trimmed) == null));
    final safe = unsafe ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }
}

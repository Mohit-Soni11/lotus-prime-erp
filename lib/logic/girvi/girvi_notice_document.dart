import '../../models/girvi/girvi_notice_action_model.dart';

/// Customer-facing notice content. Financial values are supplied by the
/// verified account timeline; this model only controls document presentation.
class GirviNoticeDocument {
  const GirviNoticeDocument({
    required this.language,
    required this.title,
    required this.noticeNumber,
    required this.noticeDate,
    required this.pledgeReference,
    required this.subject,
    required this.sections,
  });

  final GirviNoticeLanguage language;
  final String title;
  final String noticeNumber;
  final String noticeDate;
  final String pledgeReference;
  final String subject;
  final List<GirviNoticeSection> sections;

  String toPlainText() {
    final isHindi = language == GirviNoticeLanguage.hindi;
    final lines = <String>[
      title,
      '${isHindi ? 'सूचना नंबर' : 'Notice Number'}: $noticeNumber',
      '${isHindi ? 'सूचना दिनांक' : 'Notice Date'}: $noticeDate',
      '${isHindi ? 'गिरवी संदर्भ' : 'Pledge Reference'}: $pledgeReference',
      '',
      '${isHindi ? 'विषय' : 'Subject'}: $subject',
    ];

    for (final section in sections) {
      lines
        ..add('')
        ..add(section.title);
      for (final block in section.blocks) {
        if (block.heading != null) lines.add(block.heading!);
        lines.addAll(block.lines);
      }
    }

    return lines.join('\n').trim();
  }
}

class GirviNoticeSection {
  const GirviNoticeSection({required this.title, required this.blocks});

  final String title;
  final List<GirviNoticeBlock> blocks;
}

class GirviNoticeBlock {
  const GirviNoticeBlock({this.heading, required this.lines});

  final String? heading;
  final List<String> lines;
}

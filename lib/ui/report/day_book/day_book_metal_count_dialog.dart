import 'package:flutter/material.dart';

import '../../../logic/report/day_book/day_book_controller.dart';
import '../../../models/reports/day_book/day_book_metal_count.dart';
import '../../../theme/reports/day_book/day_book_theme.dart';
import 'day_book_form_visuals.dart';

class DayBookMetalCountDialog extends StatefulWidget {
  const DayBookMetalCountDialog({super.key, required this.controller});

  final DayBookController controller;

  @override
  State<DayBookMetalCountDialog> createState() =>
      _DayBookMetalCountDialogState();
}

class _DayBookMetalCountDialogState extends State<DayBookMetalCountDialog> {
  late final Future<List<DayBookMetalCountLine>> _lines;
  final _fields = <String, _CountFields>{};
  bool _emptyConfirmed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lines = widget.controller.loadMetalCountLines();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<DayBookMetalCountLine> lines) async {
    if (_saving) return;
    final counts = <DayBookPhysicalMetalCount>[];
    for (final line in lines) {
      final field = _fields[line.key]!;
      final pieces = int.tryParse(field.pieces.text.trim());
      final gross = double.tryParse(field.gross.text.trim());
      final net = double.tryParse(field.net.text.trim());
      final fine = double.tryParse(field.fine.text.trim());
      if (pieces == null || gross == null || net == null || fine == null) {
        setState(() => _error = 'Enter every physical count before saving.');
        return;
      }
      counts.add(DayBookPhysicalMetalCount(
        key: line.key,
        pieces: pieces,
        grossGrams: gross,
        netGrams: net,
        fineGrams: fine,
      ));
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.verifyPhysicalMetal(counts, _emptyConfirmed);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DayBookFormVisuals.themed(
        child: Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: const Color(0xFFFFFEFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: DayBookColors.brandGoldBorder),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.sizeOf(context).height - 36,
            ),
            child: FutureBuilder<List<DayBookMetalCountLine>>(
              future: _lines,
              builder: (context, snapshot) {
                final lines = snapshot.data;
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
                    child: Row(children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: DayBookColors.goldMetal, size: 25),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Physical Metal Count',
                                style: DayBookStyles.pageTitle
                                    .copyWith(fontSize: 21)),
                            Text(
                                'Count owned stock by item and purity. '
                                'Girvi customer property is separate.',
                                style: DayBookStyles.labelStrong
                                    .copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ]),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (snapshot.hasError)
                            _notice('Stock records could not be loaded: '
                                '${snapshot.error}')
                          else if (lines == null)
                            const Padding(
                              padding: EdgeInsets.all(25),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (lines.isEmpty)
                            CheckboxListTile(
                              title: const Text('I physically checked that '
                                  'there is no owned gold or silver stock'),
                              value: _emptyConfirmed,
                              onChanged: (value) => setState(
                                  () => _emptyConfirmed = value ?? false),
                            )
                          else
                            for (final line in lines) _line(line),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            _notice(_error!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton.icon(
                            onPressed:
                                lines == null || _saving || snapshot.hasError
                                    ? null
                                    : () => _save(lines),
                            icon: const Icon(Icons.verified_outlined, size: 19),
                            label: Text(_saving
                                ? 'Verifying...'
                                : 'Save Physical Count'),
                          ),
                        ]),
                  ),
                ]);
              },
            ),
          ),
        ),
      );

  Widget _line(DayBookMetalCountLine line) {
    final field = _fields.putIfAbsent(line.key, _CountFields.new);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: DayBookStyles.panel(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${line.metal} · ${line.item} · ${line.purity}',
            style: DayBookStyles.sectionTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 5),
        Text(
            'System: ${line.pieces} pieces · '
            '${line.grossGrams.toStringAsFixed(3)} g gross · '
            '${line.netGrams.toStringAsFixed(3)} g net · '
            '${line.fineGrams?.toStringAsFixed(3) ?? 'unknown'} g fine',
            style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
        const SizedBox(height: 9),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _input('Pieces', field.pieces, width: 110),
          _input('Gross g', field.gross),
          _input('Net g', field.net),
          _input('Fine g', field.fine),
        ]),
      ]),
    );
  }

  Widget _input(String label, TextEditingController controller,
          {double width = 135}) =>
      SizedBox(
        width: width,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: DayBookStyles.labelStrong.copyWith(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _notice(String message) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DayBookColors.bodySubtle,
          border: Border.all(color: DayBookColors.brandGoldBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(message,
            style: DayBookStyles.labelStrong.copyWith(fontSize: 13)),
      );
}

class _CountFields {
  final pieces = TextEditingController();
  final gross = TextEditingController();
  final net = TextEditingController();
  final fine = TextEditingController();

  void dispose() {
    pieces.dispose();
    gross.dispose();
    net.dispose();
    fine.dispose();
  }
}

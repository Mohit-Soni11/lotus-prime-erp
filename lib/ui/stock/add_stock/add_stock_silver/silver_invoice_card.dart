import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/dashboard/date_card/date_card_logic.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/stock_metal_ui.dart';

class SilverInvoiceCard extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverInvoiceCard({
    super.key,
    required this.ctrl,
  });

  @override
  State<SilverInvoiceCard> createState() => _SilverInvoiceCardState();
}

class _SilverInvoiceCardState extends State<SilverInvoiceCard> {
  late final DateCardLogic _dateLogic;

  @override
  void initState() {
    super.initState();
    _dateLogic = DateCardLogic();
    _dateLogic.init();
  }

  @override
  void dispose() {
    _dateLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(widget.ctrl.selectedMetal);
    final accent = widget.ctrl.gstEnabled ? AddStockColors.success : ui.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _accentLine(20, accent, 1.0),
                        const SizedBox(height: 3),
                        _accentLine(13, accent, 0.45),
                        const SizedBox(height: 3),
                        _accentLine(7, accent, 0.18),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVOICE NUMBER',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AddStockColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.ctrl.gstEnabled
                                ? 'Tax Intake Reference'
                                : 'Standard Stock Intake',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: widget.ctrl.gstEnabled
                                  ? AddStockColors.success
                                  : AddStockColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _StatusPill(
                label: widget.ctrl.gstEnabled ? 'GST BATCH' : 'ESTIMATE',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: double.infinity,
            color: AddStockColors.cardBorder,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;

              final invoiceBlock = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      AddStockIcons.hsn,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BATCH CODE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: AddStockColors.textMuted,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.ctrl.batchCode,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: accent,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final dateTimeBlock = StreamBuilder<DateCardModel>(
                stream: _dateLogic.timeStream,
                initialData: _dateLogic.initialData,
                builder: (_, snapshot) => _DateTimeRow(
                  data: snapshot.data ?? DateCardModel.empty(),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    invoiceBlock,
                    const SizedBox(height: 12),
                    dateTimeBlock,
                  ],
                );
              }

              return Row(
                children: [
                  invoiceBlock,
                  Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AddStockColors.cardBorder,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: dateTimeBlock),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // ── SUPPLIER INVOICE NUMBER INPUT ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUPPLIER INVOICE NO.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AddStockColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.ctrl.supplierInvoiceNumberCtrl,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AddStockColors.textDark,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. INV-2024-00123',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AddStockColors.textHint,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 15,
                        color: accent,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: AddStockColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AddStockColors.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AddStockColors.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BillPhotoPicker(ctrl: widget.ctrl, accent: accent),
          // NOTE: Applied Silver Rate moved to SilverPaymentRecordCard
          //       (Rate is now entered manually per-batch in the Payment Record
          //        section as rate per kg, not loaded from daily rates here.)
        ],
      ),
    );
  }

  Widget _accentLine(double width, Color color, double opacity) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BillPhotoPicker extends StatelessWidget {
  final SilverStockController ctrl;
  final Color accent;

  const _BillPhotoPicker({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    final photoPath = ctrl.billPhotoPath;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: hasPhoto && File(photoPath).existsSync()
                ? Image.file(File(photoPath), fit: BoxFit.cover)
                : Icon(Icons.image_outlined, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUPPLIER BILL PHOTO',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AddStockColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto ? ctrl.billPhotoName : 'Attach supplier paper bill',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasPhoto
                        ? AddStockColors.textDark
                        : AddStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (hasPhoto)
            IconButton(
              tooltip: 'Remove bill photo',
              onPressed: ctrl.clearBillPhoto,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AddStockColors.danger,
            ),
          OutlinedButton.icon(
            onPressed: ctrl.isPickingBillPhoto ? null : ctrl.pickBillPhoto,
            icon: ctrl.isPickingBillPhoto
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                : Icon(Icons.upload_file_rounded, size: 16, color: accent),
            label: Text(hasPhoto ? 'CHANGE' : 'UPLOAD'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final DateCardModel data;

  const _DateTimeRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final timeParts = data.time.split(':');
    final cleanTime =
        timeParts.length >= 2 ? '${timeParts[0]} : ${timeParts[1]}' : data.time;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DateChip(
          icon: Icons.calendar_today_rounded,
          iconColor: AddStockColors.accentCompliance,
          label: 'DATE',
          value: data.date.toUpperCase(),
          chipBg: AddStockColors.accentCompliance.withValues(alpha: 0.07),
          chipBorder: AddStockColors.accentCompliance.withValues(alpha: 0.25),
          valueColor: AddStockColors.textDark,
        ),
        _DateChip(
          icon: Icons.access_time_rounded,
          iconColor: AddStockColors.success,
          label: 'TIME',
          value: cleanTime,
          chipBg: AddStockColors.success.withValues(alpha: 0.07),
          chipBorder: AddStockColors.success.withValues(alpha: 0.25),
          valueColor: AddStockColors.success,
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color chipBg;
  final Color chipBorder;
  final Color valueColor;

  const _DateChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.chipBg,
    required this.chipBorder,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: iconColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: valueColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../models/customer/add_customer/add_customer_form_model.dart';
import '../../../models/customer/customer_enums/add_customer_enums.dart';

class CustomerEntityChip extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const CustomerEntityChip({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18, color: isSelected ? activeColor : Colors.black54),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? activeColor : Colors.black87)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54)),
              ])),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: activeColor, size: 18),
        ]),
      ),
    );
  }
}

// =============================================================================
// FAMILY MEMBER ROW
// =============================================================================

class CustomerFamilyMemberRow extends StatefulWidget {
  final FamilyMember member;
  final void Function(FamilyMember) onUpdate;
  final VoidCallback onRemove;
  final Future<void> Function(void Function(DateTime)) onPickDate;

  const CustomerFamilyMemberRow({
    super.key,
    required this.member,
    required this.onUpdate,
    required this.onRemove,
    required this.onPickDate,
  });

  @override
  State<CustomerFamilyMemberRow> createState() =>
      CustomerFamilyMemberRowState();
}

class CustomerFamilyMemberRowState extends State<CustomerFamilyMemberRow> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dob = widget.member.dateOfBirth;
    final dobStr = dob != null ? DateFormat('dd/MM/yyyy').format(dob) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8FF),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFDB2777).withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _nameCtrl,
              onChanged: (v) =>
                  widget.onUpdate(widget.member.copyWith(name: v)),
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  hintText: 'Member name',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38),
                  border: InputBorder.none,
                  isDense: true),
            ),
          )),
          const SizedBox(width: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FamilyRelation>(
                value: widget.member.relation,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.black54),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                items: FamilyRelation.values
                    .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (r) {
                  if (r != null) {
                    widget.onUpdate(widget.member.copyWith(relation: r));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
                width: 36,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFDC2626), size: 18)),
          ),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => widget.onPickDate(
              (d) => widget.onUpdate(widget.member.copyWith(dateOfBirth: d))),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2DDD6))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(Icons.cake_rounded,
                  size: 16,
                  color:
                      dob != null ? const Color(0xFFDB2777) : Colors.black54),
              const SizedBox(width: 8),
              Text(
                dobStr ?? 'Date of Birth (optional)',
                style: dob != null
                    ? GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDB2777))
                    : GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// IMAGE SOURCE SHEET
// =============================================================================

class CustomerImageSourceSheet extends StatelessWidget {
  const CustomerImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Select Photo Source',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 16),
        _btn(context, Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
        _btn(context, Icons.photo_library_rounded, 'Gallery',
            ImageSource.gallery),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, String label, ImageSource src) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0x18D4AF37),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 22)),
      title: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      onTap: () => Navigator.pop(ctx, src),
    );
  }
}

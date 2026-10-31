import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
            child: Icon(icon, size: 18, color: activeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ])),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: activeColor, size: 18),
        ]),
      ),
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
        Text('Customer Profile Photo',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
        const SizedBox(height: 4),
        Text('Choose how to add a clear customer photo',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 16),
        _btn(context, Icons.camera_alt_rounded, 'Capture with Live Camera',
            ImageSource.camera),
        _btn(context, Icons.photo_library_rounded, 'Choose from Gallery',
            ImageSource.gallery),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFF64748B)),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, String label, ImageSource src) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: const Color(0xFFFFFBF2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE4C86B)),
        ),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2CA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF9C6D00), size: 22),
          ),
          title: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: Colors.black),
          onTap: () => Navigator.pop(ctx, src),
        ),
      ),
    );
  }
}

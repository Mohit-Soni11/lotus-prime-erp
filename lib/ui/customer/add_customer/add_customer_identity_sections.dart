part of 'add_customer_screen.dart';

extension _CustomerIdentitySections on _AddCustomerScreenState {
  Widget _buildInitialLoadError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AddCustomerColors.error,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            _initialLoadError!,
            style: AddCustomerStyles.sectionTitle,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _initializeForm,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );
  // SECTION CARD

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget child,
    required int stepNumber,
  }) {
    final headerAccent = Color.lerp(accent, Colors.white, 0.88)!;
    final lighterAccent = Color.lerp(accent, Colors.white, 0.96)!;
    return Container(
      decoration: AddCustomerStyles.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [headerAccent, lighterAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AddCustomerStyles.cardRadius)),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: accent.withValues(alpha: 0.28), width: 1),
              ),
              child: Center(
                  child: Text(
                stepNumber.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              )),
            ),
            const SizedBox(width: 14),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    )),
              ],
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ]),
    );
  }
  // SECTION 0: PROFILE PHOTO

  Widget _buildPhotoSection() {
    final imagePath = _logic.form.profileImagePath;
    final gender = _logic.form.gender;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AddCustomerColors.brandGold.withValues(alpha: 0.14),
            AddCustomerColors.brandGold.withValues(alpha: 0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AddCustomerColors.brandGold.withValues(alpha: 0.30),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AddCustomerColors.brandGold.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  AddCustomerColors.brandGold,
                  AddCustomerColors.brandGold.withValues(alpha: 0.4),
                  AddCustomerColors.brandGold
                ]),
                boxShadow: [
                  BoxShadow(
                      color:
                          AddCustomerColors.brandGold.withValues(alpha: 0.40),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AddCustomerColors.bodyPanelBg),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: imagePath != null
                      ? Image.file(File(imagePath),
                          fit: BoxFit.cover, width: 84, height: 84)
                      : _buildAvatar(gender),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AddCustomerColors.brandGold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AddCustomerColors.brandGold.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: Colors.black87),
            ),
          ]),
        ),
        const SizedBox(width: 18),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Photo',
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AddCustomerColors.bodyTextMain)),
            const SizedBox(height: 5),
            Text(
              imagePath != null
                  ? '✓ Photo uploaded'
                  : 'Avatar will auto-switch based on gender selection.',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: imagePath != null
                      ? AddCustomerColors.success
                      : Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _miniBtn(
                label: imagePath != null ? 'Change Photo' : 'Upload Photo',
                icon: Icons.camera_alt_rounded,
                bg: AddCustomerColors.brandGold,
                fg: Colors.black87,
                onTap: _pickImage,
              ),
              if (imagePath != null) ...[
                const SizedBox(width: 8),
                _miniBtn(
                  label: 'Remove',
                  icon: Icons.delete_outline_rounded,
                  bg: AddCustomerColors.errorBg,
                  fg: AddCustomerColors.error,
                  border: AddCustomerColors.error.withValues(alpha: 0.3),
                  onTap: () => _logic.setProfileImagePath(null),
                ),
              ],
            ]),
          ],
        )),
      ]),
    );
  }

  Widget _miniBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    Color? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border != null ? Border.all(color: border) : null,
          boxShadow: bg == AddCustomerColors.brandGold
              ? [
                  BoxShadow(
                      color:
                          AddCustomerColors.brandGold.withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }

  Widget _buildAvatar(Gender? gender) {
    final isFemale = gender == Gender.female;
    return Container(
      width: 84,
      height: 84,
      color: isFemale ? const Color(0xFFFFF0F5) : const Color(0xFFF0F4FF),
      child: isFemale
          ? const FaIcon(FontAwesomeIcons.solidUser,
              size: 40, color: Color(0xFFEC4899))
          : const Icon(Icons.person_rounded,
              size: 48, color: Color(0xFF6366F1)),
    );
  }
  // SECTION 1: PERSONAL
}

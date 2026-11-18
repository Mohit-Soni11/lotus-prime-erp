part of '../account_profile_screen.dart';

extension _ProfileAvatarWidgets on _AccountProfileScreenState {
  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatarCard(),
        const SizedBox(width: 20),
        Expanded(child: _buildFormCard()),
      ],
    );
  }

  Widget _buildAvatarCard() {
    final hasLocal = _pickedImageFile != null;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: AccountProfileStyles.cardDecoration,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: AccountProfileStyles.avatarSize,
                height: AccountProfileStyles.avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AccountProfileColors.brandGold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AccountProfileColors.brandGold.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasLocal
                      ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                      : _buildInitialsAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showPhotoMenu,
                  child: Container(
                    width: AccountProfileStyles.cameraIconSize,
                    height: AccountProfileStyles.cameraIconSize,
                    decoration: BoxDecoration(
                      color: AccountProfileColors.brandGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AccountProfileColors.bodyPanelBg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AccountProfileColors.brandGold
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(AccountProfileIcons.camera,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
            style: AccountProfileStyles.avatarName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text,
            style: AccountProfileStyles.avatarEmail,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          _buildRoleBadge(_role),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AccountProfileColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AccountProfileColors.success,
                        blurRadius: 4,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text('Online',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AccountProfileColors.success,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (_pickedImageFile != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickAndCropPhoto,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AccountProfileColors.brandGoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AccountProfileColors.brandGoldBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AccountProfileIcons.crop,
                        size: 13, color: AccountProfileColors.brandGold),
                    const SizedBox(width: 5),
                    Text(AccountProfileStrings.btnCrop,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AccountProfileColors.brandGold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final name = _nameCtrl.text;
    String initials = 'U';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      initials = parts.length > 1
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name[0].toUpperCase();
    }
    return Container(
      color: AccountProfileColors.avatarBg,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AccountProfileColors.avatarInitials,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg, text, border;
    IconData icon;
    switch (role) {
      case 'OWNER':
        bg = AccountProfileColors.ownerBadgeBg;
        text = AccountProfileColors.ownerBadgeText;
        border = AccountProfileColors.ownerBadgeBorder;
        icon = AccountProfileIcons.shield;
        break;
      case 'MANAGER':
        bg = AccountProfileColors.managerBadgeBg;
        text = AccountProfileColors.managerBadgeText;
        border = AccountProfileColors.managerBadgeBorder;
        icon = Icons.supervisor_account_outlined;
        break;
      default:
        bg = AccountProfileColors.staffBadgeBg;
        text = AccountProfileColors.staffBadgeText;
        border = AccountProfileColors.staffBadgeBorder;
        icon = AccountProfileIcons.person;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 13),
          const SizedBox(width: 5),
          Text(role,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: text,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import '../../theme/dashboard/shop_card/shop_card_theme.dart';
import '../../../../logic/dashboard/shop_card/shop_card_logic.dart';
import '../../../../logic/dashboard/dashboard_repository.dart'; // âœ… Import

class ShopIdentityCard extends StatefulWidget {
  // âœ… Repository ko pass karna zaroori hai
  final DashboardRepository repository;

  const ShopIdentityCard({super.key, required this.repository});

  @override
  State<ShopIdentityCard> createState() => _ShopIdentityCardState();
}

class _ShopIdentityCardState extends State<ShopIdentityCard> {
  late final ShopCardLogic _logic;

  @override
  void initState() {
    super.initState();
    // âœ… Logic ko Repository pass kiya
    _logic = ShopCardLogic(widget.repository);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, child) {
        if (_logic.isLoading) {
          return _buildLoadingShimmer();
        }

        if (_logic.hasError) {
          return _buildErrorState();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: ShopCardStyles.premiumCardDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ShopCardStyles.borderRadius),
            child: Padding(
              padding: ShopCardStyles.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _logic.data.displayName.toUpperCase(),
                              style: ShopCardStyles.shopNameStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Prop. ${_logic.data.ownerName}",
                              style: ShopCardStyles.ownerNameStyle,
                            ),
                            Text(
                              _logic.formattedLocation,
                              style: ShopCardStyles.locationStyle,
                            ),
                            const SizedBox(height: 12),
                            _buildToggleButton(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildProfileImage(),
                    ],
                  ),

                  // --- DETAILS ---
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      alignment: Alignment.topCenter,
                      curve: Curves.easeOutQuart,
                      child: _logic.isExpanded
                          ? Column(
                              children: [
                                const SizedBox(height: 15),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 10),
                                if (_logic.data.showMobile)
                                  _buildDetailRow(ShopCardIcons.mobile,
                                      "+91 ${_logic.data.mobile}",
                                      isGold: true),
                                if (_logic.data.showEmail)
                                  _buildDetailRow(
                                      ShopCardIcons.email, _logic.data.email),
                                _buildDetailRow(
                                    ShopCardIcons.website, _logic.data.website,
                                    isLink: true),
                                const SizedBox(height: 8),
                                if (_logic.data.showGst)
                                  _buildDetailRow(ShopCardIcons.gst,
                                      "GST: ${_logic.data.gstin}"),
                                _buildDetailRow(ShopCardIcons.bis,
                                    "BIS: ${_logic.data.bisLicense}"),
                                _buildDetailRow(ShopCardIcons.huid,
                                    "HUID: ${_logic.data.huidNo}"),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ... (Baaki saare helper widgets same rahenge: _buildProfileImage, _buildToggleButton, etc.)
  // (Main unhe repeat nahi kar raha space save karne ke liye, wo perfect hain)

  // Need to include these for context if copy pasting file completely:
  Widget _buildProfileImage() {
    final logoPath = _logic.data.logoPath?.trim() ?? '';
    final logoFile = logoPath.isEmpty ? null : File(logoPath);
    final hasLogo = logoFile?.existsSync() ?? false;
    if (!hasLogo) return const SizedBox.shrink();

    final isCircle = _logic.data.logoShape.toLowerCase() == 'circle';

    return Container(
      width: ShopCardStyles.imgBoxSize,
      height: ShopCardStyles.imgBoxSize,
      decoration: BoxDecoration(
        color: ShopCardColors.imgBg,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            isCircle ? null : BorderRadius.circular(ShopCardStyles.imgRadius),
        border: Border.all(
            color: ShopCardColors.borderGold,
            width: ShopCardStyles.imgBorderWidth),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Image.file(
        logoFile!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildToggleButton() {
    return InkWell(
      onTap: _logic.toggleCardExpansion,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: ShopCardColors.borderGold),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _logic.isExpanded ? "HIDE PROFILE" : "VIEW PROFILE",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ShopCardColors.textGold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _logic.isExpanded
                  ? ShopCardIcons.arrowUp
                  : ShopCardIcons.arrowDown,
              color: ShopCardColors.iconGold,
              size: 16,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text,
      {bool isGold = false, bool isLink = false}) {
    if (text.isEmpty || text == "null") return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ShopCardColors.iconGold),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: isLink
                      ? ShopCardStyles.linkStyle
                      : ShopCardStyles.detailTextStyle.copyWith(
                          color: isGold
                              ? ShopCardColors.textGold
                              : ShopCardColors.textSilver),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() => Container(
      height: 150,
      width: double.infinity,
      decoration: ShopCardStyles.premiumCardDecoration
          .copyWith(color: Colors.white.withValues(alpha: 0.05)),
      child: const Center(
          child: CircularProgressIndicator(color: ShopCardColors.textGold)));

  Widget _buildErrorState() => Container(
      height: 150,
      decoration: ShopCardStyles.premiumCardDecoration.copyWith(
          border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.redAccent, size: 30),
        const SizedBox(height: 10),
        Text(_logic.errorMessage ?? "Error",
            style: const TextStyle(color: Colors.redAccent)),
        TextButton(
            onPressed: _logic.retryFetch,
            child: const Text("Retry",
                style: TextStyle(color: ShopCardColors.textGold)))
      ])));
}

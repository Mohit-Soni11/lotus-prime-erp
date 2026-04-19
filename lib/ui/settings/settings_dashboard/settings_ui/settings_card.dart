import 'package:flutter/material.dart';
import '../../../../theme/settings/settings_dashboard/settings_theme.dart'; // Theme Colors & Styles
import '../../../../models/setting/settings_model.dart'; // Model structure samjhne ke liye

class SettingsCard extends StatefulWidget {
  final SettingsModel item;
  final VoidCallback onTap;

  const SettingsCard({
    super.key, 
    required this.item, 
    required this.onTap
  });

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: SettingsStyles.cardPadding,
          
          decoration: SettingsStyles.cardDecoration.copyWith(
            color: _isHovered ? SettingsColors.cardHoverBg : null,
            border: Border.all(
              color: _isHovered ? SettingsColors.accentGold : Colors.white.withOpacity(0.08),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered 
              ? [const BoxShadow(color: SettingsColors.glowGold, blurRadius: 15, offset: Offset(0, 5))] 
              : SettingsStyles.cardDecoration.boxShadow,
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Icon & Arrow ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 32,
                    color: _isHovered ? SettingsColors.accentGold : SettingsColors.textSecondary,
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 1.0 : 0.0,
                    child: const Icon(SettingsIcons.navArrow, size: 16, color: SettingsColors.accentGold),
                  ),
                ],
              ),
              
              // --- Text ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: SettingsStyles.cardTitle.copyWith(
                      color: _isHovered ? SettingsColors.textPrimary : SettingsColors.textSecondary
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.subtitle,
                    style: SettingsStyles.cardSubtitle,
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
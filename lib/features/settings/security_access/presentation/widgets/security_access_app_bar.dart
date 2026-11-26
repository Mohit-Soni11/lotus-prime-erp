import 'package:flutter/material.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

import '../security_access_theme.dart';

class SecurityAccessAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SecurityAccessAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) => Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: SecurityAccessTheme.shell,
          border: Border(
              bottom: BorderSide(color: SecurityAccessTheme.shellBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  fixedSize: const Size(42, 42),
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 18),
              Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.14)),
              const SizedBox(width: 18),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE9C741), SecurityAccessTheme.gold],
                  ),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'SECURITY & ACCESS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SystemStatusBadge(
                status: SystemStatus.online,
                showLabel: true,
              ),
            ],
          ),
        ),
      );
}

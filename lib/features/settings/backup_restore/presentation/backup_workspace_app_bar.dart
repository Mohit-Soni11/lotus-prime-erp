import 'package:flutter/material.dart';
import '../../../../../ui/shared/system_status_badge.dart';
import 'backup_workspace_theme.dart';

class BackupWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BackupWorkspaceAppBar(
      {super.key, required this.onBack, this.busy = false});
  final VoidCallback? onBack;
  final bool busy;
  @override
  Size get preferredSize => const Size.fromHeight(70);
  @override
  Widget build(BuildContext context) => Container(
        height: preferredSize.height,
        color: BackupWorkspaceTheme.navy,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
            bottom: false,
            child: Row(children: [
              IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10)),
                      fixedSize: const Size(42, 42)),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 21)),
              const SizedBox(width: 18),
              Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.14)),
              const SizedBox(width: 18),
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [
                        Color(0xFFE9C741),
                        BackupWorkspaceTheme.gold
                      ])),
                  child: const Icon(Icons.backup_rounded,
                      color: Colors.white, size: 21)),
              const SizedBox(width: 14),
              const Expanded(
                  child: Text('BACKUP & RESTORE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7))),
              const SizedBox(width: 12),
              SystemStatusBadge(
                  status: busy ? SystemStatus.loading : SystemStatus.online,
                  showLabel: MediaQuery.sizeOf(context).width >= 700),
            ])),
      );
}

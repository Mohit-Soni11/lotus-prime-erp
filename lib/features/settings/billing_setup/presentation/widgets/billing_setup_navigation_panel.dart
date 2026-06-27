import 'package:flutter/material.dart';

import '../../domain/entities/billing_setup_module.dart';
import '../theme/billing_setup_design_tokens.dart';

class BillingSetupNavigationPanel extends StatelessWidget {
  final List<BillingSetupModule> modules;
  final ValueChanged<BillingSetupModule> onModuleSelected;

  const BillingSetupNavigationPanel({
    super.key,
    required this.modules,
    required this.onModuleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BillingSetupDesignTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BillingSetupDesignTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(
              'Workspace',
              style: TextStyle(
                color: BillingSetupDesignTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...modules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavigationItem(
                module: module,
                onTap: () => onModuleSelected(module),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatefulWidget {
  final BillingSetupModule module;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.module,
    required this.onTap,
  });

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = BillingSetupDesignTokens.accentFor(widget.module.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? accent.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                BillingSetupDesignTokens.iconFor(widget.module.id),
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.module.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BillingSetupDesignTokens.textStrong,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

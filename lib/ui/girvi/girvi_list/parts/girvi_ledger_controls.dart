part of '../girvi_list_screen.dart';

extension _GirviLedgerControls on _GirviListScreenState {
  Widget _buildLedgerControls() {
    return _LedgerSurface(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final search = _LedgerSearchField(
            controller: _searchController,
            onClear: _clearSearch,
          );
          final action = widget.onNewGirvi == null
              ? null
              : _LedgerPrimaryButton(
                  icon: Icons.add_rounded,
                  label: 'New Girvi',
                  onTap: _openNewGirvi,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                search,
                if (action != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: action),
                ],
              ] else
                Row(
                  children: [
                    Expanded(child: search),
                    if (action != null) ...[
                      const SizedBox(width: 12),
                      action,
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GirviFilter.values.map((filter) {
                  return _LedgerFilterChip(
                    label: filter.displayName,
                    count: _controller.countForFilter(filter),
                    icon: _filterIcon(filter),
                    color: _filterColor(filter),
                    selected: _controller.filter == filter,
                    onTap: () => _setFilter(filter),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LedgerSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _LedgerSearchField({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        style: GoogleFonts.manrope(
          color: GirviColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: GirviColors.inputBg,
          hintText: 'Search ticket, customer, mobile or item',
          hintStyle: GoogleFonts.inter(
            color: GirviColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            GirviIcons.search,
            color: GirviColors.brandGold,
            size: 19,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: GirviColors.textMuted,
                  size: 18,
                ),
              );
            },
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GirviColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GirviColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: GirviColors.brandGold,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LedgerFilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GirviColors.shellBg : color;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 14),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? GirviColors.shellBg.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.manrope(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LedgerPrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: GirviColors.brandGold,
          foregroundColor: GirviColors.shellBg,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

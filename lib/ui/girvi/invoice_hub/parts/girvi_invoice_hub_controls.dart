part of '../girvi_invoice_hub_screen.dart';

extension GirviInvoiceHubControls on _GirviInvoiceHubScreenState {
  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('PAPER SIZE'),
        const SizedBox(height: 10),
        Row(
          children: GirviInvoiceFormat.values.map((format) {
            final selected = _controller.selectedFormat == format;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: format == GirviInvoiceFormat.a4 ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => _controller.switchFormat(format),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? GirviColors.brandGoldLight
                          : GirviColors.shellPanelBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? GirviColors.brandGold
                            : GirviColors.shellBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          format == GirviInvoiceFormat.a4
                              ? Icons.description_outlined
                              : Icons.article_outlined,
                          color: selected
                              ? GirviColors.brandGold
                              : GirviColors.shellTextMuted,
                          size: 23,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          format.label,
                          style: GoogleFonts.inter(
                            color: selected
                                ? GirviColors.brandGold
                                : GirviColors.shellTextTitle,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          format.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOutputOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelLabel('OUTPUT OPTIONS'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GirviColors.shellPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GirviColors.shellBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Copies',
                      style: GoogleFonts.inter(
                        color: GirviColors.shellTextTitle,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.printCopies > 1
                        ? () => _controller.updatePrintOptions(
                              copies: _controller.printCopies - 1,
                              duplicate: _controller.includeDuplicateStamp,
                            )
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: GirviColors.brandGold,
                  ),
                  Text(
                    '${_controller.printCopies}',
                    style: GoogleFonts.manrope(
                      color: GirviColors.brandGold,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.printCopies < 5
                        ? () => _controller.updatePrintOptions(
                              copies: _controller.printCopies + 1,
                              duplicate: _controller.includeDuplicateStamp,
                            )
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: GirviColors.brandGold,
                  ),
                ],
              ),
              const Divider(color: GirviColors.shellBorder, height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reissued Bill',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextTitle,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Use when issuing a replacement receipt',
                          style: GoogleFonts.inter(
                            color: GirviColors.shellTextMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _controller.includeDuplicateStamp,
                    onChanged: (value) => _controller.updatePrintOptions(
                      copies: _controller.printCopies,
                      duplicate: value,
                    ),
                    activeThumbColor: GirviColors.brandGold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: GirviColors.dangerBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GirviColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: GirviColors.danger,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: GirviColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: GirviColors.shellTextMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

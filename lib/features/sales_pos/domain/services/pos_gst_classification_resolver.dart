import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../../../../theme/settings/tax_gst/tax_gst_strings.dart';

class PosGstClassificationLine {
  final String code;
  final String title;
  final String subtitle;
  final String taxLabel;

  const PosGstClassificationLine({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.taxLabel,
  });
}

class PosGstClassificationResolver {
  const PosGstClassificationResolver();

  List<PosGstClassificationLine> resolve({
    required List<SaleItemModel> saleItems,
    required List<HsnCodeModel> hsnCodes,
  }) {
    final activeMetals = saleItems
        .where((item) => item.netWt > 0)
        .map((item) => item.metal)
        .toSet();
    if (activeMetals.isEmpty) {
      return const [];
    }

    final activeProductCodes = hsnCodes
        .where((entry) =>
            entry.isActive &&
            entry.appliesTo == TaxGstStrings.hsnAppliesProductSale)
        .toList(growable: false);

    final lines = <PosGstClassificationLine>[];
    final jewelleryMetals = activeMetals
        .where((metal) => metal != MetalType.diamond)
        .toList(growable: false);
    if (jewelleryMetals.isNotEmpty) {
      final matches = jewelleryMetals
          .map((metal) => _matchForMetal(activeProductCodes, metal))
          .whereType<HsnCodeModel>()
          .toList(growable: false);
      lines.add(
        _buildGroupedLine(
          matches: matches,
          fallbackCode: '7113',
          fallbackRate: '3%',
          title: 'Jewellery Sale',
          subtitle: _metalSubtitle(jewelleryMetals),
        ),
      );
    }

    if (activeMetals.contains(MetalType.diamond)) {
      final diamondMatch =
          _matchForMetal(activeProductCodes, MetalType.diamond);
      lines.add(
        _buildGroupedLine(
          matches: diamondMatch == null ? const [] : [diamondMatch],
          fallbackCode: '7102',
          fallbackRate: '3%',
          title: 'Loose Diamond / Stone',
          subtitle: 'Configured separately from finished jewellery',
        ),
      );
    }

    return lines;
  }

  String? invoiceHsnForMetal({
    required MetalType metal,
    required List<HsnCodeModel> hsnCodes,
  }) {
    final activeProductCodes = hsnCodes
        .where((entry) =>
            entry.isActive &&
            entry.appliesTo == TaxGstStrings.hsnAppliesProductSale)
        .toList(growable: false);
    final match = _matchForMetal(activeProductCodes, metal);
    final code = match?.hsnCode.trim();
    return code == null || code.isEmpty ? null : code;
  }

  HsnCodeModel? _matchForMetal(List<HsnCodeModel> entries, MetalType metal) {
    final keywords = switch (metal) {
      MetalType.gold => const ['gold jewellery', 'gold'],
      MetalType.silver => const ['silver jewellery', 'silver'],
      MetalType.platinum => const ['platinum jewellery', 'platinum'],
      MetalType.diamond => const ['diamond', 'gemstone', 'stone'],
    };

    for (final keyword in keywords) {
      for (final entry in entries) {
        if (entry.normalizedCategory.contains(keyword)) {
          return entry;
        }
      }
    }
    return null;
  }

  PosGstClassificationLine _buildGroupedLine({
    required List<HsnCodeModel> matches,
    required String fallbackCode,
    required String fallbackRate,
    required String title,
    required String subtitle,
  }) {
    final displayCodes = matches
        .map((entry) => entry.billingDisplayCode)
        .where((code) => code.isNotEmpty)
        .toSet();
    final rates = matches
        .map((entry) => entry.gstRate.trim())
        .where((rate) => rate.isNotEmpty)
        .toSet();

    return PosGstClassificationLine(
      code:
          'HSN ${displayCodes.length == 1 ? displayCodes.first : fallbackCode}',
      title: title,
      subtitle: subtitle,
      taxLabel: rates.length == 1 ? 'GST ${rates.first}' : 'GST $fallbackRate',
    );
  }

  String _metalSubtitle(List<MetalType> metals) {
    final labels = metals.map((metal) {
      final display = metal.displayName.toLowerCase();
      return display[0].toUpperCase() + display.substring(1);
    }).toList(growable: false);
    if (labels.length == 1) {
      return '${labels.first} finished jewellery';
    }
    return '${labels.join(' + ')} finished jewellery';
  }
}

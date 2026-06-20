// =============================================================================
// FILE        : stock_item_model.dart
// MODULE      : Stock & Inventory
// LAYER       : Models
// DESCRIPTION : Pure data model for Add Stock form.
//               Logic aur UI ke beech ka bridge. Immutable + copyWith.
// =============================================================================

import 'stock_enums.dart';

class StockItemModel {
  // ── IDENTIFICATION ─────────────────────────────────────────────
  final String sku;
  final String itemName;
  final String? description;

  // ── CLASSIFICATION ─────────────────────────────────────────────
  final StockCategory category;
  final StockSubCategory subCategory;

  // ── METAL ──────────────────────────────────────────────────────
  final MetalType metalType;
  final String? purity;
  final double grossWeight;
  final double stoneWeight;
  final double netWeight;

  // ── STONE ──────────────────────────────────────────────────────
  final StoneType stoneType;
  final double stoneCarats;
  final int stonePieces;

  // ── PRICING ────────────────────────────────────────────────────
  final double makingCharges;
  final MakingChargesType makingChargesType;
  final double purchasePrice;
  final double mrp;

  // ── COMPLIANCE ─────────────────────────────────────────────────
  final String? hsnCode;
  final String? huid;
  final double gstRate;

  // ── INVENTORY ──────────────────────────────────────────────────
  final int quantity;
  final String? rackLocation;
  final String? supplierName;
  final StockStatus status;
  final String? imagePath;

  const StockItemModel({
    required this.sku,
    required this.itemName,
    this.description,
    required this.category,
    required this.subCategory,
    required this.metalType,
    this.purity,
    this.grossWeight = 0.0,
    this.stoneWeight = 0.0,
    this.netWeight = 0.0,
    this.stoneType = StoneType.none,
    this.stoneCarats = 0.0,
    this.stonePieces = 0,
    this.makingCharges = 0.0,
    this.makingChargesType = MakingChargesType.perGram,
    this.purchasePrice = 0.0,
    this.mrp = 0.0,
    this.hsnCode,
    this.huid,
    this.gstRate = 3.0,
    this.quantity = 1,
    this.rackLocation,
    this.supplierName,
    this.status = StockStatus.available,
    this.imagePath,
  });

  static StockItemModel empty() => const StockItemModel(
        sku: '',
        itemName: '',
        category: StockCategory.gold,
        subCategory: StockSubCategory.ring,
        metalType: MetalType.gold,
        purity: '22K (916)',
      );

  StockItemModel copyWith({
    String? sku,
    String? itemName,
    String? description,
    StockCategory? category,
    StockSubCategory? subCategory,
    MetalType? metalType,
    String? purity,
    double? grossWeight,
    double? stoneWeight,
    double? netWeight,
    StoneType? stoneType,
    double? stoneCarats,
    int? stonePieces,
    double? makingCharges,
    MakingChargesType? makingChargesType,
    double? purchasePrice,
    double? mrp,
    String? hsnCode,
    String? huid,
    double? gstRate,
    int? quantity,
    String? rackLocation,
    String? supplierName,
    StockStatus? status,
    String? imagePath,
  }) =>
      StockItemModel(
        sku: sku ?? this.sku,
        itemName: itemName ?? this.itemName,
        description: description ?? this.description,
        category: category ?? this.category,
        subCategory: subCategory ?? this.subCategory,
        metalType: metalType ?? this.metalType,
        purity: purity ?? this.purity,
        grossWeight: grossWeight ?? this.grossWeight,
        stoneWeight: stoneWeight ?? this.stoneWeight,
        netWeight: netWeight ?? this.netWeight,
        stoneType: stoneType ?? this.stoneType,
        stoneCarats: stoneCarats ?? this.stoneCarats,
        stonePieces: stonePieces ?? this.stonePieces,
        makingCharges: makingCharges ?? this.makingCharges,
        makingChargesType: makingChargesType ?? this.makingChargesType,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        mrp: mrp ?? this.mrp,
        hsnCode: hsnCode ?? this.hsnCode,
        huid: huid ?? this.huid,
        gstRate: gstRate ?? this.gstRate,
        quantity: quantity ?? this.quantity,
        rackLocation: rackLocation ?? this.rackLocation,
        supplierName: supplierName ?? this.supplierName,
        status: status ?? this.status,
        imagePath: imagePath ?? this.imagePath,
      );
}

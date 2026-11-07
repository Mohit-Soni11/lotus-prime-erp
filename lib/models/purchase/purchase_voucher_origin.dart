enum PurchaseVoucherOrigin {
  addStock('ADD_STOCK'),
  customerMetalPurchase('CUSTOMER_METAL_PURCHASE'),
  bookingAdvanceMetal('BOOKING_ADVANCE_METAL'),
  supplierPurchase('SUPPLIER_PURCHASE'),
  legacy('LEGACY');

  const PurchaseVoucherOrigin(this.storageValue);

  final String storageValue;
}

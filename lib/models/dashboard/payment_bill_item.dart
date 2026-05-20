// =============================================================================
// FILE        : payment_bill_item.dart
// MODULE      : Dashboard / Payment Status
// LAYER       : Models
// DESCRIPTION : Ek bill ka complete payment snapshot.
//               Bills table + Customers table se join karke banta hai.
// =============================================================================

/// Payment ke 3 states — Python design se same
enum PaymentStatus {
  paid, // paidAmount >= finalAmount → Green
  partial, // 0 < paidAmount < finalAmount → Amber/Gold
  unpaid, // paidAmount == 0 → Red
}

/// Ek bill ka complete data — UI row ke liye
class PaymentBillItem {
  final int billId;
  final String billNo;
  final String customerName;
  final String customerInitials; // Avatar ke liye
  final int? customerId; // Profile navigate ke liye
  final String mobile;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount; // totalAmount - paidAmount
  final DateTime billDate;
  final PaymentStatus status;

  const PaymentBillItem({
    required this.billId,
    required this.billNo,
    required this.customerName,
    required this.customerInitials,
    required this.customerId,
    required this.mobile,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.billDate,
    required this.status,
  });

  /// Status compute karo amounts se
  static PaymentStatus computeStatus(double paid, double total) {
    if (total <= 0) return PaymentStatus.paid;
    if (paid >= total) return PaymentStatus.paid;
    if (paid > 0) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  /// Customer name se initials nikalo
  static String extractInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '??';
    final words = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return cleaned.substring(0, cleaned.length >= 2 ? 2 : 1).toUpperCase();
  }
}

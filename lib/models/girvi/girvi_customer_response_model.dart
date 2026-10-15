enum GirviCustomerResponseKind {
  willVisit('WILL_VISIT', 'Will visit the shop', true),
  fullSettlement('FULL_SETTLEMENT', 'Promises full settlement', true),
  partialPayment('PARTIAL_PAYMENT', 'Promises partial payment', true),
  extensionRequest('EXTENSION_REQUEST', 'Requests more time', true),
  amountDispute('AMOUNT_DISPUTE', 'Disputes the account amount', false),
  recoveryRequest('RECOVERY_REQUEST', 'Requests recovery settlement', false),
  noResponse('NO_RESPONSE', 'No response received', false),
  other('OTHER', 'Other response', false);

  const GirviCustomerResponseKind(this.dbValue, this.label, this.isPromise);

  final String dbValue;
  final String label;
  final bool isPromise;

  static GirviCustomerResponseKind fromDb(String value) =>
      values.firstWhere((kind) => kind.dbValue == value, orElse: () => other);
}

enum GirviContactChannel {
  shopVisit('SHOP_VISIT', 'Shop visit'),
  phoneCall('PHONE_CALL', 'Phone call'),
  whatsapp('WHATSAPP', 'WhatsApp'),
  sms('SMS', 'SMS'),
  email('EMAIL', 'Email'),
  registeredPost('REGISTERED_POST', 'Registered post'),
  other('OTHER', 'Other');

  const GirviContactChannel(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static GirviContactChannel fromDb(String value) => values.firstWhere(
        (channel) => channel.dbValue == value,
        orElse: () => other,
      );
}

enum GirviPromiseStatus {
  open('OPEN', 'Open'),
  fulfilled('FULFILLED', 'Fulfilled'),
  partiallyFulfilled('PARTIALLY_FULFILLED', 'Partially fulfilled'),
  missed('MISSED', 'Missed'),
  cancelled('CANCELLED', 'Cancelled'),
  recorded('RECORDED', 'Recorded');

  const GirviPromiseStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  bool get isOpen => this == open;
  bool get isResolved => !isOpen;

  static GirviPromiseStatus fromDb(String value) => values.firstWhere(
        (status) => status.dbValue == value,
        orElse: () => recorded,
      );
}

class GirviCustomerResponse {
  const GirviCustomerResponse({
    required this.id,
    required this.girviId,
    required this.kind,
    required this.channel,
    required this.responseText,
    required this.status,
    required this.receivedAt,
    required this.createdAt,
    this.noticeActionId,
    this.noticeStage,
    this.promisedAmount,
    this.promiseDueAt,
    this.resolvedAt,
    this.resolutionNote,
    this.proofReference,
    this.performedBy,
    this.updatedAt,
  });

  final int id;
  final int girviId;
  final int? noticeActionId;
  final int? noticeStage;
  final GirviCustomerResponseKind kind;
  final GirviContactChannel channel;
  final String responseText;
  final double? promisedAmount;
  final DateTime? promiseDueAt;
  final GirviPromiseStatus status;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String? proofReference;
  final DateTime receivedAt;
  final String? performedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isPromise => kind.isPromise;

  bool isDueOn(DateTime now) =>
      status.isOpen &&
      promiseDueAt != null &&
      DateTime(now.year, now.month, now.day)
          .isAfter(DateTime(promiseDueAt!.year, promiseDueAt!.month, promiseDueAt!.day));
}

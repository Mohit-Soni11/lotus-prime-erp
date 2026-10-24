enum GirviCustomerResponseKind {
  willVisit('WILL_VISIT', 'Will visit the shop', true),
  extensionRequest('EXTENSION_REQUEST', 'Requests more time', true),
  recoveryRequest('RECOVERY_REQUEST', 'Requests recovery settlement', false),
  noResponse('NO_RESPONSE', 'No response received', false),
  holdRequest('HOLD_REQUEST', 'Requests account hold', true);

  const GirviCustomerResponseKind(
      this.dbValue, this.label, this.requiresFollowUpDate);

  final String dbValue;
  final String label;
  final bool requiresFollowUpDate;

  bool get authorisesRecovery => this == recoveryRequest;

  static GirviCustomerResponseKind fromDb(String value) => values.firstWhere(
        (kind) => kind.dbValue == value,
        orElse: () => noResponse,
      );
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
  fulfilled('FULFILLED', 'Completed'),
  missed('MISSED', 'Not kept'),
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
    this.promiseDueAt,
    this.resolvedAt,
    this.resolutionNote,
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
  final DateTime? promiseDueAt;
  final GirviPromiseStatus status;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final DateTime receivedAt;
  final String? performedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get requiresFollowUpDate => kind.requiresFollowUpDate;

  bool isDueOn(DateTime now) =>
      status.isOpen &&
      promiseDueAt != null &&
      DateTime(now.year, now.month, now.day).isAfter(
          DateTime(promiseDueAt!.year, promiseDueAt!.month, promiseDueAt!.day));
}

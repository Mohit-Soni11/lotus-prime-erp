/// Keeps an edited notice tied to the verified account statement used to
/// generate it. Operators may reword the action paragraphs, but account facts,
/// amounts, and the selected response date must remain unchanged.
class GirviNoticeApprovalValidator {
  const GirviNoticeApprovalValidator._();

  static String? validate({
    required String generatedText,
    required String approvedText,
  }) {
    final generated = _normalize(generatedText);
    final approved = _normalize(approvedText);
    if (generated == approved) return null;

    const actionHeading = 'Required Action';
    final generatedAction = generated.indexOf('\n$actionHeading\n');
    final approvedAction = approved.indexOf('\n$actionHeading\n');
    if (generatedAction < 0 || approvedAction < 0) {
      return 'Keep the verified account statement and Required Action section in the notice.';
    }
    if (generated.substring(0, generatedAction) !=
        approved.substring(0, approvedAction)) {
      return 'Account, customer, item, interest, and payment details cannot be edited in the notice. Refresh the account record first.';
    }

    final generatedActionText = generated.substring(generatedAction);
    final approvedActionText = approved.substring(approvedAction);
    if (!_sameTokens(generatedActionText, approvedActionText,
        RegExp(r'(?:Rs|₹)\s*[\d,]+(?:\.\d{1,2})?'))) {
      return 'The outstanding amount in Required Action must match the verified account.';
    }
    if (!_sameTokens(generatedActionText, approvedActionText,
        RegExp(r'\b\d{1,2}\s+[A-Za-z]+\s+\d{4}\b'))) {
      return 'The response date in Required Action must match the selected period.';
    }
    return null;
  }

  static String _normalize(String value) => value
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .trim();

  static bool _sameTokens(String first, String second, RegExp pattern) {
    final firstValues =
        pattern.allMatches(first).map((match) => match.group(0)).toList();
    final secondValues =
        pattern.allMatches(second).map((match) => match.group(0)).toList();
    if (firstValues.length != secondValues.length) return false;
    for (var index = 0; index < firstValues.length; index++) {
      if (firstValues[index] != secondValues[index]) return false;
    }
    return true;
  }
}

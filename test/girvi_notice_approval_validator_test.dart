import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/notice/girvi_notice_approval_validator.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  final item = createNoticeCase(simple: false);
  final generated = GirviNoticeGenerationService(
    now: item.now,
    shopName: 'Test Jewellers',
  ).build(
    item: item,
    noticeType: GirviNoticeType.formal,
    language: GirviNoticeLanguage.english,
    noticePeriodDays: 7,
  );

  test('allows action wording edits without changing verified facts', () {
    final edited = generated.replaceFirst(
      'Please settle the account or contact us within the above period to avoid this action.',
      'Please contact our shop within the above period to avoid this action.',
    );
    expect(
      GirviNoticeApprovalValidator.validate(
        generatedText: generated,
        approvedText: edited,
      ),
      isNull,
    );
  });

  test('rejects changes to the account statement', () {
    final edited = generated.replaceFirst(
        'Principal Amount: Rs ', 'Principal Amount: Rs 99,');
    expect(
      GirviNoticeApprovalValidator.validate(
        generatedText: generated,
        approvedText: edited,
      ),
      contains('cannot be edited'),
    );
  });

  test('rejects changes to the action amount or response date', () {
    final changedAmount = generated.replaceFirst(
      RegExp(r'Please pay the Total Outstanding Amount of Rs [\d,]+'),
      'Please pay the Total Outstanding Amount of Rs 1',
    );
    expect(
      GirviNoticeApprovalValidator.validate(
        generatedText: generated,
        approvedText: changedAmount,
      ),
      contains('outstanding amount'),
    );
    final changedDate = generated.replaceFirst(
      'on or before 11 October 2026',
      'on or before 12 October 2026',
    );
    expect(
      GirviNoticeApprovalValidator.validate(
        generatedText: generated,
        approvedText: changedDate,
      ),
      contains('response date'),
    );
  });
}

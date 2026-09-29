import 'package:intl/intl.dart';

import '../../models/girvi/contact_recovery_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import 'girvi_interest_period_text.dart';

class GirviNoticeGenerationService {
  GirviNoticeGenerationService({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;
  final _date = DateFormat('dd MMMM yyyy');
  final _money = NumberFormat('#,##,##0', 'en_IN');

  List<String> validate(ContactRecoveryCase item) {
    final issues = <String>[];
    final account = item.account;
    final financialValues = <String, double>{
      'principal outstanding': account.principalDue,
      'interest outstanding': account.netInterestDue,
      'total payable': account.totalPayable,
      'interest received': account.interestPaidTotal,
      'interest discount': account.interestDiscountTotal,
      'principal received': account.principalPaidTotal,
      'principal discount': account.principalDiscountTotal,
    };

    for (final entry in financialValues.entries) {
      if (_invalidMoney(entry.value)) {
        issues.add('Invalid ${entry.key} found in account ledger.');
      }
    }

    final expectedTotal = account.principalDue + account.netInterestDue;
    if ((account.totalPayable - expectedTotal).abs() > 1) {
      issues.add(
        'Account totals are inconsistent. Principal plus interest does not match total payable.',
      );
    }

    for (final payment in _interestLedger(item)) {
      if (_invalidMoney(payment.amount) ||
          _invalidMoney(payment.interestComponent) ||
          _invalidMoney(payment.interestDiscountComponent) ||
          _invalidMoney(payment.balanceAfter)) {
        issues.add(
          'Invalid interest ledger amount found for ${date(payment.paymentDate)}.',
        );
      }
      final months = payment.monthsCovered ?? 0;
      if (months > 0 &&
          (payment.interestFromDate == null ||
              payment.interestToDate == null)) {
        issues.add(
          'Interest ledger period is incomplete for ${date(payment.paymentDate)}.',
        );
      }
    }

    return issues.toSet().toList(growable: false);
  }

  Map<GirviNoticeLanguage, String> buildAll({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
  }) {
    return {
      GirviNoticeLanguage.hindi: build(
        item: item,
        noticeType: noticeType,
        language: GirviNoticeLanguage.hindi,
      ),
      GirviNoticeLanguage.english: build(
        item: item,
        noticeType: noticeType,
        language: GirviNoticeLanguage.english,
      ),
    };
  }

  String build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
  }) {
    return language == GirviNoticeLanguage.hindi
        ? _buildHindi(item, noticeType)
        : _buildEnglish(item, noticeType);
  }

  String _buildEnglish(ContactRecoveryCase item, GirviNoticeType noticeType) {
    final data = _NoticeData(item: item, noticeType: noticeType, service: this);
    final tone = _englishTone(noticeType);
    final lines = <String>[
      'Subject: ${tone.subject}',
      '',
      'Dear ${data.customerName},',
      '',
      tone.opening,
      '',
      'Notice Details',
      'Notice Date: ${data.noticeDate}',
      'Notice Stage: ${noticeType.stage}/3',
      'Invoice Number: ${data.ticketNo}',
      'Customer Mobile: ${data.mobile}',
      'Customer Address: ${data.address}',
      '',
      'Pledge Account Details',
      'Pledge Date: ${data.startDate}',
      'Maturity Date: ${data.maturityDate}',
      '',
      'Duration and Interest Period',
      'Actual Duration: ${data.actualDuration}',
      'Total Calendar Duration: ${data.calendarDuration}',
      'Chargeable Interest Period: ${data.chargeablePeriod}',
      'Period Basis: Actual duration is the calendar time from pledge date to notice date. Chargeable interest period is read from the verified account interest record and is used for financial settlement.',
      '',
      'Overdue Period: ${data.overdueAge}',
      'Recorded Interest Method: ${data.interestType}',
      'Recorded Interest Rate: ${data.interestRate}',
      '',
      'Pledged Item Details',
      'Item: ${data.itemSummary}',
      'Gross Weight: ${data.grossWeight}',
      'Net Weight: ${data.netWeight}',
      'Valuation: ${data.valuation}',
      '',
      'Verified Ledger Summary',
      'Principal Outstanding: ${data.principalDue}',
      'Interest Received / Adjusted: ${data.interestCredit}',
      'Interest Outstanding: ${data.interestDue}',
      'Total Payable: ${data.totalPayable}',
      '',
      'Recorded Interest Ledger',
      ...data.englishLedgerLines,
      if (data.englishCompoundLines.isNotEmpty) ...[
        '',
        'Recorded Compound Interest Breakdown',
        ...data.englishCompoundLines,
      ],
      '',
      'Requested Action',
      'Please visit the shop or contact the shop on the provided contact number before ${data.deadline} to complete payment, settlement, or an acceptable resolution.',
      '',
      tone.closing,
      '',
      'This notice is prepared from the verified account and interest ledger records. The notice generator does not calculate or add any separate financial amount.',
      '',
      'Authorised Signatory',
    ];
    return lines.join('\n');
  }

  String _buildHindi(ContactRecoveryCase item, GirviNoticeType noticeType) {
    final data = _NoticeData(item: item, noticeType: noticeType, service: this);
    final tone = _hindiTone(noticeType);
    final lines = <String>[
      'विषय: ${tone.subject}',
      '',
      'प्रिय ${data.customerName},',
      '',
      tone.opening,
      '',
      'सूचना विवरण',
      'सूचना दिनांक: ${data.noticeDate}',
      'सूचना चरण: ${noticeType.stage}/3',
      'इनवॉइस नंबर: ${data.ticketNo}',
      'ग्राहक मोबाइल: ${data.mobile}',
      'ग्राहक पता: ${data.addressHindi}',
      '',
      'गिरवी खाता विवरण',
      'गिरवी तारीख: ${data.startDate}',
      'परिपक्वता तारीख: ${data.maturityDate}',
      '',
      'अवधि और ब्याज गणना अवधि',
      'वास्तविक अवधि: ${data.actualDuration}',
      'कुल कैलेंडर अवधि: ${data.calendarDuration}',
      'चार्जेबल ब्याज अवधि: ${data.chargeablePeriod}',
      'अवधि आधार: वास्तविक अवधि गिरवी तारीख से सूचना तारीख तक का कैलेंडर समय है। चार्जेबल ब्याज अवधि सत्यापित खाते के ब्याज रिकॉर्ड से ली गई है और वित्तीय निपटान के लिए उपयोग होती है।',
      '',
      'बकाया अवधि: ${data.overdueAge}',
      'रिकॉर्डेड ब्याज पद्धति: ${data.interestTypeHindi}',
      'रिकॉर्डेड ब्याज दर: ${data.interestRate}',
      '',
      'गिरवी वस्तु विवरण',
      'वस्तु: ${data.itemSummaryHindi}',
      'कुल वजन: ${data.grossWeight}',
      'नेट वजन: ${data.netWeight}',
      'मूल्यांकन: ${data.valuation}',
      '',
      'सत्यापित लेजर सारांश',
      'मूलधन बकाया: ${data.principalDue}',
      'प्राप्त / समायोजित ब्याज: ${data.interestCredit}',
      'ब्याज बकाया: ${data.interestDue}',
      'कुल देय राशि: ${data.totalPayable}',
      '',
      'रिकॉर्डेड ब्याज लेजर',
      ...data.hindiLedgerLines,
      if (data.hindiCompoundLines.isNotEmpty) ...[
        '',
        'रिकॉर्डेड चक्रवृद्धि ब्याज विवरण',
        ...data.hindiCompoundLines,
      ],
      '',
      'आवश्यक कार्रवाई',
      'कृपया ${data.deadline} से पहले दुकान पर आएं या दिए गए संपर्क नंबर पर संपर्क करके भुगतान, निपटान या स्वीकार्य समाधान पूरा करें।',
      '',
      tone.closing,
      '',
      'यह सूचना सत्यापित खाते और ब्याज लेजर रिकॉर्ड के आधार पर तैयार की गई है। सूचना प्रणाली अपनी तरफ से कोई अलग वित्तीय गणना या अतिरिक्त राशि नहीं जोड़ती है।',
      '',
      'अधिकृत हस्ताक्षर',
    ];
    return lines.join('\n');
  }

  _NoticeTone _englishTone(GirviNoticeType type) {
    switch (type) {
      case GirviNoticeType.first:
        return const _NoticeTone(
          subject: 'First Pledge Account Reminder',
          opening:
              'This is a professional reminder that the pledge account below has remained unpaid after maturity. The purpose of this notice is to request timely contact and settlement based on the current account record.',
          closing:
              'This is the first notice. Please treat it as a request to regularise the account and avoid escalation.',
        );
      case GirviNoticeType.second:
        return const _NoticeTone(
          subject: 'Second Pledge Account Follow-up Notice',
          opening:
              'The account remains unresolved after the earlier notice. This second notice requests immediate attention to the pending dues and account settlement.',
          closing:
              'If the account is not regularised within the notice period, the case may move to final notice review according to applicable terms and policy.',
        );
      case GirviNoticeType.finalNotice:
        return const _NoticeTone(
          subject: 'Final Pledge Redemption and Recovery Notice',
          opening:
              'This is the final notice for the pledge account below. The customer is requested to respond, pay, settle, or provide an acceptable resolution within the prescribed period.',
          closing:
              'If no response, payment, settlement, or acceptable action is received within the prescribed period, the pledged item may be sent to the recovery process according to the applicable agreement, business policy and law, including sale or melting where legally permitted. Recovery proceeds may be adjusted against outstanding principal, interest and valid charges. Any legally recoverable remaining balance, if any, will be handled according to applicable terms and law.',
        );
    }
  }

  _NoticeTone _hindiTone(GirviNoticeType type) {
    switch (type) {
      case GirviNoticeType.first:
        return const _NoticeTone(
          subject: 'पहली गिरवी खाता स्मरण सूचना',
          opening:
              'यह एक पेशेवर स्मरण सूचना है कि नीचे दिया गया गिरवी खाता परिपक्वता के बाद भी लंबित है। इस सूचना का उद्देश्य वर्तमान खाते के रिकॉर्ड के आधार पर समय पर संपर्क और निपटान का अनुरोध करना है।',
          closing:
              'यह पहली सूचना है। कृपया खाते को नियमित करने और आगे की कार्रवाई से बचने के लिए इसे गंभीरता से लें।',
        );
      case GirviNoticeType.second:
        return const _NoticeTone(
          subject: 'दूसरी गिरवी खाता अनुवर्ती सूचना',
          opening:
              'पहली सूचना के बाद भी खाता लंबित है। यह दूसरी सूचना बकाया राशि और खाते के निपटान पर तुरंत ध्यान देने के लिए जारी की जा रही है।',
          closing:
              'यदि सूचना अवधि में खाता नियमित नहीं किया जाता है, तो मामला लागू शर्तों और नीति के अनुसार अंतिम सूचना समीक्षा में जा सकता है।',
        );
      case GirviNoticeType.finalNotice:
        return const _NoticeTone(
          subject: 'अंतिम गिरवी छुड़ाने और वसूली सूचना',
          opening:
              'यह नीचे दिए गए गिरवी खाते की अंतिम सूचना है। ग्राहक से अनुरोध है कि निर्धारित अवधि में जवाब दें, भुगतान करें, निपटान करें या कोई स्वीकार्य समाधान दें।',
          closing:
              'यदि निर्धारित अवधि में ग्राहक की ओर से कोई जवाब, भुगतान, निपटान या स्वीकार्य कार्रवाई प्राप्त नहीं होती है, तो गिरवी वस्तु को लागू समझौते, व्यापार नीति और कानून के अनुसार वसूली प्रक्रिया में भेजा जा सकता है, जिसमें कानूनन अनुमति होने पर बिक्री या गलाना शामिल हो सकता है। प्राप्त वसूली राशि को बकाया मूलधन, ब्याज और वैध शुल्कों में समायोजित किया जा सकता है। यदि कोई कानूनी रूप से वसूल योग्य शेष राशि बचती है, तो उसे लागू शर्तों और कानून के अनुसार संभाला जाएगा।',
        );
    }
  }

  String money(double value) => 'Rs ${_money.format(value.round())}';

  String date(DateTime? value) =>
      value == null ? 'Not set' : _date.format(value);

  bool _invalidMoney(double value) =>
      value.isNaN || value.isInfinite || value < -0.01;

  List<GirviPaymentModel> _interestLedger(ContactRecoveryCase item) {
    return item.paymentHistory.where(_isInterestLedgerEntry).toList()
      ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
  }

  bool _isInterestLedgerEntry(GirviPaymentModel payment) {
    final type = payment.type;
    if (type == GirviPaymentType.interest ||
        type == GirviPaymentType.partialInterest) {
      return true;
    }
    if (type == GirviPaymentType.fullRelease) {
      return payment.interestComponent > 0 ||
          payment.interestDiscountComponent > 0;
    }
    return payment.interestComponent > 0 ||
        payment.interestDiscountComponent > 0;
  }
}

class _NoticeData {
  _NoticeData({
    required this.item,
    required this.noticeType,
    required this.service,
  });

  final ContactRecoveryCase item;
  final GirviNoticeType noticeType;
  final GirviNoticeGenerationService service;

  GirviLoanWithCustomer get account => item.account;
  GirviLoanModel get loan => item.loan;

  String get ticketNo => loan.ticketNo;
  String get customerName => account.customerName;
  String get mobile => account.customerMobile;
  String get address => account.customerAddress.trim().isEmpty
      ? 'Not available'
      : account.customerAddress.trim();
  String get addressHindi => account.customerAddress.trim().isEmpty
      ? 'उपलब्ध नहीं'
      : account.customerAddress.trim();
  String get noticeDate => service.date(service._now);
  String get startDate => service.date(loan.startDate);
  String get maturityDate => service.date(loan.maturityDate);
  String get deadline =>
      service.date(service._now.add(Duration(days: item.noticePeriodDays)));
  String get actualDuration => item.loanAgeLabel;
  String get calendarDuration => item.loanAgeMonthsDaysLabel;
  String get chargeablePeriod => item.chargeableInterestMonthsLabel;
  String get overdueAge => item.overdueAgeMonthsDaysLabel;
  String get interestType => account.interestType;
  String get interestTypeHindi =>
      GirviInterestCalculationType.isSimple(account.interestType)
          ? 'साधारण ब्याज'
          : 'चक्रवृद्धि ब्याज';
  String get interestRate => '${loan.interestRate.toStringAsFixed(2)}% monthly';
  String get itemSummary =>
      _cleanItemSummary(loan.itemDescription.trim().isEmpty
          ? loan.itemSummary
          : loan.itemDescription.trim());
  String get itemSummaryHindi => itemSummary
      .replaceAll('Serial Number', 'क्रमांक')
      .replaceAll('Gold', 'सोना')
      .replaceAll('Net Weight', 'नेट वजन');
  String get grossWeight => '${loan.grossWeight.toStringAsFixed(3)} g';
  String get netWeight => '${loan.netWeight.toStringAsFixed(3)} g';
  String get valuation => service.money(loan.totalValue);
  String get principalDue => service.money(account.principalDue);
  String get interestDue => service.money(account.netInterestDue);
  String get interestCredit {
    final credit = account.interestPaidTotal + account.interestDiscountTotal;
    return service.money(credit);
  }

  String get totalPayable => service.money(account.totalPayable);

  List<String> get englishLedgerLines {
    final entries = service._interestLedger(item);
    if (entries.isEmpty) {
      return [
        'No interest collection entry is recorded for this account. Current outstanding values are taken from the verified account ledger snapshot.',
      ];
    }
    return [
      for (var index = 0; index < entries.length; index++)
        _ledgerLine(entries[index], index + 1, isHindi: false),
    ];
  }

  List<String> get hindiLedgerLines {
    final entries = service._interestLedger(item);
    if (entries.isEmpty) {
      return [
        'इस खाते में अभी कोई ब्याज भुगतान लेजर एंट्री दर्ज नहीं है। वर्तमान बकाया राशि सत्यापित खाते के लेजर सारांश से ली गई है।',
      ];
    }
    return [
      for (var index = 0; index < entries.length; index++)
        _ledgerLine(entries[index], index + 1, isHindi: true),
    ];
  }

  List<String> get englishCompoundLines {
    final lines = item.compoundInterestBreakdown;
    if (lines.isEmpty) return const [];
    return [
      for (final line in lines) ...[
        _compoundTitle(line, isHindi: false),
        'Opening Amount: ${service.money(line.principalBase)}',
        'Monthly Interest Rate: ${line.monthlyRatePercent.toStringAsFixed(2)}%',
        'Interest per Month: ${service.money(line.monthlyInterest)}',
        'Applicable Period: ${line.months} month${line.months == 1 ? '' : 's'}',
        'Interest for ${_compoundCycleName(line, isHindi: false)}: ${service.money(line.interestAmount)}',
        'Closing Amount after ${_compoundCycleName(line, isHindi: false)}: ${service.money(line.closingAmount)}',
      ],
    ];
  }

  List<String> get hindiCompoundLines {
    final lines = item.compoundInterestBreakdown;
    if (lines.isEmpty) return const [];
    return [
      for (final line in lines) ...[
        _compoundTitle(line, isHindi: true),
        'ओपनिंग राशि: ${service.money(line.principalBase)}',
        'मासिक ब्याज दर: ${line.monthlyRatePercent.toStringAsFixed(2)}%',
        'एक माह का ब्याज: ${service.money(line.monthlyInterest)}',
        'लागू अवधि: ${line.months} माह',
        '${_compoundCycleName(line, isHindi: true)} का ब्याज: ${service.money(line.interestAmount)}',
        '${_compoundCycleName(line, isHindi: true)} के बाद क्लोजिंग राशि: ${service.money(line.closingAmount)}',
      ],
    ];
  }

  String _ledgerLine(
    GirviPaymentModel payment,
    int index, {
    required bool isHindi,
  }) {
    final period = _interestPeriodLabel(payment, isHindi: isHindi);
    final amount = payment.interestComponent > 0
        ? payment.interestComponent
        : payment.amount;
    final discount = payment.interestDiscountComponent > 0
        ? isHindi
            ? ', ब्याज छूट ${service.money(payment.interestDiscountComponent)}'
            : ', interest discount ${service.money(payment.interestDiscountComponent)}'
        : '';
    final balance = service.money(payment.balanceAfter);
    final mode = payment.mode.displayName;
    if (isHindi) {
      return '$index. ${service.date(payment.paymentDate)} | $mode | अवधि $period | ब्याज प्राप्त ${service.money(amount)}$discount | शेष $balance';
    }
    return '$index. ${service.date(payment.paymentDate)} | $mode | Period $period | Interest received ${service.money(amount)}$discount | Balance after $balance';
  }

  String _interestPeriodLabel(
    GirviPaymentModel payment, {
    required bool isHindi,
  }) {
    final from = payment.interestFromDate;
    final to = payment.interestToDate;
    final months = payment.monthsCovered ?? 0;
    final monthLabel = months <= 0
        ? null
        : isHindi
            ? '$months माह'
            : '$months month${months == 1 ? '' : 's'}';
    if (from != null && to != null) {
      final range = '${service.date(from)} to ${service.date(to)}';
      return monthLabel == null ? range : '$range ($monthLabel)';
    }
    if (monthLabel != null) return monthLabel;
    return isHindi ? 'लेजर में अवधि दर्ज नहीं' : 'period not recorded';
  }

  String _compoundTitle(
    GirviInterestBreakdownLine line, {
    required bool isHindi,
  }) {
    final period = GirviInterestPeriodText.forBreakdownLine(
      loanStartDate: loan.startDate,
      line: line,
    );
    final cycle = _compoundCycleName(line, isHindi: isHindi);
    return isHindi
        ? '$cycle - ${period.monthRangeLabel}'
        : '$cycle - ${period.monthRangeLabel}';
  }

  String _compoundCycleName(
    GirviInterestBreakdownLine line, {
    required bool isHindi,
  }) {
    if (line.months == GirviLoanModel.compoundCycleMonths) {
      return isHindi ? 'वर्ष ${line.cycleNumber}' : 'Year ${line.cycleNumber}';
    }
    return isHindi ? 'अवधि ${line.cycleNumber}' : 'Period ${line.cycleNumber}';
  }

  String _cleanItemSummary(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => 'Serial Number ${match.group(1)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _NoticeTone {
  final String subject;
  final String opening;
  final String closing;

  const _NoticeTone({
    required this.subject,
    required this.opening,
    required this.closing,
  });
}

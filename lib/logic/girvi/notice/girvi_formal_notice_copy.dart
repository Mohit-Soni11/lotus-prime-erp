part of '../girvi_notice_generation_service.dart';

/// One customer-facing notice; account facts come from the verified timeline.
class _NoticeCopy {
  const _NoticeCopy({
    required this.title,
    required this.subject,
    required this.opening,
    required this.accountContext,
    required this.requiredAction,
    required this.closing,
  });

  final String title;
  final String Function(_NoticeData data) subject;
  final String Function(_NoticeData data) opening;
  final String Function(_NoticeData data) accountContext;
  final String Function(_NoticeData data) requiredAction;
  final String Function(_NoticeData data) closing;

  factory _NoticeCopy.forLanguage(GirviNoticeLanguage language) {
    final hindi = language == GirviNoticeLanguage.hindi;
    return _NoticeCopy(
      title: hindi ? 'गिरवी खाता सूचना' : 'PLEDGE ACCOUNT NOTICE',
      subject: (data) => hindi
          ? 'गिरवी खाता ${data.ticketNo} की बकाया राशि के भुगतान की सूचना'
          : 'Request for Settlement of Outstanding Balance — Pledge Account ${data.ticketNo}',
      opening: (data) => hindi
          ? 'हमारे रिकॉर्ड के अनुसार, ${data.startDate} को शुरू हुआ गिरवी खाता ${data.ticketNo}, ${data.maturityDate} को परिपक्व हुआ। ${data.noticeDate} तक खाते में बकाया राशि शेष है।'
          : 'As per our records, pledge account ${data.ticketNo}, opened on ${data.startDate}, matured on ${data.maturityDate}. A balance remains outstanding as of ${data.noticeDate}.',
      accountContext: (data) => hindi
          ? 'कुल ब्याज गणना अवधि ${data.chargeablePeriod} है। नीचे दिए गए हिसाब में दर्ज भुगतान और स्वीकृत छूट शामिल हैं।'
          : 'The total interest calculation period is ${data.chargeablePeriod}. The account summary reflects recorded payments and approved discounts.',
      requiredAction: (data) => hindi
          ? 'कृपया ${data.responseDueDate} तक ${data.finalOutstanding} का भुगतान करें या खाते का मिलान और भुगतान व्यवस्था के लिए दुकान से संपर्क करें। किसी भुगतान के दर्ज न होने या हिसाब से असहमति होने पर उसका प्रमाण या विवरण साझा करें।'
          : 'Please pay ${data.finalOutstanding} on or before ${data.responseDueDate}, or contact the shop to reconcile the account and discuss payment arrangements. If you believe a payment is unrecorded or an entry is disputed, please share the details or proof.',
      closing: (_) => hindi
          ? 'बकाया का समाधान न होने पर लागू कानून और आवश्यक सूचना प्रक्रिया के अनुसार गिरवी वस्तु की बिक्री द्वारा वसूली पर कार्रवाई की जा सकती है। यह सूचना या इसका जवाब न मिलना अपने आप वस्तु का स्वामित्व नहीं बदलता और वस्तु को गलाने की सहमति नहीं है।'
          : 'If the outstanding balance remains unresolved, recovery through sale of the pledged item may be pursued in accordance with applicable law and the required notice process. This notice or the absence of a reply does not itself transfer ownership or constitute consent to melt the item.',
    );
  }
}

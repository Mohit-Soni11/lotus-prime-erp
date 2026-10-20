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
  final String subject;
  final String Function(_NoticeData data) opening;
  final String Function(_NoticeData data) accountContext;
  final String Function(_NoticeData data) requiredAction;
  final String Function(_NoticeData data) closing;

  factory _NoticeCopy.forLanguage(GirviNoticeLanguage language) {
    final hindi = language == GirviNoticeLanguage.hindi;
    return _NoticeCopy(
      title: hindi ? 'गिरवी खाता सूचना' : 'PLEDGE ACCOUNT NOTICE',
      subject: hindi
          ? 'गिरवी खाते का बकाया भुगतान और प्रस्तावित वसूली'
          : 'Outstanding Pledge Account Payment and Proposed Recovery',
      opening: (data) => hindi
          ? 'हमारे रिकॉर्ड के अनुसार, आपके गिरवी खाता संख्या ${data.ticketNo} की भुगतान तारीख ${data.maturityDate} थी। खाते में अभी बकाया राशि शेष है।'
          : 'According to our records, payment for pledge account ${data.ticketNo} was due on ${data.maturityDate}. An outstanding balance remains on the account.',
      accountContext: (data) => hindi
          ? 'दिनांक ${data.noticeDate} तक दर्ज भुगतान और स्वीकृत समायोजन नीचे दिए गए हिसाब में शामिल हैं। कृपया खाते और गिरवी वस्तु का विवरण ध्यान से देखें।'
          : 'The statement below includes recorded payments and approved adjustments as of ${data.noticeDate}. Please review the account and pledged-item details.',
      requiredAction: (data) => hindi
          ? 'कृपया यह सूचना प्राप्त होने के ${data.noticeReviewPeriod} के भीतर बकाया भुगतान करें या खाते का मिलान और भुगतान व्यवस्था के लिए दुकान से संपर्क करें। किसी भुगतान के दर्ज न होने या हिसाब से असहमति होने पर उसका प्रमाण या विवरण साझा करें।'
          : 'Please pay the outstanding amount within ${data.noticeReviewPeriod} after receiving this notice, or contact the shop to reconcile the account and discuss payment arrangements. Please provide details or proof of any unrecorded payment or disputed entry.',
      closing: (_) => hindi
          ? 'बकाया का समाधान न होने पर लागू कानून और आवश्यक सूचना प्रक्रिया के अनुसार गिरवी वस्तु की बिक्री द्वारा वसूली पर कार्रवाई की जा सकती है। यह सूचना या इसका जवाब न मिलना अपने आप वस्तु का स्वामित्व नहीं बदलता और वस्तु को गलाने की सहमति नहीं है।'
          : 'If the outstanding balance remains unresolved, recovery through sale of the pledged item may be pursued in accordance with applicable law and the required notice process. This notice or the absence of a reply does not itself transfer ownership or constitute consent to melt the item.',
    );
  }
}

part of '../girvi_notice_generation_service.dart';

/// Customer-facing wording for the single pledge settlement notice.
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
  final List<String> Function(_NoticeData data) opening;
  final List<String> Function(_NoticeData data) accountContext;
  final List<String> Function(_NoticeData data) requiredAction;
  final List<String> Function(_NoticeData data) closing;

  factory _NoticeCopy.forLanguage(GirviNoticeLanguage language) {
    final hindi = language == GirviNoticeLanguage.hindi;
    return _NoticeCopy(
      title: hindi ? 'अंतिम गिरवी खाता सूचना' : 'FINAL NOTICE',
      subject: (data) => hindi
          ? 'गिरवी खाता ${data.ticketNo} के निपटान और वस्तु की वापसी की अंतिम सूचना'
          : 'Final Notice for Settlement and Release of Pledge Account ${data.ticketNo}',
      opening: (data) => hindi
          ? [
              'यह सूचना आपके गिरवी खाते ${data.ticketNo} के संबंध में है। आपने ${data.startDate} को ${data.shopName} में अपनी वस्तु गिरवी रखी थी, जो खाते की शर्तों के अधीन है।',
              'गिरवी वस्तु: ${data.pledgedItemSummary}',
              'खाता ${data.maturityDate} को देय हो गया था और ${data.noticeDate} तक इसका निपटान नहीं हुआ है।',
            ]
          : [
              'This notice is issued in reference to your Pledge Account ${data.ticketNo}, under which your item was deposited with ${data.shopName} on ${data.startDate}, subject to the Terms & Conditions of the pledge account.',
              'Pledged Item: ${data.pledgedItemSummary}',
              'The account became due on ${data.maturityDate} and remains unsettled as of ${data.noticeDate}.',
            ],
      accountContext: (data) => hindi
          ? [
              'इस सूचना में खाते का सारांश ${data.noticeDate} तक दर्ज भुगतानों के बाद ${data.finalOutstanding} की अंतिम बकाया राशि दिखाता है।',
              'ब्याज की गणना ${data.interestCalculatedTo} तक की गई है।',
            ]
          : [
              'The Account Summary in this notice shows Total Outstanding of ${data.finalOutstanding} as on ${data.noticeDate}, after payments recorded in the pledge account.',
              'Interest calculated up to: ${data.interestCalculatedTo}.',
            ],
      requiredAction: (data) => hindi
          ? [
              'कृपया ${data.responseDueDate} तक ${data.finalOutstanding} की पूरी बकाया राशि का भुगतान करें। पूरा भुगतान होने पर खाता रिलीज होगा और आप ${data.shopName} से अपनी गिरवी वस्तु ले सकते हैं।',
              'यदि आप इस तारीख तक पूरा भुगतान नहीं कर सकते, तो निपटान पर चर्चा करने के लिए ${data.responseDueDate} तक ${data.shopName} से संपर्क करें।',
            ]
          : [
              'Please pay the Total Outstanding Amount of ${data.finalOutstanding} on or before ${data.responseDueDate}. On full settlement, the account will be released and you can collect your pledged item from ${data.shopName}.',
              'If you cannot pay in full by this date, you must contact ${data.shopName} on or before ${data.responseDueDate} to discuss settlement.',
            ],
      closing: (data) => hindi
          ? [
              'यह आपकी बकाया राशि के संबंध में अंतिम सूचना है। यदि आप ${data.responseDueDate} तक बकाया राशि का भुगतान नहीं करते या ${data.shopName} के साथ निपटान नहीं करते, तो खाते की शर्तों के अनुसार ${data.shopName} गिरवी वस्तु को बेचकर या गलाकर बकाया राशि की वसूली कर सकता है।',
              'इस कार्रवाई से बचने के लिए कृपया ऊपर दी गई अवधि में खाता चुकाएं या हमसे संपर्क करें।',
            ]
          : [
              'This is the final intimation regarding your outstanding dues. If you do not clear the dues or reach a settlement with ${data.shopName} on or before ${data.responseDueDate}, ${data.shopName} may sell or melt the pledged item and recover the outstanding amount from it, as per the Terms & Conditions of the pledge account.',
              'Please settle the account or contact us within the above period to avoid this action.',
            ],
    );
  }
}

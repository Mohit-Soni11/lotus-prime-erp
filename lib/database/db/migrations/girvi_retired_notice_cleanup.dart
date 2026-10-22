/// Removes the retired first/second/final notice workflow and its documents.
/// The current single formal notice uses NOTICE_PREPARED and is unaffected.
const retiredGirviNoticeCleanupSql = <String>[
  '''DELETE FROM girvi_customer_responses
     WHERE notice_action_id IN (
       SELECT id FROM girvi_notice_actions
       WHERE action_type IN (
         'FIRST_NOTICE_PREPARED',
         'SECOND_NOTICE_PREPARED',
         'FINAL_NOTICE_PREPARED'
       )
     )''',
  '''DELETE FROM girvi_notice_documents
     WHERE notice_action_id IN (
       SELECT id FROM girvi_notice_actions
       WHERE action_type IN (
         'FIRST_NOTICE_PREPARED',
         'SECOND_NOTICE_PREPARED',
         'FINAL_NOTICE_PREPARED'
       )
     )''',
  '''DELETE FROM girvi_notice_actions
     WHERE notice_action_id IN (
       SELECT id FROM girvi_notice_actions
       WHERE action_type IN (
         'FIRST_NOTICE_PREPARED',
         'SECOND_NOTICE_PREPARED',
         'FINAL_NOTICE_PREPARED'
       )
     )
     AND action_type IN (
       'NOTICE_PDF_SAVED',
       'NOTICE_PDF_PRINTED',
       'NOTICE_PDF_SHARED',
       'NOTICE_DELIVERY_RECORDED'
     )''',
  '''UPDATE girvi_notice_actions SET notice_action_id = NULL
     WHERE notice_action_id IN (
       SELECT id FROM girvi_notice_actions
       WHERE action_type IN (
         'FIRST_NOTICE_PREPARED',
         'SECOND_NOTICE_PREPARED',
         'FINAL_NOTICE_PREPARED'
       )
     )''',
  '''DELETE FROM girvi_notice_actions
     WHERE action_type IN (
       'FIRST_NOTICE_PREPARED',
       'SECOND_NOTICE_PREPARED',
       'FINAL_NOTICE_PREPARED'
     )''',
];

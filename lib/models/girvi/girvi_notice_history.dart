/// Read-only compatibility for approved documents from the retired workflow.
/// These action types must never be used to prepare new notices.
abstract final class GirviNoticeHistory {
  static const firstPrepared = 'FIRST_NOTICE_PREPARED';
  static const secondPrepared = 'SECOND_NOTICE_PREPARED';
  static const finalPrepared = 'FINAL_NOTICE_PREPARED';
  static const preparationTypes = [
    firstPrepared,
    secondPrepared,
    finalPrepared
  ];

  static int? stageFor(String actionType) => switch (actionType) {
        firstPrepared => 1,
        secondPrepared => 2,
        finalPrepared => 3,
        _ => null,
      };

  static String? title(int? stage, {bool hindi = false}) => switch (stage) {
        1 => hindi ? 'पहली सूचना' : 'First Notice',
        2 => hindi ? 'दूसरी सूचना' : 'Second Notice',
        3 => hindi ? 'अंतिम सूचना' : 'Final Notice',
        _ => null,
      };
}

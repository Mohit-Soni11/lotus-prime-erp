import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';

abstract interface class ReturnReversalRepository {
  Future<ReturnReversalTransactionSummary> fetchTransactionSummary();

  Future<ReturnReversalLookupResult> findCustomerHistoryByMobile(String mobile);

  Future<ReturnReversalLookupResult> findCustomerHistoryByName(String name);

  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  );

  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  );
}

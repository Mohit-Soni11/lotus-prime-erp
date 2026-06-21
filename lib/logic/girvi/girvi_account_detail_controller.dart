import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/girvi/girvi_repository.dart';
import '../../core/logging/app_logger.dart';

class GirviAccountDetailController extends ChangeNotifier {
  GirviAccountDetailController(AppDatabase db)
      : _repository = GirviRepository(db);

  final GirviRepository _repository;

  bool _isLoading = true;
  String? _errorMessage;
  GirviLoanWithCustomer? _account;
  List<GirviPaymentModel> _payments = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GirviLoanWithCustomer? get account => _account;
  List<GirviPaymentModel> get payments => _payments;

  Future<void> load(int loanId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.syncSettlementStatus();
      final results = await _repository.getLoansWithCustomer(loanId: loanId);
      if (results.isEmpty) {
        _account = null;
        _payments = const [];
        _errorMessage = 'Girvi account could not be found.';
        return;
      }

      final loadedPayments = await _repository.getPaymentModelsForLoan(loanId);
      loadedPayments.sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

      _account = results.first;
      _payments = List.unmodifiable(loadedPayments);
    } catch (error, stackTrace) {
      _account = null;
      _payments = const [];
      _errorMessage = 'Girvi account details could not be loaded.';
      AppLogger.error(
        'GirviAccountDetailController.load failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

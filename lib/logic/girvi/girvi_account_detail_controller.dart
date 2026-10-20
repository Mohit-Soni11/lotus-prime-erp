import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../repositories/girvi/girvi_details_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class GirviAccountDetailController extends ChangeNotifier {
  GirviAccountDetailController(AppDatabase db)
      : _repository = GirviRepository(db),
        _detailsRepository = GirviDetailsRepository(db);

  final GirviRepository _repository;
  final GirviDetailsRepository _detailsRepository;

  bool _isLoading = true;
  String? _errorMessage;
  GirviLoanWithCustomer? _account;
  GirviLoanDetails? _details;
  List<GirviPaymentModel> _payments = const [];
  int _loadVersion = 0;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GirviLoanWithCustomer? get account => _account;
  GirviLoanDetails? get details => _details;
  List<GirviPaymentModel> get payments => _payments;

  Future<void> load(int loanId, {bool showLoading = true}) async {
    if (_disposed) return;
    final loadVersion = ++_loadVersion;
    if (showLoading) _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.syncSettlementStatus();
      if (_disposed || loadVersion != _loadVersion) return;
      final results = await _repository.getLoansWithCustomer(loanId: loanId);
      if (_disposed || loadVersion != _loadVersion) return;
      if (results.isEmpty) {
        _account = null;
        _details = null;
        _payments = const [];
        _errorMessage = 'Pledge account could not be found.';
        return;
      }

      final loadedDetails = await _detailsRepository.getLoanDetails(
        loanId,
      );
      if (_disposed || loadVersion != _loadVersion) return;
      final loadedPayments = await _repository.getPaymentModelsForLoan(loanId);
      if (_disposed || loadVersion != _loadVersion) return;
      loadedPayments.sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

      _account = results.first;
      _details = loadedDetails;
      _payments = List.unmodifiable(loadedPayments);
    } catch (error, stackTrace) {
      if (_disposed || loadVersion != _loadVersion) return;
      _account = null;
      _details = null;
      _payments = const [];
      _errorMessage = 'Pledge account details could not be loaded.';
      AppLogger.error(
        'GirviAccountDetailController.load failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (!_disposed && loadVersion == _loadVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }
}

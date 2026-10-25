import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_recovery_closure_snapshot.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../repositories/girvi/girvi_details_repository.dart';
import '../../repositories/girvi/girvi_notice_action_repository.dart';
import '../../repositories/girvi/girvi_repository.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class GirviAccountDetailController extends ChangeNotifier {
  GirviAccountDetailController(AppDatabase db)
      : _db = db,
        _repository = GirviRepository(db),
        _detailsRepository = GirviDetailsRepository(db);

  final AppDatabase _db;
  final GirviRepository _repository;
  final GirviDetailsRepository _detailsRepository;
  late final GirviNoticeActionRepository _noticeRepository =
      GirviNoticeActionRepository(_db);

  bool _isLoading = true;
  String? _errorMessage;
  GirviLoanWithCustomer? _account;
  GirviLoanDetails? _details;
  List<GirviPaymentModel> _payments = const [];
  GirviRecoveryClosureSnapshot? _recoveryClosure;
  GirviNoticeAction? _formalNotice;
  int _loadVersion = 0;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GirviLoanWithCustomer? get account => _account;
  GirviLoanDetails? get details => _details;
  List<GirviPaymentModel> get payments => _payments;
  GirviRecoveryClosureSnapshot? get recoveryClosure => _recoveryClosure;
  GirviNoticeAction? get formalNotice => _formalNotice;

  Future<void> load(int loanId, {bool showLoading = true}) async {
    if (_disposed) return;
    final loadVersion = ++_loadVersion;
    if (showLoading) _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.syncSettlementStatus();
      if (_disposed || loadVersion != _loadVersion) return;
      final results = await _repository.getLoansWithCustomer(
        loanId: loanId,
        includeAuctioned: true,
      );
      if (_disposed || loadVersion != _loadVersion) return;
      if (results.isEmpty) {
        _account = null;
        _details = null;
        _payments = const [];
        _recoveryClosure = null;
        _formalNotice = null;
        _errorMessage = 'Pledge account could not be found.';
        return;
      }

      final loadedDetails = await _detailsRepository.getLoanDetails(
        loanId,
      );
      if (_disposed || loadVersion != _loadVersion) return;
      final loadedPayments = await _repository.getPaymentModelsForLoan(loanId);
      if (_disposed || loadVersion != _loadVersion) return;
      final actions =
          (await _noticeRepository.actionsByGirviIds([loanId]))[loanId] ??
              const <GirviNoticeAction>[];
      if (_disposed || loadVersion != _loadVersion) return;
      final formalNotice = actions
          .where((action) =>
              action.isFormalNoticePreparation &&
              (action.noticeText?.trim().isNotEmpty ?? false))
          .firstOrNull;
      GirviRecoveryClosureSnapshot? recoveryClosure;
      if (results.first.loan.girviStatus == GirviStatus.auctioned) {
        final settlement =
            actions.where((action) => action.isDisposalSettlement).firstOrNull;
        if (settlement != null) {
          final statuses = loadedDetails?.items
                  .map((entry) => entry.item.recoveryDispositionStatus)
                  .whereType<String>()
                  .toSet() ??
              <String>{};
          recoveryClosure = GirviRecoveryClosureSnapshot.fromAction(
            settlement,
            disposition: statuses.length == 1 ? statuses.single : '',
          );
        }
      }
      loadedPayments.sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

      _account = results.first;
      _details = loadedDetails;
      _payments = List.unmodifiable(loadedPayments);
      _recoveryClosure = recoveryClosure;
      _formalNotice = formalNotice;
    } catch (error, stackTrace) {
      if (_disposed || loadVersion != _loadVersion) return;
      _account = null;
      _details = null;
      _payments = const [];
      _recoveryClosure = null;
      _formalNotice = null;
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

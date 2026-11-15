import 'package:flutter/foundation.dart';

import '../../../models/finance/account_book/account_book_month.dart';
import '../../../repositories/finance/account_book_month_repository.dart';

class AccountBookController extends ChangeNotifier {
  AccountBookController({AccountBookMonthRepository? repository})
      : _repository = repository ?? AccountBookMonthRepository() {
    load();
  }

  final AccountBookMonthRepository _repository;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  AccountBookMonth? report;
  AccountBookActivityType? filter;
  bool loading = false;
  String? error;
  int _request = 0;

  Future<void> selectMonth(DateTime date) async {
    final selected = DateTime(date.year, date.month);
    if (selected == month) return;
    month = selected;
    notifyListeners();
    await load();
  }

  Future<void> shiftMonth(int offset) =>
      selectMonth(DateTime(month.year, month.month + offset));

  void selectFilter(AccountBookActivityType? value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    final request = ++_request;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _repository.fetch(month);
      if (request != _request) return;
      report = result;
    } catch (exception) {
      if (request != _request) return;
      report = null;
      error = 'Account Book could not load: $exception';
    } finally {
      if (request == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }
}

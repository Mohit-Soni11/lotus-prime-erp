import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/customer/customer_profile_logic.dart';
import 'package:lotus_erp/models/customer/customer_profile/customer_profile_model.dart';
import 'package:lotus_erp/repositories/customer/customer_profile_repository.dart';

void main() {
  test('a failed profile query shows a load error', () async {
    final request = Completer<CustomerProfileModel?>();
    final logic = CustomerProfileLogic(
      customerId: 1,
      repo: _QueuedProfileRepository([request.future]),
    );
    addTearDown(logic.dispose);

    request.completeError(StateError('database unavailable'));
    await Future<void>.delayed(Duration.zero);

    expect(logic.state, ProfileState.error);
    expect(logic.error, contains('Failed to load customer profile'));
  });

  test('a slow profile load cannot overwrite the latest refresh', () async {
    final first = Completer<CustomerProfileModel?>();
    final second = Completer<CustomerProfileModel?>();
    final logic = CustomerProfileLogic(
      customerId: 1,
      repo: _QueuedProfileRepository([first.future, second.future]),
    );
    addTearDown(logic.dispose);

    logic.refresh();
    second.complete(_profile('Current'));
    await Future<void>.delayed(Duration.zero);
    first.complete(_profile('Stale'));
    await Future<void>.delayed(Duration.zero);

    expect(logic.state, ProfileState.loaded);
    expect(logic.profile!.name, 'Current');
  });
}

CustomerProfileModel _profile(String name) => CustomerProfileModel(
      id: 1,
      name: name,
      mobile: '',
      createdAt: DateTime(2026, 1, 1),
      initials: CustomerProfileModel.buildInitials(name),
    );

class _QueuedProfileRepository extends CustomerProfileRepository {
  _QueuedProfileRepository(this._responses);

  final List<Future<CustomerProfileModel?>> _responses;

  @override
  Future<CustomerProfileModel?> fetchProfile(int customerId) {
    return _responses.removeAt(0);
  }
}

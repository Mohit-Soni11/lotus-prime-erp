import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/time/date_sensitive_refresh.dart';

void main() {
  testWidgets('resume refresh queues one follow-up while loading',
      (tester) async {
    final firstRefresh = Completer<void>();
    var calls = 0;
    final refresh = DateSensitiveRefresh(onRefresh: () {
      calls++;
      return calls == 1 ? firstRefresh.future : Future<void>.value();
    });
    addTearDown(refresh.dispose);

    refresh.didChangeAppLifecycleState(AppLifecycleState.resumed);
    refresh.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(calls, 1);

    firstRefresh.complete();
    await tester.pump();
    expect(calls, 2);

    refresh.dispose();
    refresh.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(calls, 2);
  });
}

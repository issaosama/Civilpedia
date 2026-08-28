import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityProvider lifecycle', () {
    testWidgets(
        'dispose before subscription initialization completes is safe',
        (tester) async {
      // The constructor fires the async _init() (which awaits
      // Connectivity().checkConnectivity()) and returns immediately, so the
      // _subscription is still unassigned when dispose() is called here.
      final provider = ConnectivityProvider();

      // Before the fix, dispose() dereferenced the late _subscription and threw
      // LateInitializationError. After the fix it must cancel null-safely.
      await tester.pump();
      provider.dispose();

      await tester.pump();
      // A disposed provider must remain readable without throwing.
      expect(provider.isOnline, isTrue);
    });

    testWidgets('provider can be constructed and disposed while online',
        (tester) async {
      final provider = ConnectivityProvider();
      await tester.pump();
      expect(provider.isOnline, isTrue);
      provider.dispose();
      await tester.pump();
    });
  });
}

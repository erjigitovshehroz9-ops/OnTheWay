import 'package:courier_auction/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CourierApp builds under ProviderScope', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CourierApp(),
      ),
    );
    await tester.pump();
  });
}

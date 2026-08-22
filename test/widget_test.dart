import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sovi/app/app.dart';

void main() {
  testWidgets('SOVI App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SoviApp(),
      ),
    );

    expect(find.text('SOVI'), findsOneWidget);
    expect(find.text('SECURE ACOUSTIC FILE TRANSFER'), findsOneWidget);
    
    // Advance timer past splash duration to complete test cleanly
    await tester.pump(const Duration(seconds: 4));
  });
}

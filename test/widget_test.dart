// This is a basic Flutter widget test.
//
// This test has been updated for the CarbonGurukulam Store app.

import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_stores/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CarbonGurukulamStoreApp());
    // Just verify the app can be built without crashing
    expect(find.byType(CarbonGurukulamStoreApp), findsOneWidget);
  });
}

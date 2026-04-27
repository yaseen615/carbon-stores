// This is a basic Flutter widget test.
//
// This test has been updated for the CarbonGurukulam Store app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carbon_stores/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CarbonGurukulamStoreApp()));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    
    // Reset view size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Just verify the app can be built without crashing
    expect(find.byType(CarbonGurukulamStoreApp), findsOneWidget);
  });
}

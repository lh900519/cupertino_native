// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final CupertinoNative plugin = CupertinoNative();
    final String? version = await plugin.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  testWidgets('Single tab bar keeps an automatic minimum height', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CNTabBar(
            items: [
              CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
              CNTabBarItem(label: 'Settings', icon: CNSymbol('gearshape.fill')),
            ],
            currentIndex: 0,
            onTap: _ignoreTabTap,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final automaticSize = tester.getSize(find.byType(CNTabBar));
    expect(automaticSize.height, greaterThanOrEqualTo(50));

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CNTabBar(
            height: 72,
            items: [
              CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
              CNTabBarItem(label: 'Settings', icon: CNSymbol('gearshape.fill')),
            ],
            currentIndex: 0,
            onTap: _ignoreTabTap,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(CNTabBar)).height, 72);
  });
}

void _ignoreTabTap(int index) {}

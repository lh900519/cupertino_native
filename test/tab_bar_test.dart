import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fallback maps labelColor to inactiveColor', (tester) async {
    await tester.pumpWidget(_buildTabBar(labelColor: const Color(0xff123456)));

    final tabBar = tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar));
    expect(tabBar.inactiveColor, const Color(0xff123456));

    await tester.pumpWidget(_buildTabBar());
    final defaultTabBar = tester.widget<CupertinoTabBar>(
      find.byType(CupertinoTabBar),
    );
    expect(defaultTabBar.inactiveColor, CupertinoColors.inactiveGray);
  });

  testWidgets('native params and updates carry resolved labelColor', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const viewChannel = MethodChannel('CupertinoNativeTabBar_42');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      viewChannel,
      (call) async {
        calls.add(call);
        return null;
      },
    );

    const dynamicColor = CupertinoDynamicColor.withBrightness(
      color: Color(0xff123456),
      darkColor: Color(0xff654321),
    );
    await tester.pumpWidget(
      _buildTabBar(labelColor: dynamicColor, brightness: Brightness.light),
    );
    debugDefaultTargetPlatformOverride = null;

    var nativeView = tester.widget<UiKitView>(find.byType(UiKitView));
    final creationParams = nativeView.creationParams! as Map<Object?, Object?>;
    final style = creationParams['style']! as Map<Object?, Object?>;
    expect(style['labelColor'], 0xff123456);

    nativeView.onPlatformViewCreated!(42);
    await tester.pump();
    calls.clear();

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      _buildTabBar(labelColor: dynamicColor, brightness: Brightness.dark),
    );
    debugDefaultTargetPlatformOverride = null;
    await tester.pump();

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having((call) => call.method, 'method', 'setStyle')
            .having(
              (call) => (call.arguments as Map<Object?, Object?>)['labelColor'],
              'labelColor',
              0xff654321,
            ),
      ),
    );

    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(_buildTabBar(brightness: Brightness.dark));
    debugDefaultTargetPlatformOverride = null;
    await tester.pump();

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having((call) => call.method, 'method', 'setStyle')
            .having(
              (call) => (call.arguments as Map<Object?, Object?>).containsKey(
                'labelColor',
              ),
              'contains labelColor',
              isTrue,
            )
            .having(
              (call) => (call.arguments as Map<Object?, Object?>)['labelColor'],
              'labelColor',
              isNull,
            ),
      ),
    );

    nativeView = tester.widget<UiKitView>(find.byType(UiKitView));
    final resetStyle =
        (nativeView.creationParams! as Map<Object?, Object?>)['style']!
            as Map<Object?, Object?>;
    expect(resetStyle, isNot(contains('labelColor')));

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      viewChannel,
      null,
    );
  });
}

Widget _buildTabBar({
  Color? labelColor,
  Brightness brightness = Brightness.light,
}) {
  return CupertinoApp(
    theme: CupertinoThemeData(brightness: brightness),
    home: Center(
      child: CNTabBar(
        items: const [
          CNTabBarItem(label: 'Home'),
          CNTabBarItem(label: 'Settings'),
        ],
        currentIndex: 0,
        onTap: (_) {},
        labelColor: labelColor,
        height: 50,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yelloved_mobile/main.dart';

void main() {
  testWidgets('Bottom tabs open pages and preserve the profile form', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Give good things another love.'), findsOneWidget);

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openTab('Catalogue');
    expect(find.text('No items to display.'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    await openTab('Wanted Board');
    expect(find.text('Looking for something?'), findsOneWidget);
    expect(find.text('Scientific calculator'), findsOneWidget);

    await openTab('Profile');
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'cindy@example.com',
    );

    await openTab('Home');
    expect(find.text('Give good things another love.'), findsOneWidget);
    await openTab('Profile');
    expect(find.text('cindy@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

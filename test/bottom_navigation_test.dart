import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yelloved_mobile/main.dart';
import 'package:yelloved_mobile/core/app_session.dart';

void main() {
  testWidgets('Bottom tabs open pages and preserve the profile form', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(session: session, child: const MyApp()),
    );
    expect(find.text('Give good things another love.'), findsOneWidget);

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is NavigationDestination && widget.label == label,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openTab('Catalogue');
    expect(find.text('Your posted items will appear here.'), findsOneWidget);
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
  testWidgets('Home banner follows session sign in and sign out', (
    tester,
  ) async {
    final session = AppSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppSessionScope(session: session, child: const MyApp()),
    );
    expect(find.textContaining('Signed in'), findsNothing);
    session.updateProfile({'first_name': 'Cindy', 'last_name': 'Olivia'});
    session.signIn(token: 'test-token', usesTokenAuth: false);
    await tester.pumpAndSettle();
    expect(find.text('Signed in as Cindy Olivia'), findsOneWidget);
    session.signOut();
    await tester.pumpAndSettle();
    expect(find.textContaining('Signed in'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

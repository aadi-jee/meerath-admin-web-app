import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meerath_admin/main.dart';

void main() {
  testWidgets('Login screen loads and requires credentials', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MeerathAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to manage your restaurant.'), findsOneWidget);
    expect(find.text('Work Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter your email and password.'),
      findsOneWidget,
    );
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
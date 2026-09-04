import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meerath_admin/main.dart';

void main() {
  testWidgets('Login, dashboard, and menu screens load', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MeerathAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Today Sales'), findsOneWidget);
    expect(find.text('Sales by Source'), findsOneWidget);
    expect(find.text('Recent Orders'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu Management'), findsOneWidget);
    expect(find.text('Chicken Biryani'), findsWidgets);

    await tester.tap(find.text('+ Add New Item'));
    await tester.pumpAndSettle();

    expect(find.text('Add Menu Item'), findsOneWidget);
    expect(find.text('Live Preview'), findsOneWidget);
  });
}

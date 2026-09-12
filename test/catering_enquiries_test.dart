import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meerath_admin/data/catering_repository.dart';
import 'package:meerath_admin/screens/catering_enquiries_screen.dart';

class FakeCateringRepository extends CateringRepository {
  final result = Completer<Map<String, dynamic>>();
  final row = <String, dynamic>{
    'id': 'test-id',
    'customer_name': 'Test guest',
    'mobile': '+966500000000',
    'event_type': 'family',
    'venue_type': 'meerath',
    'status': 'new',
    'message': 'Vegetarian option requested',
    'guest_count': 20,
    'adult_count': 15,
    'kids_5_11_count': 3,
    'kids_under_5_count': 2,
    'created_at': '2026-09-12T10:00:00Z',
    'updated_at': '2026-09-12T10:00:00Z',
    'lang': 'en',
    'consent_to_contact': true,
  };
  @override
  Future<List<Map<String, dynamic>>> loadEnquiries() async => [Map.of(row)];
  @override
  Future<Map<String, dynamic>> setStatus(String id, String status) =>
      result.future;
}

void main() {
  Future<void> open(WidgetTester tester, FakeCateringRepository repo) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(home: CateringEnquiriesScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
  }

  DropdownButton<String> dropdown(WidgetTester tester) => tester
      .widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
  testWidgets('Enquiry starts compact and arrow reveals the guest breakdown', (
    tester,
  ) async {
    await open(tester, FakeCateringRepository());
    expect(find.text('Test guest'), findsOneWidget);
    expect(find.text('Vegetarian option requested'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('expand-test-id')));
    await tester.pumpAndSettle();
    expect(find.text('Vegetarian option requested'), findsOneWidget);
    expect(find.text('Meerath Kabab'), findsOneWidget);
    expect(find.text('Children 5–11'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expand-test-id')));
    await tester.pumpAndSettle();
    expect(find.text('Vegetarian option requested'), findsNothing);
  });
  testWidgets('Status waits for persisted verification', (tester) async {
    final repo = FakeCateringRepository();
    await open(tester, repo);
    dropdown(tester).onChanged!('contacted');
    await tester.pump();
    expect(dropdown(tester).value, 'new');
    expect(dropdown(tester).onChanged, isNull);
    repo.result.complete({...repo.row, 'status': 'contacted'});
    await tester.pumpAndSettle();
    expect(dropdown(tester).value, 'contacted');
    expect(find.text('Saved: Contacted'), findsOneWidget);
  });
  testWidgets('Failed save keeps last verified status and displays error', (
    tester,
  ) async {
    final repo = FakeCateringRepository();
    await open(tester, repo);
    dropdown(tester).onChanged!('quoted');
    await tester.pump();
    repo.result.completeError(StateError('Connection failed'));
    await tester.pumpAndSettle();
    expect(dropdown(tester).value, 'new');
    expect(find.textContaining('Could not confirm status'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/follower_provider.dart';
import 'package:frontend/screens/followers_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('FollowersScreen Widget Tests', () {
    late FollowerProvider provider;

    setUp(() {
      provider = FollowerProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<FollowerProvider>.value(
          value: provider,
          child: const FollowersScreen(),
        ),
      );
    }

    testWidgets('displays app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Followers'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays sort button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.widgetWithIcon(IconButton, Icons.sort), findsOneWidget);
    });

    testWidgets('displays search field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search followers...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search field updates on text input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test_user');
      await tester.pump();

      expect(find.text('test_user'), findsOneWidget);
    });

    testWidgets('sort button opens bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final sortButton = find.widgetWithIcon(IconButton, Icons.sort);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Most Recent First'), findsOneWidget);
      expect(find.text('Oldest First'), findsOneWidget);
      expect(find.text('Username (A-Z)'), findsOneWidget);
      expect(find.text('Username (Z-A)'), findsOneWidget);
    });

    testWidgets('screen has refresh indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}

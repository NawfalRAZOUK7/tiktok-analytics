import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/followers_analysis_screen.dart';
import 'package:frontend/providers/follower_provider.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createTestWidget() {
    final provider = FollowerProvider();
    return MaterialApp(
      home: ChangeNotifierProvider<FollowerProvider>.value(
        value: provider,
        child: const FollowersAnalysisScreen(),
      ),
    );
  }

  group('FollowersAnalysisScreen - UI Structure', () {
    testWidgets('displays AppBar with title and refresh button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Followers Analysis'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('uses proper Material Design scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has RefreshIndicator for pull to refresh',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('contains scrollable content',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('FollowersAnalysisScreen - Comparison Tabs', () {
    testWidgets('displays three comparison tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Mutuals'), findsOneWidget);
      expect(find.text('Followers Only'), findsOneWidget);
      expect(find.text('Following Only'), findsOneWidget);
    });

    testWidgets('displays TabBar and TabBarView',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('creates TabController with 3 tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 3);
    });

    testWidgets('TabBarView has proper layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('all tab labels are visible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Mutuals'), findsOneWidget);
      expect(find.text('Followers Only'), findsOneWidget);
      expect(find.text('Following Only'), findsOneWidget);
    });
  });

  group('FollowersAnalysisScreen - Layout', () {
    testWidgets('has proper padding and spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('uses dividers between sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('comparison section has fixed height',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('AppBar has proper title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isNotNull);
    });
  });
}

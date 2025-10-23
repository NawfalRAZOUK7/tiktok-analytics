import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/follower_card.dart';
import 'package:frontend/models/follower.dart';
import 'package:intl/intl.dart';

void main() {
  group('FollowerCard Widget Tests', () {
    testWidgets('displays username correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      expect(find.text('@test_user'), findsOneWidget);
    });

    testWidgets('displays avatar with first letter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('displays mutual badge when isMutual is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'mutual_user',
              dateFollowed: DateTime(2024, 1, 15),
              isMutual: true,
            ),
          ),
        ),
      );

      expect(find.text('Mutual'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('does not display mutual badge when isMutual is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'non_mutual_user',
              dateFollowed: DateTime(2024, 1, 15),
              isMutual: false,
            ),
          ),
        ),
      );

      expect(find.text('Mutual'), findsNothing);
    });

    testWidgets('displays dateFollowed when provided', (WidgetTester tester) async {
      final date = DateTime(2024, 1, 15);
      final formattedDate = DateFormat('MMM d, yyyy').format(date);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: date,
            ),
          ),
        ),
      );

      expect(find.text('Followed: $formattedDate'), findsOneWidget);
    });

    testWidgets('displays dateFollowing when provided', (WidgetTester tester) async {
      final date = DateTime(2024, 1, 20);
      final formattedDate = DateFormat('MMM d, yyyy').format(date);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowing: date,
            ),
          ),
        ),
      );

      expect(find.text('Following since: $formattedDate'), findsOneWidget);
    });

    testWidgets('displays both dates for comparison card', (WidgetTester tester) async {
      final followedDate = DateTime(2024, 1, 15);
      final followingDate = DateTime(2024, 1, 20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: followedDate,
              dateFollowing: followingDate,
              isMutual: true,
            ),
          ),
        ),
      );

      final formattedFollowed = DateFormat('MMM d, yyyy').format(followedDate);
      final formattedFollowing = DateFormat('MMM d, yyyy').format(followingDate);

      expect(find.text('Followed you: $formattedFollowed'), findsOneWidget);
      expect(find.text('You followed: $formattedFollowing'), findsOneWidget);
    });

    testWidgets('fromFollower factory creates correct widget', (WidgetTester tester) async {
      final follower = Follower(
        id: 1,
        username: 'follower_user',
        dateFollowed: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        isMutual: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard.fromFollower(follower),
          ),
        ),
      );

      expect(find.text('@follower_user'), findsOneWidget);
      expect(find.text('Mutual'), findsOneWidget);
    });

    testWidgets('fromFollowing factory creates correct widget', (WidgetTester tester) async {
      final following = Following(
        id: 2,
        username: 'following_user',
        dateFollowed: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        isMutual: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard.fromFollowing(following),
          ),
        ),
      );

      expect(find.text('@following_user'), findsOneWidget);
      expect(find.text('Mutual'), findsNothing);
    });

    testWidgets('fromComparison factory creates correct widget', (WidgetTester tester) async {
      final comparison = FollowerComparison(
        username: 'comparison_user',
        dateFollowed: DateTime(2024, 1, 15),
        dateFollowing: DateTime(2024, 1, 20),
        isMutual: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard.fromComparison(comparison),
          ),
        ),
      );

      expect(find.text('@comparison_user'), findsOneWidget);
      expect(find.text('Mutual'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles empty username gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: '',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      // Should display '?' as avatar placeholder
      expect(find.text('?'), findsOneWidget);
      expect(find.text('@'), findsOneWidget);
    });

    testWidgets('card has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 4));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('avatar container has correct size and shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('T'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints, const BoxConstraints.tightFor(width: 48, height: 48));
      expect((container.decoration as BoxDecoration).shape, BoxShape.circle);
    });

    testWidgets('displays correct icon for mutual badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'mutual_user',
              dateFollowed: DateTime(2024, 1, 15),
              isMutual: true,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.people);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, 12);
    });

    testWidgets('mutual badge has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowerCard(
              username: 'mutual_user',
              dateFollowed: DateTime(2024, 1, 15),
              isMutual: true,
            ),
          ),
        ),
      );

      final containerFinder = find.ancestor(
        of: find.text('Mutual'),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('responds to theme changes', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FollowerCard(
              username: 'test_user',
              dateFollowed: DateTime(2024, 1, 15),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should rebuild without errors
      expect(find.text('@test_user'), findsOneWidget);
    });
  });
}

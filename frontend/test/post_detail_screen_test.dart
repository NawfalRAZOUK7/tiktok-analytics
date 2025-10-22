import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/screens/post_detail_screen.dart';
import 'package:intl/intl.dart';

void main() {
  group('PostDetailScreen Widget Tests', () {
    late Post testPost;

    setUp(() {
      testPost = Post(
        id: 1,
        postId: 'test123',
        title: 'Test Post Title',
        date: DateTime(2024, 1, 15),
        likes: 1500,
        views: 25000,
        comments: 120,
        shares: 50,
        duration: 30,
        isPinned: true,
        isPrivate: false,
        coverUrl: 'https://example.com/cover.jpg',
        videoLink: 'https://tiktok.com/@user/video/123',
        hashtags: ['test', 'flutter'],
      );
    });

    testWidgets('displays post title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      expect(find.text('Test Post Title'), findsOneWidget);
    });

    testWidgets('displays pinned badge when post is pinned', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('does not display pinned badge when post is not pinned', (WidgetTester tester) async {
      final unpinnedPost = testPost.copyWith(isPinned: false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: unpinnedPost),
        ),
      );

      expect(find.text('Pinned'), findsNothing);
    });

    testWidgets('displays private badge when post is private', (WidgetTester tester) async {
      final privatePost = testPost.copyWith(isPrivate: true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: privatePost),
        ),
      );

      expect(find.text('Private'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('displays all metrics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      // Check for metric labels
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Shares'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);

      // Check for metric icons
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.remove_red_eye), findsOneWidget);
      expect(find.byIcon(Icons.comment), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('displays date correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      final dateFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');
      final expectedDate = dateFormat.format(testPost.date);
      
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('displays hashtags when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      expect(find.text('#test'), findsOneWidget);
      expect(find.text('#flutter'), findsOneWidget);
    });

    testWidgets('shows open in TikTok button when video link exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      
      // Find the IconButton
      final iconButton = tester.widget<IconButton>(
        find.byIcon(Icons.open_in_new).first,
      );
      
      expect(iconButton.tooltip, 'Open in TikTok');
    });

    testWidgets('does not show open button when video link is null', (WidgetTester tester) async {
      final postWithoutLink = testPost.copyWith(videoLink: null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: postWithoutLink),
        ),
      );

      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('displays placeholder when cover URL is null', (WidgetTester tester) async {
      final postWithoutCover = testPost.copyWith(coverUrl: null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: postWithoutCover),
        ),
      );

      await tester.pump();
      
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('formats numbers correctly for large values', (WidgetTester tester) async {
      final postWithLargeNumbers = testPost.copyWith(
        likes: 1500000,
        views: 25000000,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: postWithLargeNumbers),
        ),
      );

      await tester.pump();
      
      // Check that formatted numbers appear (e.g., "1.5M", "25M")
      expect(find.textContaining('M'), findsWidgets);
    });

    testWidgets('scrolls to show all content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      // Verify initial state
      expect(find.text('Test Post Title'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump();

      // Content should still be in widget tree
      expect(find.text('Test Post Title'), findsOneWidget);
    });

    testWidgets('calculates engagement rate correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailScreen(post: testPost),
        ),
      );

      await tester.pump();
      
      // Engagement rate should be displayed
      expect(find.text('Engagement Rate'), findsOneWidget);
      
      // Should show percentage
      expect(find.textContaining('%'), findsWidgets);
    });
  });
}

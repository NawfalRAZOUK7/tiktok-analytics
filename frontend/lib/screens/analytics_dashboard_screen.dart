import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/trends_chart.dart';
import '../widgets/keyword_chart.dart';
import '../widgets/top_posts_widget.dart';
import '../widgets/engagement_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Fetch analytics data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchAllAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Top Posts'),
            Tab(icon: Icon(Icons.tag), text: 'Keywords'),
            Tab(icon: Icon(Icons.trending_up), text: 'Engagement'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AnalyticsProvider>().fetchAllAnalytics();
            },
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TrendsChartTab(),
          TopPostsTab(),
          KeywordChartTab(),
          EngagementChartTab(),
        ],
      ),
    );
  }
}

/// Trends chart tab
class TrendsChartTab extends StatelessWidget {
  const TrendsChartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.trendsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.trendsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.trendsError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchTrends(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.trendsData == null || provider.trendsData!.data.isEmpty) {
          return const Center(
            child: Text('No trend data available'),
          );
        }

        return TrendsChart(data: provider.trendsData!);
      },
    );
  }
}

/// Top posts tab
class TopPostsTab extends StatelessWidget {
  const TopPostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.topPostsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.topPostsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading top posts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.topPostsError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchTopPosts(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.topPostsData == null || provider.topPostsData!.data.isEmpty) {
          return const Center(
            child: Text('No top posts data available'),
          );
        }

        return TopPostsWidget(data: provider.topPostsData!);
      },
    );
  }
}

/// Keyword chart tab
class KeywordChartTab extends StatelessWidget {
  const KeywordChartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.keywordLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.keywordError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading keywords',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.keywordError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchKeywords(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.keywordData == null || provider.keywordData!.keywords.isEmpty) {
          return const Center(
            child: Text('No keyword data available'),
          );
        }

        return KeywordChart(data: provider.keywordData!);
      },
    );
  }
}

/// Engagement chart tab
class EngagementChartTab extends StatelessWidget {
  const EngagementChartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.engagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.engagementError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading engagement data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.engagementError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchEngagement(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.engagementData == null || provider.engagementData!.posts.isEmpty) {
          return const Center(
            child: Text('No engagement data available'),
          );
        }

        return EngagementChart(data: provider.engagementData!);
      },
    );
  }
}

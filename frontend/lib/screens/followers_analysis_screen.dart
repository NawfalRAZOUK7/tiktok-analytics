import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/follower.dart';
import '../providers/follower_provider.dart';
import '../widgets/follower_card.dart';
import '../widgets/follower_comparison_chart.dart';

/// Screen for analyzing followers/following with statistics and comparisons
class FollowersAnalysisScreen extends StatefulWidget {
  const FollowersAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<FollowersAnalysisScreen> createState() =>
      _FollowersAnalysisScreenState();
}

class _FollowersAnalysisScreenState extends State<FollowersAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollControllerMutuals = ScrollController();
  final _scrollControllerFollowersOnly = ScrollController();
  final _scrollControllerFollowingOnly = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add scroll listeners for pagination
    _scrollControllerMutuals.addListener(_onScrollMutuals);
    _scrollControllerFollowersOnly.addListener(_onScrollFollowersOnly);
    _scrollControllerFollowingOnly.addListener(_onScrollFollowingOnly);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FollowerProvider>();
      provider.fetchStats(forceRefresh: true);
      provider.fetchMutuals(refresh: true);
      provider.fetchFollowersOnly(refresh: true);
      provider.fetchFollowingOnly(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerMutuals.dispose();
    _scrollControllerFollowersOnly.dispose();
    _scrollControllerFollowingOnly.dispose();
    super.dispose();
  }

  void _onScrollMutuals() {
    if (_scrollControllerMutuals.position.pixels >=
        _scrollControllerMutuals.position.maxScrollExtent * 0.8) {
      context.read<FollowerProvider>().fetchMutuals();
    }
  }

  void _onScrollFollowersOnly() {
    if (_scrollControllerFollowersOnly.position.pixels >=
        _scrollControllerFollowersOnly.position.maxScrollExtent * 0.8) {
      context.read<FollowerProvider>().fetchFollowersOnly();
    }
  }

  void _onScrollFollowingOnly() {
    if (_scrollControllerFollowingOnly.position.pixels >=
        _scrollControllerFollowingOnly.position.maxScrollExtent * 0.8) {
      context.read<FollowerProvider>().fetchFollowingOnly();
    }
  }

  Future<void> _onRefresh() async {
    final provider = context.read<FollowerProvider>();
    await Future.wait([
      provider.fetchStats(forceRefresh: true),
      provider.fetchMutuals(refresh: true),
      provider.fetchFollowersOnly(refresh: true),
      provider.fetchFollowingOnly(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics section
              _buildStatisticsSection(),

              const Divider(height: 32),

              // Comparison tabs section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Detailed Comparison',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              _buildComparisonSection(),

              const SizedBox(height: 32),

              // Insights section
              _buildInsightsSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer<FollowerProvider>(
      builder: (context, provider, child) {
        if (provider.statsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.statsError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error: ${provider.statsError}'),
            ),
          );
        }

        final stats = provider.stats;
        if (stats == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Main statistics cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Followers',
                      stats.totalFollowers.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Following',
                      stats.totalFollowing.toString(),
                      Icons.person_add,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Mutuals',
                      stats.mutualsCount.toString(),
                      Icons.group,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Ratio',
                      stats.followerRatio.toStringAsFixed(2),
                      Icons.analytics,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Comparison Chart
              FollowerComparisonChart(stats: stats),

              const SizedBox(height: 16),

              // Growth section
              if (stats.weeklyGrowth.isNotEmpty) ...[
                Text(
                  'Weekly Growth',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildGrowthCard(stats.weeklyGrowth),
                const SizedBox(height: 16),
              ],

              if (stats.topAcquisitionDates.isNotEmpty) ...[
                Text(
                  'Top Acquisition Dates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildTopAcquisitionList(stats.topAcquisitionDates),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(Map<String, int> growth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              growth.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        entry.value >= 0
                            ? '+${entry.value}'
                            : entry.value.toString(),
                        style: TextStyle(
                          color: entry.value >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopAcquisitionList(List<TopAcquisitionDate> dates) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dates.length > 5 ? 5 : dates.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = dates[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                item.followersGained.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(DateFormat('MMM dd, yyyy').format(item.date)),
            subtitle: Text('${item.followersGained} new followers'),
          );
        },
      ),
    );
  }

  Widget _buildComparisonSection() {
    return SizedBox(
      height: 600,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mutuals'),
              Tab(text: 'Followers Only'),
              Tab(text: 'Following Only'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMutualsTab(),
                _buildFollowersOnlyTab(),
                _buildFollowingOnlyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualsTab() {
    return Consumer<FollowerProvider>(
      builder: (context, provider, child) {
        if (provider.mutualsError != null && provider.mutuals.isEmpty) {
          return Center(child: Text('Error: ${provider.mutualsError}'));
        }

        if (provider.mutuals.isEmpty && !provider.mutualsLoading) {
          return const Center(child: Text('No mutuals found'));
        }

        return Column(
          children: [
            if (provider.totalMutuals > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${provider.totalMutuals} mutuals',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerMutuals,
                itemCount:
                    provider.mutuals.length + (provider.mutualsLoading ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index < provider.mutuals.length) {
                    return FollowerCard.fromComparison(provider.mutuals[index]);
                  } else {
                    return _buildSkeletonCard();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowersOnlyTab() {
    return Consumer<FollowerProvider>(
      builder: (context, provider, child) {
        if (provider.followersOnlyError != null &&
            provider.followersOnly.isEmpty) {
          return Center(child: Text('Error: ${provider.followersOnlyError}'));
        }

        if (provider.followersOnly.isEmpty && !provider.followersOnlyLoading) {
          return const Center(
            child: Text(
              'No followers-only found\nAll your followers follow you back!',
            ),
          );
        }

        return Column(
          children: [
            if (provider.totalFollowersOnly > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${provider.totalFollowersOnly} followers you don\'t follow back',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerFollowersOnly,
                itemCount:
                    provider.followersOnly.length +
                    (provider.followersOnlyLoading ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index < provider.followersOnly.length) {
                    return FollowerCard.fromComparison(
                      provider.followersOnly[index],
                    );
                  } else {
                    return _buildSkeletonCard();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowingOnlyTab() {
    return Consumer<FollowerProvider>(
      builder: (context, provider, child) {
        if (provider.followingOnlyError != null &&
            provider.followingOnly.isEmpty) {
          return Center(child: Text('Error: ${provider.followingOnlyError}'));
        }

        if (provider.followingOnly.isEmpty && !provider.followingOnlyLoading) {
          return const Center(
            child: Text(
              'No following-only found\nEveryone you follow follows you back!',
            ),
          );
        }

        return Column(
          children: [
            if (provider.totalFollowingOnly > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${provider.totalFollowingOnly} people you follow who don\'t follow back',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerFollowingOnly,
                itemCount:
                    provider.followingOnly.length +
                    (provider.followingOnlyLoading ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index < provider.followingOnly.length) {
                    return FollowerCard.fromComparison(
                      provider.followingOnly[index],
                    );
                  } else {
                    return _buildSkeletonCard();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightsSection() {
    return Consumer<FollowerProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        if (stats == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              _buildInsightCard(
                'Engagement Rate',
                '${((stats.mutualsCount / stats.totalFollowing) * 100).toStringAsFixed(1)}% of people you follow follow you back',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(height: 8),

              if (stats.followerRatio > 1.2)
                _buildInsightCard(
                  'Growing Account',
                  'You have ${((stats.followerRatio - 1) * 100).toStringAsFixed(0)}% more followers than following',
                  Icons.star,
                  Colors.amber,
                ),

              if (stats.followerRatio < 0.8)
                _buildInsightCard(
                  'Consider Unfollowing',
                  'You follow ${(((1 / stats.followerRatio) - 1) * 100).toStringAsFixed(0)}% more people than follow you',
                  Icons.info,
                  Colors.blue,
                ),

              const SizedBox(height: 8),

              if (provider.totalFollowingOnly > 0)
                _buildInsightCard(
                  'Non-Reciprocal Follows',
                  '${provider.totalFollowingOnly} people don\'t follow you back',
                  Icons.person_remove,
                  Colors.orange,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

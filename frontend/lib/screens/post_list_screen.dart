import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostProvider>();
      provider.fetchPosts(refresh: true);
      provider.fetchStats();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<PostProvider>().fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TikTok Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortAndFilterChips(),
          _buildStatsBar(),
          Expanded(child: _buildPostList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search posts, IDs, hashtags...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<PostProvider>().setSearchQuery('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (value) {
          context.read<PostProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildSortAndFilterChips() {
    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(_getSortLabel(provider.sortBy)),
                selected: true,
                onSelected: (_) => _showSortDialog(),
              ),
              const SizedBox(width: 8),
              if (provider.hasActiveFilters)
                ActionChip(
                  label: const Text('Clear Filters'),
                  onPressed: () => provider.clearFilters(),
                  backgroundColor: Colors.red.shade100,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBar() {
    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        if (stats == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Posts', stats.totalPosts.toString()),
              _buildStatItem('Avg Likes', stats.avgLikes.toStringAsFixed(0)),
              _buildStatItem('Avg Views', stats.avgViews.toStringAsFixed(0)),
              _buildStatItem(
                'Engagement',
                '${(stats.avgEngagementRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPostList() {
    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchPosts(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.posts.isEmpty) {
          return const Center(
            child: Text('No posts found. Try adjusting your filters.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPosts(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final post = provider.posts[index];
              return _buildPostCard(post);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Post post) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.go('/posts/${post.id}', extra: post);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    post.coverUrl != null
                        ? CachedNetworkImage(
                          imageUrl: post.coverUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        )
                        : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.video_library),
                        ),
              ),
              const SizedBox(width: 12),

              // Post Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(post.formattedLikes),
                        const SizedBox(width: 16),
                        const Icon(Icons.remove_red_eye, size: 16),
                        const SizedBox(width: 4),
                        Text(post.formattedViews),
                        if (post.isPinned) ...[
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.push_pin,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(post.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case '-date':
        return 'Newest First';
      case 'date':
        return 'Oldest First';
      case '-likes':
        return 'Most Liked';
      case 'likes':
        return 'Least Liked';
      case '-views':
        return 'Most Viewed';
      case 'views':
        return 'Least Viewed';
      default:
        return 'Sort';
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('Newest First', '-date'),
              _buildSortOption('Oldest First', 'date'),
              _buildSortOption('Most Liked', '-likes'),
              _buildSortOption('Least Liked', 'likes'),
              _buildSortOption('Most Viewed', '-views'),
              _buildSortOption('Least Viewed', 'views'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      title: Text(label),
      onTap: () {
        context.read<PostProvider>().setSortBy(value);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterDialog() {
    showDialog(context: context, builder: (context) => const FilterDialog());
  }
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _minLikesController;
  late TextEditingController _maxLikesController;
  late TextEditingController _minViewsController;
  late TextEditingController _maxViewsController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PostProvider>();
    _minLikesController = TextEditingController(
      text: provider.minLikes?.toString() ?? '',
    );
    _maxLikesController = TextEditingController(
      text: provider.maxLikes?.toString() ?? '',
    );
    _minViewsController = TextEditingController(
      text: provider.minViews?.toString() ?? '',
    );
    _maxViewsController = TextEditingController(
      text: provider.maxViews?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minLikesController.dispose();
    _maxLikesController.dispose();
    _minViewsController.dispose();
    _maxViewsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _minLikesController,
              decoration: const InputDecoration(labelText: 'Min Likes'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _maxLikesController,
              decoration: const InputDecoration(labelText: 'Max Likes'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minViewsController,
              decoration: const InputDecoration(labelText: 'Min Views'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _maxViewsController,
              decoration: const InputDecoration(labelText: 'Max Views'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final provider = context.read<PostProvider>();
            provider.setLikesFilter(
              min: int.tryParse(_minLikesController.text),
              max: int.tryParse(_maxLikesController.text),
            );
            provider.setViewsFilter(
              min: int.tryParse(_minViewsController.text),
              max: int.tryParse(_maxViewsController.text),
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

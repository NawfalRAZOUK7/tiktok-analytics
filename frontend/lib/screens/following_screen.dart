import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/follower_provider.dart';
import '../widgets/follower_card.dart';

/// Screen displaying the list of following with search, filters, and pagination
class FollowingScreen extends StatefulWidget {
  const FollowingScreen({Key? key}) : super(key: key);

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowerProvider>().fetchFollowing(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<FollowerProvider>().fetchFollowing();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<FollowerProvider>()
        ..setSearchQuery(query.isEmpty ? null : query)
        ..fetchFollowing(refresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<FollowerProvider>().fetchFollowing(refresh: true);
  }

  void _showSortOptions() {
    final provider = context.read<FollowerProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Sort by'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Divider(),
          _buildSortOption('Most Recent First', '-date_followed', provider.ordering),
          _buildSortOption('Oldest First', 'date_followed', provider.ordering),
          _buildSortOption('Username (A-Z)', 'username', provider.ordering),
          _buildSortOption('Username (Z-A)', '-username', provider.ordering),
        ],
      ),
    );
  }

  Widget _buildSortOption(String title, String value, String? currentValue) {
    final isSelected = value == currentValue;
    
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      selected: isSelected,
      onTap: () {
        context.read<FollowerProvider>()
          ..setOrdering(value)
          ..fetchFollowing(refresh: true);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search following...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Following list
          Expanded(
            child: Consumer<FollowerProvider>(
              builder: (context, provider, child) {
                if (provider.totalFollowing > 0) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${provider.totalFollowing} following',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            if (provider.searchQuery != null)
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear search'),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: _buildFollowingList(provider),
                      ),
                    ],
                  );
                }

                return _buildFollowingList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList(FollowerProvider provider) {
    // Error state
    if (provider.followingError != null && provider.following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading following',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.followingError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchFollowing(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.following.isEmpty && !provider.followingLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery != null
                  ? 'No following found'
                  : 'Not following anyone yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery != null
                  ? 'Try a different search'
                  : 'Users you follow will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // List with skeleton loaders
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: provider.following.length + (provider.followingLoading ? 5 : 0),
        itemBuilder: (context, index) {
          if (index < provider.following.length) {
            final following = provider.following[index];
            return FollowerCard.fromFollowing(following);
          } else {
            return _buildSkeletonCard();
          }
        },
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

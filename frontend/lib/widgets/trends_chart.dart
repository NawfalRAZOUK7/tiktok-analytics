import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics.dart';
import 'package:intl/intl.dart';

class TrendsChart extends StatefulWidget {
  final TrendsResponse data;

  const TrendsChart({super.key, required this.data});

  @override
  State<TrendsChart> createState() => _TrendsChartState();
}

class _TrendsChartState extends State<TrendsChart> {
  bool _showLikes = true;
  bool _showViews = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trends Over Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.data.startDate} to ${widget.data.endDate}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Likes'),
                        selected: _showLikes,
                        onSelected: (value) {
                          setState(() => _showLikes = value);
                        },
                        avatar: _showLikes
                            ? const Icon(Icons.favorite, size: 16, color: Colors.red)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Views'),
                        selected: _showViews,
                        onSelected: (value) {
                          setState(() => _showViews = value);
                        },
                        avatar: _showViews
                            ? const Icon(Icons.visibility, size: 16, color: Colors.blue)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: widget.data.data.isEmpty
                    ? const Center(child: Text('No data available'))
                    : LineChart(
                        _buildChartData(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary Statistics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Total Posts', _totalPosts()),
                  _buildStatRow('Total Likes', _totalLikes()),
                  _buildStatRow('Total Views', _totalViews()),
                  _buildStatRow('Avg Likes/Post', _avgLikes()),
                  _buildStatRow('Avg Views/Post', _avgViews()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String _totalPosts() {
    final total = widget.data.data.fold<int>(0, (sum, item) => sum + item.postCount);
    return total.toString();
  }

  String _totalLikes() {
    final total = widget.data.data.fold<int>(0, (sum, item) => sum + item.totalLikes);
    return NumberFormat('#,###').format(total);
  }

  String _totalViews() {
    final total = widget.data.data.fold<int>(0, (sum, item) => sum + item.totalViews);
    return NumberFormat('#,###').format(total);
  }

  String _avgLikes() {
    final totalLikes = widget.data.data.fold<int>(0, (sum, item) => sum + item.totalLikes);
    final totalPosts = widget.data.data.fold<int>(0, (sum, item) => sum + item.postCount);
    if (totalPosts == 0) return '0';
    return NumberFormat('#,###').format(totalLikes ~/ totalPosts);
  }

  String _avgViews() {
    final totalViews = widget.data.data.fold<int>(0, (sum, item) => sum + item.totalViews);
    final totalPosts = widget.data.data.fold<int>(0, (sum, item) => sum + item.postCount);
    if (totalPosts == 0) return '0';
    return NumberFormat('#,###').format(totalViews ~/ totalPosts);
  }

  LineChartData _buildChartData() {
    final spots = widget.data.data;

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat.compact().format(value.toInt()),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (spots.length / 5).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= spots.length) return const Text('');
              final date = DateTime.parse(spots[index].date);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('M/d').format(date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        if (_showLikes)
          LineChartBarData(
            spots: spots
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.totalLikes.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        if (_showViews)
          LineChartBarData(
            spots: spots
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.totalViews.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.parse(spots[spot.x.toInt()].date);
              final dateStr = DateFormat('MMM d').format(date);
              final value = NumberFormat('#,###').format(spot.y.toInt());
              final label = spot.barIndex == 0 ? 'Likes' : 'Views';
              return LineTooltipItem(
                '$dateStr\n$label: $value',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

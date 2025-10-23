import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget displaying growth chart for followers/following over time
class FollowerGrowthChart extends StatefulWidget {
  final Map<String, int> weeklyGrowth;
  final Map<String, int>? monthlyGrowth;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showSecondaryLine;

  const FollowerGrowthChart({
    Key? key,
    required this.weeklyGrowth,
    this.monthlyGrowth,
    this.title = 'Growth Over Time',
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.green,
    this.showSecondaryLine = false,
  }) : super(key: key);

  @override
  State<FollowerGrowthChart> createState() => _FollowerGrowthChartState();
}

class _FollowerGrowthChartState extends State<FollowerGrowthChart> {
  bool _showWeekly = true;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.monthlyGrowth != null)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Weekly'),
                        icon: Icon(Icons.calendar_view_week, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Monthly'),
                        icon: Icon(Icons.calendar_month, size: 16),
                      ),
                    ],
                    selected: {_showWeekly},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showWeekly = newSelection.first;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showWeekly ? 'Weekly Growth Trend' : 'Monthly Growth Trend',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final data = _showWeekly ? widget.weeklyGrowth : widget.monthlyGrowth ?? {};
    
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No growth data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import historical snapshots to see trends',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            setState(() {
              if (response == null || response.lineBarSpots == null) {
                _touchedIndex = null;
                return;
              }
              _touchedIndex = response.lineBarSpots!.first.spotIndex;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot spot) {
              return widget.primaryColor.withOpacity(0.8);
            },
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final dateKey = data.keys.elementAt(spot.spotIndex);
                final value = spot.y.toInt();
                return LineTooltipItem(
                  '$dateKey\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: value >= 0 ? '+$value' : '$value',
                      style: TextStyle(
                        color: value >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(
                      text: ' followers',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(data),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                
                final dateKey = data.keys.elementAt(index);
                // Show only first, middle, and last labels to avoid crowding
                if (index == 0 || 
                    index == data.length - 1 || 
                    index == data.length ~/ 2) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateLabel(dateKey),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _calculateInterval(data),
              getTitlesWidget: (value, meta) {
                return Text(
                  value >= 0 ? '+${value.toInt()}' : '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: _calculateMinY(data),
        maxY: _calculateMaxY(data),
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(data),
            isCurved: true,
            curveSmoothness: 0.35,
            color: widget.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isImportant = _isImportantPoint(data, index);
                final isTouched = index == _touchedIndex;
                
                return FlDotCirclePainter(
                  radius: isTouched ? 8 : (isImportant ? 6 : 4),
                  color: isTouched 
                      ? widget.primaryColor 
                      : (isImportant ? Colors.orange : Colors.white),
                  strokeWidth: 2,
                  strokeColor: widget.primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.primaryColor.withOpacity(0.3),
                  widget.primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(Map<String, int> data) {
    final spots = <FlSpot>[];
    var index = 0;
    for (final value in data.values) {
      spots.add(FlSpot(index.toDouble(), value.toDouble()));
      index++;
    }
    return spots;
  }

  double _calculateMinY(Map<String, int> data) {
    final minValue = data.values.reduce((a, b) => a < b ? a : b);
    return (minValue - 10).toDouble();
  }

  double _calculateMaxY(Map<String, int> data) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    return (maxValue + 10).toDouble();
  }

  double _calculateInterval(Map<String, int> data) {
    final min = _calculateMinY(data);
    final max = _calculateMaxY(data);
    final range = max - min;
    return (range / 5).ceilToDouble();
  }

  bool _isImportantPoint(Map<String, int> data, int index) {
    final values = data.values.toList();
    if (index >= values.length) return false;
    
    final value = values[index];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    
    // Mark points that are peaks or valleys
    return value == maxValue || value == minValue;
  }

  String _formatDateLabel(String dateKey) {
    try {
      // Try to parse as date
      final date = DateTime.parse(dateKey);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      // If parsing fails, return abbreviated version
      if (dateKey.length > 8) {
        return '${dateKey.substring(0, 3)}...';
      }
      return dateKey;
    }
  }

  Widget _buildLegend() {
    final data = _showWeekly ? widget.weeklyGrowth : widget.monthlyGrowth ?? {};
    
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.reduce((a, b) => a + b);
    final average = (total / data.length).round();
    final maxGain = data.values.reduce((a, b) => a > b ? a : b);
    final maxLoss = data.values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            'Total',
            total >= 0 ? '+$total' : '$total',
            total >= 0 ? Colors.green : Colors.red,
            Icons.trending_up,
          ),
          _buildLegendItem(
            'Average',
            average >= 0 ? '+$average' : '$average',
            Colors.blue,
            Icons.bar_chart,
          ),
          _buildLegendItem(
            'Best',
            '+$maxGain',
            Colors.orange,
            Icons.star,
          ),
          if (maxLoss < 0)
            _buildLegendItem(
              'Worst',
              '$maxLoss',
              Colors.red,
              Icons.trending_down,
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

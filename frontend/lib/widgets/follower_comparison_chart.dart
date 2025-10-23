import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/follower.dart';

/// Widget displaying Venn diagram and bar chart for follower comparison
class FollowerComparisonChart extends StatefulWidget {
  final FollowerStats stats;
  final VoidCallback? onTap;

  const FollowerComparisonChart({Key? key, required this.stats, this.onTap})
    : super(key: key);

  @override
  State<FollowerComparisonChart> createState() =>
      _FollowerComparisonChartState();
}

class _FollowerComparisonChartState extends State<FollowerComparisonChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showVennDiagram = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChartType() {
    setState(() {
      _showVennDiagram = !_showVennDiagram;
      _animationController.reset();
      _animationController.forward();
    });
  }

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
                  'Followers Comparison',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _showVennDiagram ? Icons.bar_chart : Icons.bubble_chart,
                  ),
                  onPressed: _toggleChartType,
                  tooltip:
                      _showVennDiagram
                          ? 'Switch to Bar Chart'
                          : 'Switch to Venn Diagram',
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showVennDiagram ? _buildVennDiagram() : _buildBarChart(),
            ),
            const SizedBox(height: 24),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildVennDiagram() {
    return SizedBox(
      key: const ValueKey('venn'),
      height: 300,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: VennDiagramPainter(
              followersOnly: widget.stats.followersOnlyCount,
              followingOnly: widget.stats.followingOnlyCount,
              mutuals: widget.stats.mutualsCount,
              animation: _animation.value,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.stats.mutualsCount.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Mutuals',
                      style: TextStyle(fontSize: 14, color: Colors.white),
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

  Widget _buildBarChart() {
    final total = widget.stats.totalFollowers + widget.stats.totalFollowing;
    final followersOnlyPercent =
        (widget.stats.followersOnlyCount / total * 100);
    final followingOnlyPercent =
        (widget.stats.followingOnlyCount / total * 100);
    final mutualsPercent = (widget.stats.mutualsCount / total * 100);

    return SizedBox(
      key: const ValueKey('bar'),
      height: 300,
      child: Column(
        children: [
          _buildBarItem(
            'Followers Only',
            widget.stats.followersOnlyCount,
            followersOnlyPercent,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildBarItem(
            'Mutuals',
            widget.stats.mutualsCount,
            mutualsPercent,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildBarItem(
            'Following Only',
            widget.stats.followingOnlyCount,
            followingOnlyPercent,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(String label, int count, double percent, Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$count (${percent.toStringAsFixed(1)}%)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percent / 100) * _animation.value,
                minHeight: 32,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          'Followers Only',
          Colors.blue,
          widget.stats.followersOnlyCount,
        ),
        _buildLegendItem('Mutuals', Colors.purple, widget.stats.mutualsCount),
        _buildLegendItem(
          'Following Only',
          Colors.green,
          widget.stats.followingOnlyCount,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Custom painter for Venn diagram
class VennDiagramPainter extends CustomPainter {
  final int followersOnly;
  final int followingOnly;
  final int mutuals;
  final double animation;

  VennDiagramPainter({
    required this.followersOnly,
    required this.followingOnly,
    required this.mutuals,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3.5 * animation;
    final overlap = radius * 0.5;

    // Calculate circle positions
    final leftCircleCenter = Offset(center.dx - overlap, center.dy);
    final rightCircleCenter = Offset(center.dx + overlap, center.dy);

    // Draw followers circle (left - blue)
    final followersPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.4)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(leftCircleCenter, radius, followersPaint);

    // Draw followers border
    final followersBorderPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(leftCircleCenter, radius, followersBorderPaint);

    // Draw following circle (right - green)
    final followingPaint =
        Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.multiply;
    canvas.drawCircle(rightCircleCenter, radius, followingPaint);

    // Draw following border
    final followingBorderPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(rightCircleCenter, radius, followingBorderPaint);

    // Draw labels
    _drawText(
      canvas,
      '$followersOnly',
      Offset(leftCircleCenter.dx - radius * 0.5, center.dy),
      Colors.blue,
      16,
      FontWeight.bold,
    );

    _drawText(
      canvas,
      '$followingOnly',
      Offset(rightCircleCenter.dx + radius * 0.5, center.dy),
      Colors.green,
      16,
      FontWeight.bold,
    );

    // Draw section labels
    _drawText(
      canvas,
      'Followers',
      Offset(leftCircleCenter.dx - radius * 0.5, center.dy - radius - 20),
      Colors.blue,
      14,
      FontWeight.w600,
    );

    _drawText(
      canvas,
      'Following',
      Offset(rightCircleCenter.dx + radius * 0.5, center.dy - radius - 20),
      Colors.green,
      14,
      FontWeight.w600,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(VennDiagramPainter oldDelegate) {
    return oldDelegate.followersOnly != followersOnly ||
        oldDelegate.followingOnly != followingOnly ||
        oldDelegate.mutuals != mutuals ||
        oldDelegate.animation != animation;
  }
}

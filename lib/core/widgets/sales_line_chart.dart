import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/theme_extensions.dart';
import '../../models/admin_models.dart';

String _fmtMoney(num value) => '₱${NumberFormat('#,##0.00').format(value)}';

// =============================================================================
// INTERACTIVE SALES OVERVIEW LINE & AREA CHART
// =============================================================================
class SalesLineChart extends StatefulWidget {
  const SalesLineChart({
    super.key,
    required this.orders,
    required this.startDate,
    required this.endDate,
    required this.isSales,
    required this.colors,
  });

  final List<Order> orders;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSales;
  final AppSemanticColors colors;

  @override
  State<SalesLineChart> createState() => SalesLineChartState();
}

class SalesLineChartState extends State<SalesLineChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // 1. Group orders by day
    final dailyData = <DateTime, (double sales, int orders)>{};

    for (final o in widget.orders) {
      if (widget.isSales && !o.contributesToSales) continue;
      final day = DateTime(o.placedAt.year, o.placedAt.month, o.placedAt.day);
      final current = dailyData[day] ?? (0.0, 0);
      dailyData[day] = (current.$1 + o.total, current.$2 + 1);
    }

    final sortedDays = dailyData.keys.toList()..sort();

    // Ensure we have at least 2 data points for visualization
    if (sortedDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 32, color: widget.colors.mutedText),
            const SizedBox(height: 6),
            Text(
              'No sales data in this period',
              style: TextStyle(fontSize: 12, color: widget.colors.mutedText),
            ),
          ],
        ),
      );
    }

    // Build data points
    final points = sortedDays.map((d) {
      final info = dailyData[d]!;
      return (
        date: d,
        value: widget.isSales ? info.$1 : info.$2.toDouble(),
        sales: info.$1,
        orders: info.$2,
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return MouseRegion(
          onHover: (event) {
            final x = event.localPosition.dx;
            final chartLeft = 45.0;
            final chartRight = width - 15.0;
            final chartWidth = chartRight - chartLeft;

            if (x >= chartLeft && x <= chartRight && points.length > 1) {
              final step = chartWidth / (points.length - 1);
              final idx = ((x - chartLeft) / step).round().clamp(0, points.length - 1);
              setState(() => _hoveredIndex = idx);
            }
          },
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: ChartPainter(
                  points: points,
                  isSales: widget.isSales,
                  hoveredIndex: _hoveredIndex,
                  gridColor: widget.colors.subtleBorder,
                  textColor: widget.colors.secondaryText,
                  primaryColor: const Color(0xFF10B981),
                ),
              ),
              if (_hoveredIndex != null && _hoveredIndex! < points.length) ...[
                _buildHoverTooltip(
                  point: points[_hoveredIndex!],
                  index: _hoveredIndex!,
                  totalPoints: points.length,
                  width: width,
                  height: height,
                  colors: widget.colors,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoverTooltip({
    required ({DateTime date, double value, double sales, int orders}) point,
    required int index,
    required int totalPoints,
    required double width,
    required double height,
    required AppSemanticColors colors,
  }) {
    final chartLeft = 45.0;
    final chartRight = width - 15.0;
    final chartWidth = chartRight - chartLeft;
    final step = totalPoints > 1 ? chartWidth / (totalPoints - 1) : 0.0;
    final posX = chartLeft + index * step;

    return Positioned(
      left: (posX - 60).clamp(10.0, width - 130.0),
      top: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primaryText,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(point.date),
              style: TextStyle(
                color: colors.cardBackground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmtMoney(point.sales)} (${point.orders} orders)',
              style: TextStyle(
                color: colors.cardBackground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  ChartPainter({
    required this.points,
    required this.isSales,
    required this.hoveredIndex,
    required this.gridColor,
    required this.textColor,
    required this.primaryColor,
  });

  final List<({DateTime date, double value, double sales, int orders})> points;
  final bool isSales;
  final int? hoveredIndex;
  final Color gridColor;
  final Color textColor;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 45.0;
    const rightMargin = 15.0;
    const topMargin = 20.0;
    const bottomMargin = 28.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Find max value
    double maxVal = points.map((p) => p.value).fold(0.0, math.max);
    if (maxVal == 0) maxVal = isSales ? 1000 : 5;
    // Round max up nicely
    maxVal = (maxVal * 1.15);

    // 1. Draw horizontal grid lines & Y labels
    const gridDivisions = 3;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= gridDivisions; i++) {
      final y = topMargin + chartHeight * (1 - i / gridDivisions);
      final value = (maxVal * (i / gridDivisions));

      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      final label = isSales
          ? (value >= 1000 ? '₱${(value / 1000).toStringAsFixed(1)}k' : '₱${value.round()}')
          : '${value.round()}';

      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }

    if (points.isEmpty) return;

    // 2. Compute coordinate points
    final count = points.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : chartWidth / 2;

    final coords = <Offset>[];
    for (int i = 0; i < count; i++) {
      final px = count > 1 ? leftMargin + i * stepX : leftMargin + chartWidth / 2;
      final py = topMargin + chartHeight * (1 - (points[i].value / maxVal).clamp(0.0, 1.0));
      coords.add(Offset(px, py));
    }

    // 3. Draw smooth curve & gradient area fill
    final linePath = Path();
    final fillPath = Path();

    linePath.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, topMargin + chartHeight);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, topMargin + chartHeight);
    fillPath.close();

    // Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.22),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(
          leftMargin, topMargin, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // 4. Draw points & X-axis date labels
    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final maxLabels = math.min(count, 8);
    final labelInterval = math.max(1, (count / maxLabels).floor());

    for (int i = 0; i < count; i++) {
      final coord = coords[i];
      final isHovered = hoveredIndex == i;

      // Draw point circle
      canvas.drawCircle(coord, isHovered ? 5.5 : 3.0, dotPaint);
      canvas.drawCircle(coord, isHovered ? 5.5 : 3.0, dotBorderPaint);

      // Draw X label
      if (i % labelInterval == 0 || i == count - 1) {
        final dateLabel = DateFormat('MMM d').format(points[i].date);
        final tp = TextPainter(
          text: TextSpan(text: dateLabel, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(coord.dx - tp.width / 2, topMargin + chartHeight + 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.isSales != isSales ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/theme_extensions.dart';
import '../widgets/admin_widgets.dart';
import '../../models/admin_models.dart';
import 'sales_line_chart.dart';

enum DatePreset { today, thisWeek, thisMonth, custom, all }

class SalesOverviewCard extends StatefulWidget {
  const SalesOverviewCard({
    super.key,
    required this.allOrders,
    this.filteredOrders,
    this.summary,
    this.dateRangeLabel,
    this.startDate,
    this.endDate,
    this.initialPreset = DatePreset.all,
    this.trailingHeaderControls,
    this.onDateRangeChanged,
    this.showDateControls = true,
  });

  final List<Order> allOrders;
  final List<Order>? filteredOrders;
  final SalesSummary? summary;
  final String? dateRangeLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final DatePreset initialPreset;
  final Widget? trailingHeaderControls;
  final void Function(DateTime? start, DateTime? end, DatePreset preset)?
      onDateRangeChanged;
  final bool showDateControls;

  @override
  State<SalesOverviewCard> createState() => _SalesOverviewCardState();
}

class _SalesOverviewCardState extends State<SalesOverviewCard> {
  bool showSalesMetric = true;
  late DatePreset _selectedPreset;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _startDate = widget.startDate;
    _endDate = widget.endDate;

    if (widget.startDate == null &&
        widget.endDate == null &&
        _selectedPreset != DatePreset.all) {
      _applyPreset(_selectedPreset, updateState: false);
    }
  }

  @override
  void didUpdateWidget(covariant SalesOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _startDate = widget.startDate;
      _endDate = widget.endDate;
    }
  }

  void _applyPreset(DatePreset preset, {bool updateState = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? s;
    DateTime? e;

    switch (preset) {
      case DatePreset.today:
        s = today;
        e = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case DatePreset.thisWeek:
        s = today.subtract(Duration(days: today.weekday - 1));
        e = s.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case DatePreset.thisMonth:
        s = DateTime(now.year, now.month, 1);
        e = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DatePreset.all:
        s = null;
        e = null;
        break;
      case DatePreset.custom:
        return;
    }

    if (updateState) {
      setState(() {
        _selectedPreset = preset;
        _startDate = s;
        _endDate = e;
      });
      widget.onDateRangeChanged?.call(s, e, preset);
    } else {
      _selectedPreset = preset;
      _startDate = s;
      _endDate = e;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(
              start: DateUtils.dateOnly(_startDate!),
              end: DateUtils.dateOnly(_endDate!),
            )
          : null,
      firstDate: DateTime(2020),
      lastDate: today,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final dialogWidth = (media.size.width * 0.9).clamp(320.0, 440.0);
        final dialogHeight = (media.size.height * 0.85).clamp(420.0, 560.0);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(dialogWidth, dialogHeight),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF10B981),
                        ),
                    datePickerTheme: DatePickerThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 12,
                    ),
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      final s = DateUtils.dateOnly(picked.start);
      final e = DateUtils.dateOnly(picked.end);
      setState(() {
        _selectedPreset = DatePreset.custom;
        _startDate = s;
        _endDate = e;
      });
      widget.onDateRangeChanged?.call(s, e, DatePreset.custom);
    }
  }

  String _dateRangeLabel() {
    if (widget.dateRangeLabel != null &&
        _selectedPreset == DatePreset.all &&
        _startDate == null) {
      return widget.dateRangeLabel!;
    }
    if (_startDate == null && _endDate == null) {
      return 'All time';
    }
    if (_startDate != null && _endDate != null) {
      if (_startDate!.year == _endDate!.year &&
          _startDate!.month == _endDate!.month &&
          _startDate!.day == _endDate!.day) {
        return DateFormat('MMM d, yyyy').format(_startDate!);
      }
      return '${DateFormat('MMM d').format(_startDate!)} – ${DateFormat('MMM d, yyyy').format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'From ${DateFormat('MMM d, yyyy').format(_startDate!)}';
    }
    return 'Until ${DateFormat('MMM d, yyyy').format(_endDate!)}';
  }

  String _fmtMoney(num value) => '₱${NumberFormat('#,##0.00').format(value)}';

  Widget _presetPill(String label, DatePreset preset, AppSemanticColors colors,
      {VoidCallback? onTap, IconData? icon}) {
    final isSelected = _selectedPreset == preset;
    return InkWell(
      onTap: onTap ?? () => _applyPreset(preset),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : colors.secondaryText,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : colors.secondaryText,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartMetricToggle(String label, bool isSelected, VoidCallback onTap) {
    final colors = semanticColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : colors.secondaryText,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStatTile({
    required String label,
    required String value,
    required IconData icon,
    required AppSemanticColors colors,
    Color? accentColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (accentColor ?? colors.primaryText).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: accentColor ?? colors.primaryText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accentColor ?? colors.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);

    // Charts, peak-day and average-order-value must use the same order set as
    // the report totals. Pending and cancelled orders are transactions, not
    // sales, so they do not belong in this sales overview.
    final activeOrders = (widget.filteredOrders ?? widget.allOrders)
        .where((order) => order.contributesToSales)
        .toList();
    final activeSummary = widget.summary ?? SalesSummary.fromOrders(activeOrders);
    final rangeLabel = widget.dateRangeLabel ?? _dateRangeLabel();

    // Peak sales day calculation
    final dailyTotals = <DateTime, double>{};
    for (final o in activeOrders) {
      final day = DateTime(o.placedAt.year, o.placedAt.month, o.placedAt.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + o.total;
    }
    DateTime? peakDay;
    double peakSales = 0.0;
    dailyTotals.forEach((day, sales) {
      if (sales > peakSales) {
        peakSales = sales;
        peakDay = day;
      }
    });
    final peakDayText = peakDay != null
        ? '${DateFormat('MMM d').format(peakDay!)} (${_fmtMoney(peakSales)})'
        : 'N/A';

    // Avg Order Value
    final aovText = _fmtMoney(activeOrders.isEmpty
        ? 0
        : activeSummary.grossSales / activeOrders.length);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1050;

              final presetControls = Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.hoverSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.subtleBorder),
                ),
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    _presetPill('All Time', DatePreset.all, colors),
                    _presetPill('Today', DatePreset.today, colors),
                    _presetPill('This Week', DatePreset.thisWeek, colors),
                    _presetPill('This Month', DatePreset.thisMonth, colors),
                    _presetPill(
                      _selectedPreset == DatePreset.custom
                          ? _dateRangeLabel()
                          : 'Custom Date',
                      DatePreset.custom,
                      colors,
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickCustomDateRange,
                    ),
                  ],
                ),
              );

              final metricControls = Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.hoverSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.subtleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chartMetricToggle('Sales', showSalesMetric, () {
                      setState(() => showSalesMetric = true);
                    }),
                    _chartMetricToggle('Orders', !showSalesMetric, () {
                      setState(() => showSalesMetric = false);
                    }),
                  ],
                ),
              );

              final rightControls = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.showDateControls) presetControls,
                  metricControls,
                  if (widget.trailingHeaderControls != null)
                    widget.trailingHeaderControls!,
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Overview',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily performance for $rangeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    rightControls,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Overview',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily performance for $rangeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  rightControls,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: SalesLineChart(
              orders: activeOrders,
              startDate: _startDate,
              endDate: _endDate,
              isSales: showSalesMetric,
              colors: colors,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.subtleBorder),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final isNarrow = box.maxWidth < 620;
              final statItems = [
                _summaryStatTile(
                  label: 'AVG. ORDER VALUE',
                  value: aovText,
                  icon: Icons.shopping_bag_outlined,
                  colors: colors,
                ),
                _summaryStatTile(
                  label: 'PEAK SALES DAY',
                  value: peakDayText,
                  icon: Icons.star_outline_rounded,
                  colors: colors,
                ),
              ];

              if (isNarrow) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: statItems,
                );
              }

              return Row(
                children: [
                  Expanded(child: statItems[0]),
                  Container(width: 1, height: 30, color: colors.subtleBorder),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: statItems[1],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

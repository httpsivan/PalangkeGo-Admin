import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';

String _fmtMoney(num value) => '₱${NumberFormat('#,##0.00').format(value)}';

enum DatePreset { today, thisWeek, thisMonth, custom, all }

class SalesReportsPage extends ConsumerStatefulWidget {
  const SalesReportsPage({super.key});

  @override
  ConsumerState<SalesReportsPage> createState() => _SalesReportsPageState();
}
class _SalesReportsPageState extends ConsumerState<SalesReportsPage> {
  final search = TextEditingController();
  final minimum = TextEditingController();
  final maximum = TextEditingController();
  final tableController = ScrollController();

  DatePreset selectedPreset = DatePreset.thisMonth;
  DateTime? startDate;
  DateTime? endDate;

  String category = 'All Categories';
  String vendor = 'All Stall Holders';
  OrderStatus? orderStatus;
  PaymentStatus? paymentStatus;
  PaymentMethod? paymentMethod;
  String sort = 'Newest first';
  int page = 0;
  bool exporting = false;
  bool showSalesMetric = true; // true = Sales, false = Orders
  bool topSellersPeriod = true; // true = Period, false = All-Time

  @override
  void initState() {
    super.initState();
    _applyPreset(DatePreset.thisMonth, updateState: false);
  }

  @override
  void dispose() {
    search.dispose();
    minimum.dispose();
    maximum.dispose();
    tableController.dispose();
    super.dispose();
  }

  void _applyPreset(DatePreset preset, {bool updateState = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? s;
    DateTime? e;

    switch (preset) {
      case DatePreset.today:
        s = today;
        e = today;
        break;
      case DatePreset.thisWeek:
        // Monday as start of week
        s = today.subtract(Duration(days: today.weekday - 1));
        e = s.add(const Duration(days: 6));
        break;
      case DatePreset.thisMonth:
        s = DateTime(now.year, now.month, 1);
        e = DateTime(now.year, now.month + 1, 0);
        break;
      case DatePreset.all:
        s = null;
        e = null;
        break;
      case DatePreset.custom:
        // Handled by custom date picker
        return;
    }

    if (updateState) {
      setState(() {
        selectedPreset = preset;
        startDate = s;
        endDate = e;
        page = 0;
      });
    } else {
      selectedPreset = preset;
      startDate = s;
      endDate = e;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF10B981),
                ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        selectedPreset = DatePreset.custom;
        startDate = range.start;
        endDate = range.end;
        page = 0;
      });
    }
  }

  String _dateRangeLabel() {
    if (startDate == null && endDate == null) {
      return 'All time';
    }
    if (startDate != null && endDate != null) {
      if (startDate!.isAtSameMomentAs(endDate!)) {
        return DateFormat('MMM d, yyyy').format(startDate!);
      }
      return '${DateFormat('MMM d').format(startDate!)} – ${DateFormat('MMM d, yyyy').format(endDate!)}';
    }
    if (startDate != null) {
      return 'From ${DateFormat('MMM d, yyyy').format(startDate!)}';
    }
    return 'Until ${DateFormat('MMM d, yyyy').format(endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final orders = ref.watch(appDataProvider.select((s) => s.orders));
    final categories = <String>{
      'All Categories',
      ...orders.expand((item) => item.items.map((line) => line.category)),
    }.toList();
    final vendors = <String>{
      'All Stall Holders',
      ...orders.map((item) => item.vendorName),
    }.toList();

    final filteredOrders = _filtered(orders);
    final summary = SalesSummary.fromOrders(filteredOrders);

    final totalPages = (filteredOrders.length / 10).ceil();
    final safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final visible = filteredOrders.skip(safePage * 10).take(10).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideDesktop = constraints.maxWidth >= 1200;
        final isMediumScreen =
            constraints.maxWidth >= 850 && constraints.maxWidth < 1200;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. PAGE HEADER WITH DATE RANGE SELECTOR & EXPORT
            PageHeader(
              title: 'Sales Reports',
              subtitle:
                  'Review marketplace sales, orders, payments, refunds, and net revenue.',
              trailing: _buildHeaderControls(colors, filteredOrders, summary),
              metrics: [
                MetricCardData(
                  value: _fmtMoney(summary.grossSales),
                  label: 'TOTAL SALES',
                  icon: Icons.payments_outlined,
                  accent: const Color(0xFF10B981),
                ),
                MetricCardData(
                  value: _fmtMoney(summary.netRevenue),
                  label: 'NET REVENUE',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF059669),
                ),
                MetricCardData(
                  value: '${summary.totalOrders}',
                  label: 'TOTAL ORDERS',
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFF3B82F6),
                ),
                MetricCardData(
                  value: '${summary.completedOrders}',
                  label: 'COMPLETED ORDERS',
                  icon: Icons.check_circle_outline_rounded,
                  accent: const Color(0xFF10B981),
                ),
                MetricCardData(
                  value: _fmtMoney(summary.refunds),
                  label: 'REFUNDS',
                  icon: Icons.replay_rounded,
                  accent: const Color(0xFFEF4444),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(30, 24, 30, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. ANALYTICS SECTION: SALES OVERVIEW CHART, SALES BY CATEGORY, & TOP SELLERS
                  if (isWideDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 46,
                          child: _buildSalesOverviewCard(
                              colors, filteredOrders),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 27,
                          child: _buildCategorySalesCard(
                              colors, filteredOrders, summary.grossSales),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 27,
                          child: _buildTopSellersCard(
                              colors, filteredOrders),
                        ),
                      ],
                    )
                  else if (isMediumScreen) ...[
                    _buildSalesOverviewCard(colors, filteredOrders),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCategorySalesCard(
                              colors, filteredOrders, summary.grossSales),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTopSellersCard(
                              colors, filteredOrders),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildSalesOverviewCard(colors, filteredOrders),
                    const SizedBox(height: 16),
                    _buildCategorySalesCard(
                        colors, filteredOrders, summary.grossSales),
                    const SizedBox(height: 16),
                    _buildTopSellersCard(
                        colors, filteredOrders),
                  ],

                  const SizedBox(height: 24),

                  // 3. RECENT TRANSACTIONS TABLE
                  _buildTransactionsSection(
                    colors: colors,
                    filteredOrders: filteredOrders,
                    visibleOrders: visible,
                    categories: categories,
                    vendors: vendors,
                    safePage: safePage,
                    totalPages: totalPages,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CONTROLS: DATE RANGE PRESETS & EXPORT
  // ---------------------------------------------------------------------------
  Widget _buildHeaderControls(
      AppSemanticColors colors, List<Order> values, SalesSummary summary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date Presets
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderOnHero),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _presetPill('Today', DatePreset.today),
              _presetPill('This Week', DatePreset.thisWeek),
              _presetPill('This Month', DatePreset.thisMonth),
              _presetPill(
                selectedPreset == DatePreset.custom
                    ? _dateRangeLabel()
                    : 'Custom Date',
                DatePreset.custom,
                onTap: _pickCustomDateRange,
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),

        // Export Dropdown Menu
        PopupMenuButton<String>(
          tooltip: 'Export reports',
          enabled: !exporting,
          onSelected: (action) {
            if (action == 'pdf') {
              _exportPdf(values, summary);
            } else if (action == 'excel') {
              _exportExcel(values, summary);
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 10),
                  Text('Export PDF', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'excel',
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined,
                      size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 10),
                  Text('Export Excel', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderOnHero),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                exporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded,
                        size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Export',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetPill(String label, DatePreset preset,
      {VoidCallback? onTap, IconData? icon}) {
    final isSelected = selectedPreset == preset;
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
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SALES OVERVIEW CHART
  // ---------------------------------------------------------------------------
  Widget _buildSalesOverviewCard(
      AppSemanticColors colors, List<Order> orders) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'Daily performance for ${_dateRangeLabel()}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.mutedText,
                    ),
                  ),
                ],
              ),
              Container(
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
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: _SalesLineChart(
              orders: orders,
              startDate: startDate,
              endDate: endDate,
              isSales: showSalesMetric,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartMetricToggle(
      String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SALES BY CATEGORY
  // ---------------------------------------------------------------------------
  Widget _buildCategorySalesCard(
      AppSemanticColors colors, List<Order> orders, double totalGross) {
    final predefined = [
      (
        name: 'Fish',
        style: CategoryColors.fish,
      ),
      (
        name: 'Meat',
        style: CategoryColors.meat,
      ),
      (
        name: 'Fruits',
        style: CategoryColors.fruits,
      ),
      (
        name: 'Vegetables',
        style: CategoryColors.vegetables,
      ),
    ];

    // Compute sales per category
    final salesMap = <String, double>{};
    for (final o in orders) {
      for (final item in o.items) {
        final cat = item.category.trim().toLowerCase();
        salesMap[cat] = (salesMap[cat] ?? 0.0) + item.subtotal;
      }
    }

    final computedTotal = salesMap.values.fold<double>(0.0, (a, b) => a + b);
    final baseline = computedTotal > 0 ? computedTotal : 1.0;

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
          Text(
            'Sales by Category',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Marketplace volume distribution',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          ...predefined.map((cat) {
            final sales = salesMap[cat.name.toLowerCase()] ?? 0.0;
            final pct = (sales / baseline).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cat.style.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cat.style.border, width: 1),
                        ),
                        child: _CategoryIcon(
                          category: cat.name,
                          color: cat.style.text,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                      Text(
                        _fmtMoney(sales),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: colors.hoverSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(cat.style.accent),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP SELLERS CARD
  // ---------------------------------------------------------------------------
  Widget _buildTopSellersCard(AppSemanticColors colors, List<Order> orders) {
    // Dynamic calculation from current filtered orders
    final vendorMap = <String, (int count, double revenue)>{};
    for (final o in orders) {
      final current = vendorMap[o.vendorName] ?? (0, 0.0);
      vendorMap[o.vendorName] = (current.$1 + 1, current.$2 + o.total);
    }
    final sortedVendors = vendorMap.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    final count = topSellersPeriod
        ? sortedVendors.length.clamp(0, 4)
        : topSellerNames.length.clamp(0, 4);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Sellers',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topSellersPeriod
                          ? 'Leading stall holders by sales'
                          : 'All-time leading stall holders',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.hoverSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.subtleBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chartMetricToggle('Period', topSellersPeriod, () {
                      setState(() => topSellersPeriod = true);
                    }),
                    _chartMetricToggle('All-Time', !topSellersPeriod, () {
                      setState(() => topSellersPeriod = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (count == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 38),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 26, color: colors.mutedText),
                    const SizedBox(height: 8),
                    Text(
                      'No seller records in this period',
                      style: TextStyle(fontSize: 12, color: colors.mutedText),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(count, (index) {
              final String sellerName;
              final String orderSubtext;
              final String revenueText;

              if (topSellersPeriod) {
                final entry = sortedVendors[index];
                sellerName = entry.key;
                orderSubtext = '${entry.value.$1} orders';
                revenueText = _fmtMoney(entry.value.$2);
              } else {
                sellerName = topSellerNames[index];
                orderSubtext = topSellerOrders[index];
                revenueText = topSellerRevenue[index].startsWith('₱')
                    ? topSellerRevenue[index]
                    : '₱${topSellerRevenue[index]}';
              }

              final isSelected = vendor == sellerName;

              return Padding(
                padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 14),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (vendor == sellerName) {
                        vendor = 'All Stall Holders';
                      } else {
                        vendor = sellerName;
                      }
                      page = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10B981).withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AvatarCircle(name: sellerName, size: 32),
                            Positioned(
                              right: -3,
                              top: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? const Color(0xFF10B981)
                                      : colors.elevatedSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: index == 0
                                        ? Colors.white
                                        : colors.subtleBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: index == 0
                                        ? Colors.white
                                        : colors.primaryText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderSubtext,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              revenueText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Revenue',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: colors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECENT TRANSACTIONS TABLE SECTION
  // ---------------------------------------------------------------------------
  Widget _buildTransactionsSection({
    required AppSemanticColors colors,
    required List<Order> filteredOrders,
    required List<Order> visibleOrders,
    required List<String> categories,
    required List<String> vendors,
    required int safePage,
    required int totalPages,
  }) {
    return DataPanel(
      title: 'Recent Transactions',
      subtitle: 'Showing ${filteredOrders.length} matching order records',
      headerAction: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterButton(
            label: 'Filters',
            icon: Icons.tune_rounded,
            onTap: () => _showFilters(categories, vendors),
          ),
          FilterMenuButton(
            label: 'Sort: $sort',
            icon: Icons.sort_rounded,
            values: const [
              'Newest first',
              'Oldest first',
              'Highest total',
              'Lowest total',
            ],
            onSelected: (value) => setState(() {
              sort = value;
              page = 0;
            }),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search & Filter Toolbar
          Toolbar(
            controller: search,
            searchHint:
                'Search order ID, transaction, customer, or stall holder...',
            onChanged: (_) => setState(() => page = 0),
            onClear: _clearFilters,
            trailing: [
              if (selectedPreset != DatePreset.thisMonth ||
                  startDate != null ||
                  endDate != null)
                _chip(
                  _dateRangeLabel(),
                  () => _applyPreset(DatePreset.thisMonth),
                ),
              if (category != 'All Categories')
                _chip(category, () => setState(() => category = 'All Categories')),
              if (vendor != 'All Stall Holders')
                _chip(vendor, () => setState(() => vendor = 'All Stall Holders')),
              if (orderStatus != null)
                _chip('Order: ${enumLabel(orderStatus!)}',
                    () => setState(() => orderStatus = null)),
              if (paymentStatus != null)
                _chip('Payment: ${enumLabel(paymentStatus!)}',
                    () => setState(() => paymentStatus = null)),
              if (minimum.text.trim().isNotEmpty)
                _chip('Min: ₱${minimum.text.trim()}',
                    () => setState(() => minimum.clear())),
              if (maximum.text.trim().isNotEmpty)
                _chip('Max: ₱${maximum.text.trim()}',
                    () => setState(() => maximum.clear())),
            ],
          ),

          // Scrollable Data Table
          ScrollableDataTable(
            columns: const [
              DataColumn(label: Text('ORDER ID')),
              DataColumn(label: Text('DATE & TIME')),
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('STALL HOLDER')),
              DataColumn(label: Text('TOTAL')),
              DataColumn(label: Text('PAYMENT')),
              DataColumn(label: Text('PAYMENT STATUS')),
              DataColumn(label: Text('ORDER STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: visibleOrders.map((item) => _transactionRow(item, colors)).toList(),
            verticalController: tableController,
            minWidth: 1080,
            rowHeight: 56,
            emptyState: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 36,
                      color: colors.mutedText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No sales found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try changing your date range or filters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _clearFilters,
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (filteredOrders.isNotEmpty)
            PaginationBar(
              total: filteredOrders.length,
              start: safePage * 10 + 1,
              end: ((safePage + 1) * 10).clamp(0, filteredOrders.length),
              page: safePage,
              pageCount: totalPages,
              onPageChanged: (value) => setState(() => page = value),
              showSummary: search.text.trim().isNotEmpty ||
                  category != 'All Categories' ||
                  vendor != 'All Stall Holders',
            ),
        ],
      ),
    );
  }

  DataRow _transactionRow(Order item, AppSemanticColors colors) {
    return DataRow(
      cells: [
        // Order ID
        DataCell(
          Text(
            item.id,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: colors.primaryText,
            ),
          ),
        ),

        // Date & Time
        DataCell(
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(item.placedAt),
            style: TextStyle(
              fontSize: 12,
              color: colors.secondaryText,
            ),
          ),
        ),

        // Customer
        DataCell(
          Text(
            item.customerName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),

        // Vendor / Stall Holder
        DataCell(
          Text(
            item.vendorName,
            style: TextStyle(
              fontSize: 12,
              color: colors.secondaryText,
            ),
          ),
        ),

        // Total
        DataCell(
          Text(
            _fmtMoney(item.total),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: colors.primaryText,
            ),
          ),
        ),

        // Payment Method
        DataCell(
          Text(
            enumLabel(item.paymentMethod),
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Payment Status Pill
        DataCell(_paymentStatusBadge(item.paymentStatus)),

        // Order Status Pill
        DataCell(_orderStatusBadge(item.status)),

        // Action: View Details
        DataCell(
          OutlinedButton.icon(
            onPressed: () => _openOrderDetailsDialog(context, item),
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: colors.subtleBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentStatusBadge(PaymentStatus status) {
    final (kind, label) = switch (status) {
      PaymentStatus.paid => (BadgeKind.success, 'Paid'),
      PaymentStatus.pending => (BadgeKind.warning, 'Pending'),
      PaymentStatus.failed => (BadgeKind.danger, 'Failed'),
      PaymentStatus.refunded || PaymentStatus.partiallyRefunded => (
          BadgeKind.purple,
          'Refunded'
        ),
    };
    return StatusBadge(label: label, kind: kind);
  }

  Widget _orderStatusBadge(OrderStatus status) {
    final (kind, label) = switch (status) {
      OrderStatus.completed => (BadgeKind.success, 'Completed'),
      OrderStatus.processing => (BadgeKind.warning, 'Processing'),
      OrderStatus.pending => (BadgeKind.warning, 'Pending'),
      OrderStatus.cancelled => (BadgeKind.danger, 'Cancelled'),
      OrderStatus.refunded => (BadgeKind.purple, 'Refunded'),
    };
    return StatusBadge(label: label, kind: kind);
  }

  Widget _chip(String label, VoidCallback onRemove) {
    final isCat = CategoryColors.isCategory(label);
    final catStyle = isCat ? CategoryColors.get(label) : null;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isCat ? FontWeight.w600 : FontWeight.normal,
          color: isCat ? catStyle!.text : null,
        ),
      ),
      onDeleted: onRemove,
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 12,
        color: isCat ? catStyle!.text : null,
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: isCat ? catStyle!.background : Colors.transparent,
      side: BorderSide(
        color: isCat ? catStyle!.border : const Color(0xFFE2E8F0),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERING LOGIC
  // ---------------------------------------------------------------------------
  List<Order> _filtered(List<Order> source) {
    final query = search.text.trim().toLowerCase();
    final min = double.tryParse(minimum.text.trim());
    final max = double.tryParse(maximum.text.trim());

    final list = source.where((item) {
      final searchable =
          '${item.id} ${item.transactionId} ${item.customerName} ${item.vendorName} ${item.stallName}'
              .toLowerCase();

      final startCondition = startDate == null ||
          !item.placedAt.isBefore(DateTime(
              startDate!.year, startDate!.month, startDate!.day, 0, 0, 0));
      final endCondition = endDate == null ||
          !item.placedAt.isAfter(DateTime(
              endDate!.year, endDate!.month, endDate!.day, 23, 59, 59));

      final categoryMatches = category == 'All Categories' ||
          item.items.any((line) => line.category == category);

      return (query.isEmpty || searchable.contains(query)) &&
          (vendor == 'All Stall Holders' || item.vendorName == vendor) &&
          (orderStatus == null || item.status == orderStatus) &&
          (paymentStatus == null || item.paymentStatus == paymentStatus) &&
          (paymentMethod == null || item.paymentMethod == paymentMethod) &&
          categoryMatches &&
          startCondition &&
          endCondition &&
          (min == null || item.total >= min) &&
          (max == null || item.total <= max);
    }).toList();

    list.sort((a, b) {
      if (sort == 'Highest total') return b.total.compareTo(a.total);
      if (sort == 'Lowest total') return a.total.compareTo(b.total);
      final result = a.placedAt.compareTo(b.placedAt);
      return sort == 'Oldest first' ? result : -result;
    });

    return list;
  }

  void _clearFilters() => setState(() {
        search.clear();
        category = 'All Categories';
        vendor = 'All Stall Holders';
        orderStatus = null;
        paymentStatus = null;
        paymentMethod = null;
        minimum.clear();
        maximum.clear();
        sort = 'Newest first';
        page = 0;
        _applyPreset(DatePreset.thisMonth);
      });

  // ---------------------------------------------------------------------------
  // FILTERS DIALOG
  // ---------------------------------------------------------------------------
  Future<void> _showFilters(
      List<String> categories, List<String> vendors) async {
    var nextCategory = category;
    var nextVendor = vendor;
    var nextOrderStatus = orderStatus;
    var nextPaymentStatus = paymentStatus;
    var nextPaymentMethod = paymentMethod;
    var nextStart = startDate;
    var nextEnd = endDate;
    final minController = TextEditingController(text: minimum.text);
    final maxController = TextEditingController(text: maximum.text);
    String? error;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Filter Transactions',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdown('Category', nextCategory, categories,
                        (value) => setDialogState(() => nextCategory = value!)),
                    _dropdown('Stall holder', nextVendor, vendors,
                        (value) => setDialogState(() => nextVendor = value!)),
                    _dropdown(
                      'Order status',
                      nextOrderStatus == null
                          ? 'All statuses'
                          : enumLabel(nextOrderStatus!),
                      ['All statuses', ...OrderStatus.values.map(enumLabel)],
                      (value) => setDialogState(() => nextOrderStatus =
                          value == 'All statuses'
                              ? null
                              : OrderStatus.values.firstWhere(
                                  (item) => enumLabel(item) == value)),
                    ),
                    _dropdown(
                      'Payment status',
                      nextPaymentStatus == null
                          ? 'All statuses'
                          : enumLabel(nextPaymentStatus!),
                      [
                        'All statuses',
                        ...PaymentStatus.values.map(enumLabel)
                      ],
                      (value) => setDialogState(() => nextPaymentStatus =
                          value == 'All statuses'
                              ? null
                              : PaymentStatus.values.firstWhere(
                                  (item) => enumLabel(item) == value)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Total (₱)',
                              prefixText: '₱ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Total (₱)',
                              prefixText: '₱ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Date Range Filter',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                initialDateRange: nextStart != null &&
                                        nextEnd != null
                                    ? DateTimeRange(
                                        start: nextStart!, end: nextEnd!)
                                    : null,
                              );
                              if (range != null) {
                                setDialogState(() {
                                  nextStart = range.start;
                                  nextEnd = range.end;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_month_outlined,
                                size: 16),
                            label: Text(
                              nextStart == null
                                  ? 'Choose date range'
                                  : '${DateFormat('MMM d').format(nextStart!)} - ${DateFormat('MMM d').format(nextEnd!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        if (nextStart != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear date filter',
                            onPressed: () => setDialogState(() {
                              nextStart = null;
                              nextEnd = null;
                            }),
                            icon: const Icon(Icons.clear_rounded, size: 18),
                          ),
                        ],
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: semanticColors(context).danger,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final min = double.tryParse(minController.text.trim());
                  final max = double.tryParse(maxController.text.trim());
                  if (minController.text.trim().isNotEmpty && min == null ||
                      maxController.text.trim().isNotEmpty && max == null) {
                    setDialogState(() => error = 'Amounts must be valid numbers.');
                    return;
                  }
                  if (min != null && max != null && max < min) {
                    setDialogState(() =>
                        error = 'Maximum cannot be lower than minimum.');
                    return;
                  }
                  setState(() {
                    category = nextCategory;
                    vendor = nextVendor;
                    orderStatus = nextOrderStatus;
                    paymentStatus = nextPaymentStatus;
                    paymentMethod = nextPaymentMethod;
                    startDate = nextStart;
                    endDate = nextEnd;
                    minimum.text = minController.text;
                    maximum.text = maxController.text;
                    selectedPreset = DatePreset.custom;
                    page = 0;
                  });
                  Navigator.pop(dialogContext);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      );
    } finally {
      minController.dispose();
      maxController.dispose();
    }
  }

  Widget _dropdown(String label, String value, List<String> values,
          ValueChanged<String?> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: values.contains(value) ? value : values.first,
          decoration: InputDecoration(labelText: label),
          items: values
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: CategoryColors.isCategory(item)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryDot(category: item, size: 8),
                              const SizedBox(width: 8),
                              Text(item),
                            ],
                          )
                        : Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );

  // ---------------------------------------------------------------------------
  // ORDER DETAILS FLOATING MODAL DIALOG
  // ---------------------------------------------------------------------------
  void _openOrderDetailsDialog(BuildContext context, Order order) {
    showBlurredDialog(
      context,
      (context) => _OrderDetailsDialog(order: order),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT UTILITIES
  // ---------------------------------------------------------------------------
  Future<void> _exportPdf(List<Order> values, SalesSummary summary) async {
    setState(() => exporting = true);
    try {
      final lines = <String>[
        'Generated: ${longDate.format(DateTime.now())}',
        'Period: ${_dateRangeLabel()}',
        'Total Orders: ${summary.totalOrders} | Completed: ${summary.completedOrders} | Pending: ${summary.pendingOrders}',
        'Gross Sales: ${_fmtMoney(summary.grossSales)} | Refunds: ${_fmtMoney(summary.refunds)} | Net Revenue: ${_fmtMoney(summary.netRevenue)}',
        '',
        'Order ID | Date | Customer | Stall Holder | Total | Payment | Payment Status | Order Status',
        ...values.map((item) =>
            '${item.id} | ${DateFormat('yyyy-MM-dd HH:mm').format(item.placedAt)} | ${item.customerName} | ${item.vendorName} | ${_fmtMoney(item.total)} | ${enumLabel(item.paymentMethod)} | ${enumLabel(item.paymentStatus)} | ${enumLabel(item.status)}'),
      ];
      downloadBytes(
        buildSimplePdf(title: 'PalengkeGo Sales Report', lines: lines),
        'palengkego_sales_report.pdf',
        'application/pdf',
      );
      await ref.read(appDataProvider.notifier).recordAudit(
            action: AuditAction.exportPdf,
            targetEntityType: 'Sales Report',
            targetEntityId: 'sales-report',
            targetUserName: 'System',
            previousValue: '',
            newValue: '${values.length} records',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report downloaded successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _exportExcel(List<Order> values, SalesSummary summary) async {
    setState(() => exporting = true);
    try {
      final summaryRows = <List<Object?>>[
        ['PalengkeGo Sales Summary', ''],
        ['Reporting Period', _dateRangeLabel()],
        ['Generated By', ref.read(adminProfileProvider).name],
        ['Generated At', longDate.format(DateTime.now())],
        ['Total Orders', summary.totalOrders],
        ['Completed Orders', summary.completedOrders],
        ['Pending Orders', summary.pendingOrders],
        ['Cancelled Orders', summary.cancelledOrders],
        ['Refunded Orders', summary.refundedOrders],
        ['Gross Sales', summary.grossSales],
        ['Discounts', summary.discounts],
        ['Refunds', summary.refunds],
        ['Platform Fees', summary.platformFees],
        ['Net Revenue', summary.netRevenue],
      ];
      final transactions = <List<Object?>>[
        [
          'Order ID',
          'Transaction ID',
          'Date / Time',
          'Customer',
          'Stall Holder',
          'Stall',
          'Items',
          'Category',
          'Quantity',
          'Subtotal',
          'Discounts',
          'Delivery Fee',
          'Platform Fee',
          'Refund',
          'Total',
          'Payment Method',
          'Payment Status',
          'Order Status',
        ],
        ...values.map((item) => item.toRow()),
      ];
      downloadBytes(
        buildSalesWorkbook(
          summaryRows: summaryRows,
          transactionRows: transactions,
        ),
        'palengkego_sales_report.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await ref.read(appDataProvider.notifier).recordAudit(
            action: AuditAction.exportExcel,
            targetEntityType: 'Sales Report',
            targetEntityId: 'sales-report',
            targetUserName: 'System',
            previousValue: '',
            newValue: '${values.length} records',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Excel workbook downloaded successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

// =============================================================================
// ORDER DETAILS FLOATING MODAL DIALOG
// =============================================================================
class _OrderDetailsDialog extends StatelessWidget {
  const _OrderDetailsDialog({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final narrow = MediaQuery.sizeOf(context).width < 680;

    return Dialog(
      backgroundColor: colors.cardBackground,
      insetPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 16 : 32,
        vertical: narrow ? 20 : 36,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(bottom: BorderSide(color: colors.subtleBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transaction: ${order.transactionId}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close details',
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  // Customer Information
                  _sectionHeader('CUSTOMER INFORMATION', colors),
                  _card(
                    colors,
                    child: Row(
                      children: [
                        AvatarCircle(name: order.customerName, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Marketplace Customer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Order Information
                  _sectionHeader('ORDER INFORMATION', colors),
                  _card(
                    colors,
                    child: Column(
                      children: [
                        _infoRow('Transaction ID', order.transactionId, colors),
                        _infoRow(
                          'Date & Time',
                          DateFormat('MMMM d, yyyy • h:mm a')
                              .format(order.placedAt),
                          colors,
                        ),
                        _infoRow('Stall Holder', order.vendorName, colors),
                        _infoRow('Stall Location', order.stallName, colors,
                            isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Items
                  _sectionHeader('ITEMS (${order.items.length})', colors),
                  _card(
                    colors,
                    child: Column(
                      children: order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        CategoryBadge(
                                          category: item.category,
                                          fontSize: 9.5,
                                        ),
                                        Text(
                                          'Qty: ${item.quantity} × ${_fmtMoney(item.unitPrice)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _fmtMoney(item.subtotal),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Financial Breakdown
                  _sectionHeader('FINANCIAL BREAKDOWN', colors),
                  _card(
                    colors,
                    child: Column(
                      children: [
                        _financialRow('Subtotal', _fmtMoney(order.subtotal), colors),
                        _financialRow('Discount', '-${_fmtMoney(order.discounts)}',
                            colors,
                            valueColor: const Color(0xFFEF4444)),
                        _financialRow(
                            'Delivery Fee', _fmtMoney(order.deliveryFee), colors),
                        _financialRow(
                            'Platform Fee', _fmtMoney(order.platformFee), colors),
                        _financialRow(
                            'Refund', '-${_fmtMoney(order.refundAmount)}', colors,
                            valueColor: order.refundAmount > 0
                                ? const Color(0xFF8B5CF6)
                                : colors.mutedText),
                        Divider(color: colors.subtleBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Total',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                            Text(
                              _fmtMoney(order.total),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Payment & Status
                  _sectionHeader('PAYMENT & STATUS', colors),
                  _card(
                    colors,
                    child: Column(
                      children: [
                        _infoRow(
                          'Payment Method',
                          enumLabel(order.paymentMethod),
                          colors,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Status',
                                  style: TextStyle(
                                      fontSize: 12, color: colors.secondaryText)),
                              _paymentStatusBadge(order.paymentStatus),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order Status',
                                  style: TextStyle(
                                      fontSize: 12, color: colors.secondaryText)),
                              _statusBadge(order.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(top: BorderSide(color: colors.subtleBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      side: BorderSide(color: colors.subtleBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryText,
                      ),
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

  Widget _sectionHeader(String title, AppSemanticColors colors) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colors.secondaryText,
          ),
        ),
      );

  Widget _card(AppSemanticColors colors, {required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.hoverSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: child,
      );

  Widget _infoRow(String label, String value, AppSemanticColors colors,
          {bool isLast = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: colors.secondaryText)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _financialRow(String label, String value, AppSemanticColors colors,
          {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: colors.secondaryText)),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colors.primaryText,
              ),
            ),
          ],
        ),
      );

  Widget _statusBadge(OrderStatus status) {
    final (kind, label) = switch (status) {
      OrderStatus.completed => (BadgeKind.success, 'Completed'),
      OrderStatus.processing => (BadgeKind.warning, 'Processing'),
      OrderStatus.pending => (BadgeKind.warning, 'Pending'),
      OrderStatus.cancelled => (BadgeKind.danger, 'Cancelled'),
      OrderStatus.refunded => (BadgeKind.purple, 'Refunded'),
    };
    return StatusBadge(label: label, kind: kind);
  }

  Widget _paymentStatusBadge(PaymentStatus status) {
    final (kind, label) = switch (status) {
      PaymentStatus.paid => (BadgeKind.success, 'Paid'),
      PaymentStatus.pending => (BadgeKind.warning, 'Pending'),
      PaymentStatus.failed => (BadgeKind.danger, 'Failed'),
      PaymentStatus.refunded || PaymentStatus.partiallyRefunded => (
          BadgeKind.purple,
          'Refunded'
        ),
    };
    return StatusBadge(label: label, kind: kind);
  }
}

// =============================================================================
// INTERACTIVE SALES OVERVIEW LINE & AREA CHART
// =============================================================================
class _SalesLineChart extends StatefulWidget {
  const _SalesLineChart({
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
  State<_SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<_SalesLineChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // 1. Group orders by day
    final dailyData = <DateTime, (double sales, int orders)>{};

    for (final o in widget.orders) {
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
                painter: _ChartPainter(
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

class _ChartPainter extends CustomPainter {
  _ChartPainter({
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
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.isSales != isSales ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

// =============================================================================
// CATEGORY VECTOR ICONS (FISH, MEAT, FRUITS, VEGETABLES)
// =============================================================================
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.category,
    required this.color,
    this.size = 16,
  });

  final String category;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CategoryIconPainter(
          category: category.trim().toLowerCase(),
          color: color,
        ),
      ),
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  const _CategoryIconPainter({
    required this.category,
    required this.color,
  });

  final String category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (category) {
      case 'fish':
        // Fish outline facing right
        final body = Path()
          ..moveTo(21.0, 12.0)
          ..cubicTo(16.5, 6.0, 10.5, 6.5, 5.5, 11.0)
          ..lineTo(2.5, 7.0)
          ..quadraticBezierTo(4.0, 12.0, 2.5, 17.0)
          ..lineTo(5.5, 13.0)
          ..cubicTo(10.5, 17.5, 16.5, 18.0, 21.0, 12.0)
          ..close();
        canvas.drawPath(body, stroke);
        // Eye
        canvas.drawCircle(const Offset(17.5, 11.0), 1.1, fill);
        // Gill curve
        final gill = Path()
          ..moveTo(14.5, 9.5)
          ..quadraticBezierTo(13.2, 12.0, 14.5, 14.5);
        canvas.drawPath(gill, stroke);
        break;

      case 'meat':
        // Prime steak cut / butcher meat contour
        final meat = Path()
          ..moveTo(11.5, 4.5)
          ..cubicTo(17.5, 4.5, 21.0, 8.0, 21.0, 12.5)
          ..cubicTo(21.0, 17.5, 16.5, 20.0, 12.0, 20.0)
          ..cubicTo(7.0, 20.0, 3.5, 17.0, 3.5, 13.0)
          ..cubicTo(3.5, 9.5, 6.5, 7.5, 9.0, 7.5)
          ..cubicTo(9.5, 7.5, 10.0, 5.5, 11.5, 4.5)
          ..close();
        canvas.drawPath(meat, stroke);
        // Bone center
        canvas.drawCircle(const Offset(8.5, 12.5), 2.0, stroke);
        canvas.drawCircle(const Offset(8.5, 12.5), 0.8, fill);
        // Marbling line
        final marble = Path()
          ..moveTo(13.0, 8.5)
          ..quadraticBezierTo(16.5, 11.5, 15.0, 15.5);
        canvas.drawPath(marble, stroke..strokeWidth = 1.3);
        break;

      case 'fruits':
      case 'fruit':
        // Fresh natural apple / fruit with stem & leaf
        final fruit = Path()
          ..moveTo(12.0, 7.5)
          ..cubicTo(9.0, 5.5, 4.0, 6.5, 4.0, 12.0)
          ..cubicTo(4.0, 17.0, 8.0, 20.5, 12.0, 20.5)
          ..cubicTo(16.0, 20.5, 20.0, 17.0, 20.0, 12.0)
          ..cubicTo(20.0, 6.5, 15.0, 5.5, 12.0, 7.5)
          ..close();
        canvas.drawPath(fruit, stroke);
        // Fruit stem
        final stem = Path()
          ..moveTo(12.0, 7.5)
          ..quadraticBezierTo(12.5, 4.0, 14.5, 3.0);
        canvas.drawPath(stem, stroke);
        // Fresh leaf
        final leaf = Path()
          ..moveTo(12.5, 5.5)
          ..quadraticBezierTo(9.0, 3.5, 8.0, 5.5)
          ..quadraticBezierTo(10.0, 7.0, 12.5, 5.5);
        canvas.drawPath(leaf, fill);
        break;

      case 'vegetables':
      case 'vegetable':
        // Fresh carrot body with leafy greens
        final carrot = Path()
          ..moveTo(8.5, 8.5)
          ..quadraticBezierTo(12.0, 7.8, 15.5, 8.5)
          ..quadraticBezierTo(14.0, 14.5, 12.5, 21.0)
          ..quadraticBezierTo(12.0, 21.8, 11.5, 21.0)
          ..quadraticBezierTo(10.0, 14.5, 8.5, 8.5)
          ..close();
        canvas.drawPath(carrot, stroke);
        // Texture lines on carrot
        final ridge1 = Path()
          ..moveTo(9.8, 12.0)
          ..lineTo(12.5, 12.0);
        final ridge2 = Path()
          ..moveTo(11.0, 16.0)
          ..lineTo(13.5, 16.0);
        canvas.drawPath(ridge1, stroke..strokeWidth = 1.3);
        canvas.drawPath(ridge2, stroke..strokeWidth = 1.3);
        // Leafy green fronds on top
        final greens = Path()
          ..moveTo(12.0, 8.0)
          ..quadraticBezierTo(12.0, 4.5, 12.0, 3.0)
          ..moveTo(11.0, 8.0)
          ..quadraticBezierTo(9.0, 5.0, 7.5, 4.0)
          ..moveTo(13.0, 8.0)
          ..quadraticBezierTo(15.0, 5.0, 16.5, 4.0);
        canvas.drawPath(greens, stroke..strokeWidth = 1.5);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter oldDelegate) =>
      oldDelegate.category != category || oldDelegate.color != color;
}

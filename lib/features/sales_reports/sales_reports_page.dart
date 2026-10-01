import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/export/admin_export_service.dart';
import '../../core/utils/export/module_export_data_builders.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../core/widgets/sales_overview_card.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';

String _fmtMoney(num value) => '₱${NumberFormat('#,##0.00').format(value)}';

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
  final Set<String> _expandedStallHolders = <String>{};

  @override
  void initState() {
    super.initState();
    _applyPreset(DatePreset.all, updateState: false);
  }

  @override
  void dispose() {
    search.dispose();
    minimum.dispose();
    maximum.dispose();
    tableController.dispose();
    super.dispose();
  }

  void _scrollToTransactions() {
    if (!tableController.hasClients) return;
    tableController.animateTo(
      tableController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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

  static Widget _buildFloatingDatePicker(BuildContext context, Widget? child) {
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
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(
              start: DateUtils.dateOnly(startDate!),
              end: DateUtils.dateOnly(endDate!),
            )
          : null,
      firstDate: DateTime(2020),
      lastDate: today,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: _buildFloatingDatePicker,
    );

    if (picked != null) {
      setState(() {
        selectedPreset = DatePreset.custom;
        startDate = DateUtils.dateOnly(picked.start);
        endDate = DateUtils.dateOnly(picked.end);
        page = 0;
      });
    }
  }

  String _dateRangeLabel() {
    if (startDate == null && endDate == null) {
      return 'All time';
    }
    if (startDate != null && endDate != null) {
      return _formatDateRange(startDate!, endDate!);
    }
    if (startDate != null) {
      return 'From ${DateFormat('MMM d, yyyy').format(startDate!)}';
    }
    return 'Until ${DateFormat('MMM d, yyyy').format(endDate!)}';
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (DateUtils.isSameDay(start, end)) {
      return DateFormat('MMM d, yyyy').format(start);
    }
    return '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final orders = ref.watch(ordersProvider);
    final approvedStallHolders = ref
        .watch(vendorsProvider)
        .where((item) =>
            item.status == AccountStatus.active ||
            item.status == AccountStatus.offline)
        .toList();
    final categories = orders
        .where((order) => order.contributesToSales)
        .expand((item) => item.items.map((line) => line.category.trim()))
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    categories.insert(0, 'All Categories');
    final filteredOrders = _filtered(orders);
    final summary = SalesSummary.fromOrders(filteredOrders);
    final salesOrders = filteredOrders
        .where((order) => order.contributesToSales)
        .toList();
    final selectedStallHolders = approvedStallHolders
        .where((item) =>
            vendor == 'All Stall Holders' || item.name == vendor)
        .toList();
    final stallHolderGroups = _groupOrdersByStallHolder(
      salesOrders,
      selectedStallHolders,
      search.text.trim().toLowerCase(),
    );

    final totalPages = (stallHolderGroups.length / 10).ceil();
    final safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final visibleStallHolderGroups =
        stallHolderGroups.skip(safePage * 10).take(10).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. PAGE HEADER WITH DATE RANGE SELECTOR & EXPORT
            PageHeader(
              title: 'Sales Reports',
              subtitle:
                  'Review marketplace sales, orders, payments, refunds, and net revenue.',
              trailing: _buildHeaderControls(colors),
              metrics: [
                MetricCardData(
                  value: _fmtMoney(summary.grossSales),
                  label: 'TOTAL SALES',
                  icon: Icons.payments_outlined,
                  accent: const Color(0xFF10B981),
                  onTap: _scrollToTransactions,
                ),
                MetricCardData(
                  value: _fmtMoney(summary.netRevenue),
                  label: 'NET REVENUE',
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF059669),
                  onTap: _scrollToTransactions,
                ),
                MetricCardData(
                  value: '${summary.totalOrders}',
                  label: 'TOTAL ORDERS',
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFF3B82F6),
                  onTap: _scrollToTransactions,
                ),
                MetricCardData(
                  value: '${summary.completedOrders}',
                  label: 'COMPLETED ORDERS',
                  icon: Icons.check_circle_outline_rounded,
                  accent: const Color(0xFF10B981),
                  onTap: _scrollToTransactions,
                ),
                MetricCardData(
                  value: _fmtMoney(summary.refunds),
                  label: 'REFUNDS',
                  icon: Icons.replay_rounded,
                  accent: const Color(0xFFEF4444),
                  onTap: _scrollToTransactions,
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                24,
                Responsive.horizontalPadding(context),
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. RECENT TRANSACTIONS
                  _buildTransactionsSection(
                    colors: colors,
                    allOrders: orders,
                    exportOrders: filteredOrders,
                    summary: summary,
                    filteredOrders: salesOrders,
                    visibleStallHolderGroups: visibleStallHolderGroups,
                    totalStallHolders: stallHolderGroups.length,
                    categories: categories,
                    safePage: safePage,
                    totalPages: totalPages,
                  ),
                  const SizedBox(height: 24),

                  // 3. SALES ANALYTICS
                  SalesOverviewCard(
                    allOrders: salesOrders,
                    filteredOrders: salesOrders,
                    summary: summary,
                    dateRangeLabel: _dateRangeLabel(),
                    startDate: startDate,
                    endDate: endDate,
                    showDateControls: false,
                  ),
                  const SizedBox(height: 16),
                  if (constraints.maxWidth >= 850)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildCategorySalesCard(
                              colors, salesOrders, summary.grossSales),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTopSellersCard(colors, salesOrders),
                        ),
                      ],
                    )
                  else ...[
                    _buildCategorySalesCard(
                        colors, salesOrders, summary.grossSales),
                    const SizedBox(height: 16),
                    _buildTopSellersCard(colors, salesOrders),
                  ],

                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CONTROLS: DATE RANGE PRESETS
  // ---------------------------------------------------------------------------
  Widget _buildHeaderControls(AppSemanticColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date Presets
        Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderOnHero),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _presetPill('All Time', DatePreset.all),
                _presetPill('Today', DatePreset.today),
                _presetPill('This Week', DatePreset.thisWeek),
                _presetPill('This Month', DatePreset.thisMonth),
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
  // SALES BY CATEGORY
  // ---------------------------------------------------------------------------
  Widget _buildCategorySalesCard(
      AppSemanticColors colors, List<Order> orders, double totalGross) {
    final predefined = [
      (
        name: 'Fresh Fish',
        style: CategoryColors.freshFish,
      ),
      (
        name: 'Dried Fish',
        style: CategoryColors.driedFish,
      ),
      (
        name: 'Meat',
        style: CategoryColors.meat,
      ),
      (
        name: 'Chicken',
        style: CategoryColors.chicken,
      ),
      (
        name: 'Fruits',
        style: CategoryColors.fruits,
      ),
      (
        name: 'Vegetables',
        style: CategoryColors.vegetables,
      ),
      (
        name: 'Maritatas',
        style: CategoryColors.maritatas,
      ),
      (
        name: 'Sari-Sari',
        style: CategoryColors.sariSari,
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
    final totalBaseline = computedTotal > 0 ? computedTotal : 1.0;

    // Build sorted category list (descending by revenue/percentage)
    final categoryList = predefined.map((cat) {
      final sales = salesMap[cat.name.toLowerCase()] ?? 0.0;
      return (
        name: cat.name,
        style: cat.style,
        sales: sales,
      );
    }).toList()
      ..sort((a, b) => b.sales.compareTo(a.sales));

    final maxCategorySales = categoryList.fold<double>(
        0.0, (max, item) => math.max(max, item.sales));

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
          ...categoryList.map((cat) {
            final pctOfTotal = (cat.sales / totalBaseline).clamp(0.0, 1.0);
            final barWidth = maxCategorySales > 0
                ? (cat.sales / maxCategorySales).clamp(0.0, 1.0)
                : 0.0;
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
                        _fmtMoney(cat.sales),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pctOfTotal * 100).round()}%',
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
                      value: barWidth,
                      minHeight: 6,
                      backgroundColor: colors.hoverSurface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cat.style.accent),
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
  Widget _buildTopSellersCard(
    AppSemanticColors colors,
    List<Order> orders,
  ) {
    // Dynamic calculation from current filtered orders
    final vendorMap = <String, (int count, double revenue)>{};
    for (final o in orders) {
      final current = vendorMap[o.vendorName] ?? (0, 0.0);
      vendorMap[o.vendorName] = (current.$1 + 1, current.$2 + o.total);
    }
    final sortedVendors = vendorMap.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    final count = sortedVendors.length.clamp(0, 4);

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
                      'Leading stall holders for ${_dateRangeLabel()}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STALL HOLDER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'REVENUE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
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
              final entry = sortedVendors[index];
              final sellerName = entry.key;
              final orderSubtext = '${entry.value.$1} orders';
              final revenueText = _fmtMoney(entry.value.$2);

              final isSelected = vendor == sellerName;

              return Padding(
                padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
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
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                        SizedBox(
                          width: 22,
                          child: Text(
                            '#${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: index == 0
                                  ? const Color(0xFF10B981)
                                  : colors.mutedText,
                            ),
                          ),
                        ),
                        AvatarCircle(name: sellerName, size: 32),
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderSubtext,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          revenueText,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
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
    required List<Order> allOrders,
    required List<Order> exportOrders,
    required SalesSummary summary,
    required List<Order> filteredOrders,
    required List<MapEntry<String, List<Order>>> visibleStallHolderGroups,
    required int totalStallHolders,
    required List<String> categories,
    required int safePage,
    required int totalPages,
  }) {
    return DataPanel(
      title: 'Recent Transactions',
      subtitle:
          'Showing $totalStallHolders approved stall holders and ${filteredOrders.length} matching sales records',
      child: Column(
        children: [
          // Search & Filter Toolbar
          Toolbar(
            controller: search,
            searchHint: 'Search order ID, transaction, or stall holder...',
            onChanged: (_) => setState(() => page = 0),
            onClear: _clearFilters,
            trailing: [
              FilterButton(
                label: selectedPreset == DatePreset.custom
                    ? _dateRangeLabel()
                    : 'Custom Date',
                icon: Icons.calendar_today_outlined,
                onTap: _pickCustomDateRange,
              ),
              ExportButton(
                onExportPdf: () => _exportSales(
                  allOrders: allOrders,
                  filteredOrders: exportOrders,
                  summary: summary,
                  format: ExportFormat.pdf,
                ),
                onExportExcel: () => _exportSales(
                  allOrders: allOrders,
                  filteredOrders: exportOrders,
                  summary: summary,
                  format: ExportFormat.excel,
                ),
              ),
              FilterButton(
                label: 'Filters',
                icon: Icons.tune_rounded,
                isActive: true,
                onTap: () => _showFilters(categories),
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
              if (category != 'All Categories')
                _chip(category,
                    () => setState(() => category = 'All Categories')),
              if (vendor != 'All Stall Holders')
                _chip(
                    vendor, () => setState(() => vendor = 'All Stall Holders')),
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

          if (visibleStallHolderGroups.isEmpty)
            Padding(
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
            )
          else
            ..._stallGroups(visibleStallHolderGroups, colors),

          if (totalStallHolders > 0)
            PaginationBar(
              total: totalStallHolders,
              start: safePage * 10 + 1,
              end: ((safePage + 1) * 10).clamp(0, totalStallHolders),
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

  List<MapEntry<String, List<Order>>> _groupOrdersByStallHolder(
    List<Order> orders,
    List<Vendor> approvedStallHolders,
    String query,
  ) {
    final groups = <String, List<Order>>{
      for (final stallHolder in approvedStallHolders) stallHolder.name: [],
    };
    final accountNames = <String, String>{
      for (final stallHolder in approvedStallHolders)
        stallHolder.name.trim().toLowerCase(): stallHolder.name,
    };
    final accountIds = <String, String>{
      for (final stallHolder in approvedStallHolders)
        stallHolder.id: stallHolder.name,
    };
    String? accountNameFor(Order order) => accountIds[order.transactionId] ??
        accountNames[order.vendorName.trim().toLowerCase()];

    for (final order in orders) {
      final accountName = accountNameFor(order);
      if (accountName != null) {
        groups[accountName]!.add(order);
      }
    }
    if (query.isNotEmpty) {
      groups.removeWhere(
          (name, items) => items.isEmpty && !name.toLowerCase().contains(query));
    }

    final orderedNames = <String>[];
    for (final order in orders) {
      final accountName = accountNameFor(order);
      if (accountName != null && !orderedNames.contains(accountName)) {
        orderedNames.add(accountName);
      }
    }
    orderedNames.addAll(groups.keys.where((name) => !orderedNames.contains(name)));
    return [for (final name in orderedNames) MapEntry(name, groups[name]!)];
  }

  List<Widget> _stallGroups(
      List<MapEntry<String, List<Order>>> groups, AppSemanticColors colors) {
    return [
      for (final entry in groups) ...[
        _StallTransactionGroup(
          stallHolderName: entry.key,
          orders: entry.value,
          collapsed: !_expandedStallHolders.contains(entry.key),
          colors: colors,
          rowBuilder: (order) => _transactionRow(order, colors),
          onToggle: () => setState(() {
            if (!_expandedStallHolders.add(entry.key)) {
              _expandedStallHolders.remove(entry.key);
            }
          }),
        ),
        const SizedBox(height: 10),
      ],
    ];
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
          '${item.id} ${item.transactionId} ${item.vendorName} ${item.stallName}'
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
        _applyPreset(DatePreset.all);
      });

  // ---------------------------------------------------------------------------
  // FILTERS DIALOG
  // ---------------------------------------------------------------------------
  Future<void> _showFilters(List<String> categories) async {
    var nextCategory = category;
    var nextOrderStatus = orderStatus;
    var nextPaymentStatus = paymentStatus;
    var nextPaymentMethod = paymentMethod;
    final minController = TextEditingController(text: minimum.text);
    final maxController = TextEditingController(text: maximum.text);
    String? error;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Filters',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdown('Categories', nextCategory, categories,
                        (value) => setDialogState(() => nextCategory = value!)),
                    _dropdown(
                      'Order status',
                      nextOrderStatus == null
                          ? 'All statuses'
                          : enumLabel(nextOrderStatus!),
                      ['All statuses', ...OrderStatus.values.map(enumLabel)],
                      (value) => setDialogState(() => nextOrderStatus = value ==
                              'All statuses'
                          ? null
                          : OrderStatus.values
                              .firstWhere((item) => enumLabel(item) == value)),
                    ),
                    _dropdown(
                      'Payment status',
                      nextPaymentStatus == null
                          ? 'All statuses'
                          : enumLabel(nextPaymentStatus!),
                      ['All statuses', ...PaymentStatus.values.map(enumLabel)],
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
                    setDialogState(
                        () => error = 'Amounts must be valid numbers.');
                    return;
                  }
                  if (min != null && max != null && max < min) {
                    setDialogState(
                        () => error = 'Maximum cannot be lower than minimum.');
                    return;
                  }
                  setState(() {
                    category = nextCategory;
                    orderStatus = nextOrderStatus;
                    paymentStatus = nextPaymentStatus;
                    paymentMethod = nextPaymentMethod;
                    minimum.text = minController.text;
                    maximum.text = maxController.text;
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
  Future<void> _exportSales({
    required List<Order> allOrders,
    required List<Order> filteredOrders,
    required SalesSummary summary,
    required ExportFormat format,
  }) async {
    final filterParts = <String>[];
    filterParts.add('Period: ${_dateRangeLabel()}');
    if (category != 'All Categories') filterParts.add('Category: $category');
    if (vendor != 'All Stall Holders') filterParts.add('Stall: $vendor');
    if (orderStatus != null) {
      filterParts.add('Order Status: ${enumLabel(orderStatus!)}');
    }
    if (paymentStatus != null) {
      filterParts.add('Payment Status: ${enumLabel(paymentStatus!)}');
    }
    if (search.text.trim().isNotEmpty) {
      filterParts.add('Search: "${search.text.trim()}"');
    }
    final activeFilters = filterParts.join(' • ');

    final doc = SalesExportData.build(
      allOrders: allOrders,
      filteredOrders: filteredOrders,
      summary: summary,
      activeFilters: activeFilters,
    );

    await AdminExportService.export(
      context: context,
      ref: ref,
      doc: doc,
      format: format,
    );
  }
}

class _StallTransactionGroup extends StatelessWidget {
  const _StallTransactionGroup({
    required this.stallHolderName,
    required this.orders,
    required this.collapsed,
    required this.colors,
    required this.rowBuilder,
    required this.onToggle,
  });

  final String stallHolderName;
  final List<Order> orders;
  final bool collapsed;
  final AppSemanticColors colors;
  final DataRow Function(Order order) rowBuilder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<double>(0, (sum, order) => sum + order.total);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: collapsed ? const Radius.circular(10) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  AvatarCircle(name: stallHolderName, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stallHolderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
                          style: TextStyle(fontSize: 10.5, color: colors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Sales: ${_fmtMoney(total)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      Text(
                        collapsed ? 'Expand' : 'Collapse',
                        style: TextStyle(fontSize: 10, color: colors.mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed) ...[
            Divider(height: 1, color: colors.subtleBorder),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStatePropertyAll(colors.tableHeader),
                    headingTextStyle: GoogleFonts.inter(
                      color: colors.secondaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    dataTextStyle:
                        TextStyle(fontSize: 12, color: colors.primaryText),
                    horizontalMargin: 14,
                    columnSpacing: 28,
                    headingRowHeight: 42,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(label: Text('ORDER ID')),
                      DataColumn(label: Text('DATE & TIME')),
                      DataColumn(label: Text('TOTAL')),
                      DataColumn(label: Text('PAYMENT')),
                      DataColumn(label: Text('ORDER STATUS')),
                      DataColumn(label: Text('ACTION')),
                    ],
                    rows: orders.map(rowBuilder).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
          maxWidth: 1040,
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
                        Text(
                          'Transaction Details',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('MMMM d, yyyy • h:mm a')
                              .format(order.placedAt),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
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
                        _financialRow(
                            'Subtotal', _fmtMoney(order.subtotal), colors),
                        _financialRow('Discount',
                            '-${_fmtMoney(order.discounts)}', colors,
                            valueColor: const Color(0xFFEF4444)),
                        _financialRow('Delivery Fee',
                            _fmtMoney(order.deliveryFee), colors),
                        _financialRow('Platform Fee',
                            _fmtMoney(order.platformFee), colors),
                        _financialRow('Refund',
                            '-${_fmtMoney(order.refundAmount)}', colors,
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

                  // Payment details
                  _sectionHeader('PAYMENT DETAILS', colors),
                  _card(
                    colors,
                    child: Column(
                      children: [
                        _infoRow(
                          'Payment Method',
                          enumLabel(order.paymentMethod),
                          colors,
                        ),
                        _infoRow(
                          'Amount Paid',
                          _fmtMoney(order.paymentStatus == PaymentStatus.paid
                              ? order.total
                              : 0),
                          colors,
                        ),
                        _infoRow(
                          'Transaction Reference',
                          order.transactionId,
                          colors,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Status',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.secondaryText)),
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
                                      fontSize: 12,
                                      color: colors.secondaryText)),
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

    final cat = category.toLowerCase().trim();

    if (cat.contains('dried')) {
      // Dried fish (daing outline with split center)
      final body = Path()
        ..moveTo(21.0, 12.0)
        ..lineTo(16.0, 6.5)
        ..lineTo(7.0, 8.0)
        ..lineTo(2.5, 6.0)
        ..lineTo(4.5, 12.0)
        ..lineTo(2.5, 18.0)
        ..lineTo(7.0, 16.0)
        ..lineTo(16.0, 17.5)
        ..close();
      canvas.drawPath(body, stroke);
      final centerLine = Path()
        ..moveTo(5.0, 12.0)
        ..lineTo(19.0, 12.0);
      canvas.drawPath(centerLine, stroke..strokeWidth = 1.2);
    } else if (cat.contains('chicken') || cat.contains('poultry')) {
      // Chicken drumstick
      final drumstick = Path()
        ..moveTo(7.0, 17.0)
        ..lineTo(5.0, 19.0)
        ..quadraticBezierTo(3.5, 20.5, 5.0, 21.0)
        ..quadraticBezierTo(6.0, 21.0, 7.0, 19.0)
        ..lineTo(9.0, 17.0)
        ..cubicTo(14.0, 17.5, 21.0, 15.0, 21.0, 9.0)
        ..cubicTo(21.0, 4.0, 15.0, 3.5, 11.0, 7.0)
        ..cubicTo(7.5, 10.5, 7.0, 14.0, 7.0, 17.0)
        ..close();
      canvas.drawPath(drumstick, stroke);
      canvas.drawCircle(
          const Offset(4.5, 19.5), 1.5, stroke..strokeWidth = 1.2);
    } else if (cat.contains('fish') || cat.contains('seafood')) {
      // Fresh fish outline
      final body = Path()
        ..moveTo(21.0, 12.0)
        ..cubicTo(16.5, 6.0, 10.5, 6.5, 5.5, 11.0)
        ..lineTo(2.5, 7.0)
        ..quadraticBezierTo(4.0, 12.0, 2.5, 17.0)
        ..lineTo(5.5, 13.0)
        ..cubicTo(10.5, 17.5, 16.5, 18.0, 21.0, 12.0)
        ..close();
      canvas.drawPath(body, stroke);
      canvas.drawCircle(const Offset(17.5, 11.0), 1.1, fill);
      final gill = Path()
        ..moveTo(14.5, 9.5)
        ..quadraticBezierTo(13.2, 12.0, 14.5, 14.5);
      canvas.drawPath(gill, stroke);
    } else if (cat.contains('meat') ||
        cat.contains('pork') ||
        cat.contains('beef')) {
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
      canvas.drawCircle(const Offset(8.5, 12.5), 2.0, stroke);
      canvas.drawCircle(const Offset(8.5, 12.5), 0.8, fill);
      final marble = Path()
        ..moveTo(13.0, 8.5)
        ..quadraticBezierTo(16.5, 11.5, 15.0, 15.5);
      canvas.drawPath(marble, stroke..strokeWidth = 1.3);
    } else if (cat.contains('fruit')) {
      // Fresh natural apple / fruit
      final fruit = Path()
        ..moveTo(12.0, 7.5)
        ..cubicTo(9.0, 5.5, 4.0, 6.5, 4.0, 12.0)
        ..cubicTo(4.0, 17.0, 8.0, 20.5, 12.0, 20.5)
        ..cubicTo(16.0, 20.5, 20.0, 17.0, 20.0, 12.0)
        ..cubicTo(20.0, 6.5, 15.0, 5.5, 12.0, 7.5)
        ..close();
      canvas.drawPath(fruit, stroke);
      final stem = Path()
        ..moveTo(12.0, 7.5)
        ..quadraticBezierTo(12.5, 4.0, 14.5, 3.0);
      canvas.drawPath(stem, stroke);
      final leaf = Path()
        ..moveTo(12.5, 5.5)
        ..quadraticBezierTo(9.0, 3.5, 8.0, 5.5)
        ..quadraticBezierTo(10.0, 7.0, 12.5, 5.5);
      canvas.drawPath(leaf, fill);
    } else if (cat.contains('veg') || cat.contains('produce')) {
      // Carrot with greens
      final carrot = Path()
        ..moveTo(8.5, 8.5)
        ..quadraticBezierTo(12.0, 7.8, 15.5, 8.5)
        ..quadraticBezierTo(14.0, 14.5, 12.5, 21.0)
        ..quadraticBezierTo(12.0, 21.8, 11.5, 21.0)
        ..quadraticBezierTo(10.0, 14.5, 8.5, 8.5)
        ..close();
      canvas.drawPath(carrot, stroke);
      final ridge1 = Path()
        ..moveTo(9.8, 12.0)
        ..lineTo(12.5, 12.0);
      final ridge2 = Path()
        ..moveTo(11.0, 16.0)
        ..lineTo(13.5, 16.0);
      canvas.drawPath(ridge1, stroke..strokeWidth = 1.3);
      canvas.drawPath(ridge2, stroke..strokeWidth = 1.3);
      final greens = Path()
        ..moveTo(12.0, 8.0)
        ..quadraticBezierTo(12.0, 4.5, 12.0, 3.0)
        ..moveTo(11.0, 8.0)
        ..quadraticBezierTo(9.0, 5.0, 7.5, 4.0)
        ..moveTo(13.0, 8.0)
        ..quadraticBezierTo(15.0, 5.0, 16.5, 4.0);
      canvas.drawPath(greens, stroke..strokeWidth = 1.5);
    } else if (cat.contains('maritata')) {
      // Maritatas (Filipino market sweet delicacy / confection)
      final pastry = Path()
        ..moveTo(5.0, 14.0)
        ..cubicTo(5.0, 8.0, 19.0, 8.0, 19.0, 14.0)
        ..lineTo(19.0, 18.0)
        ..cubicTo(19.0, 20.0, 5.0, 20.0, 5.0, 18.0)
        ..close();
      canvas.drawPath(pastry, stroke);
      final topping = Path()
        ..moveTo(8.0, 11.0)
        ..quadraticBezierTo(12.0, 8.5, 16.0, 11.0);
      canvas.drawPath(topping, stroke..strokeWidth = 1.3);
      canvas.drawCircle(const Offset(12.0, 5.5), 1.8, fill);
    } else if (cat.contains('sari')) {
      // Sari-Sari storefront shop / basket
      final basket = Path()
        ..moveTo(4.0, 9.0)
        ..lineTo(20.0, 9.0)
        ..lineTo(18.0, 20.0)
        ..lineTo(6.0, 20.0)
        ..close();
      canvas.drawPath(basket, stroke);
      final handle = Path()
        ..moveTo(7.0, 9.0)
        ..cubicTo(7.0, 4.0, 17.0, 4.0, 17.0, 9.0);
      canvas.drawPath(handle, stroke);
      final weave = Path()
        ..moveTo(12.0, 9.0)
        ..lineTo(12.0, 20.0);
      canvas.drawPath(weave, stroke..strokeWidth = 1.2);
    } else {
      // Default fallback item
      canvas.drawCircle(const Offset(12.0, 12.0), 7.0, stroke);
      canvas.drawCircle(const Offset(12.0, 12.0), 2.0, fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter oldDelegate) =>
      oldDelegate.category != category || oldDelegate.color != color;
}

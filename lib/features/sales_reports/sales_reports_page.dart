import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_exporter.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';

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
  String category = 'All Categories';
  String vendor = 'All Stall Holders';
  OrderStatus? orderStatus;
  PaymentStatus? paymentStatus;
  PaymentMethod? paymentMethod;
  DateTime? startDate;
  DateTime? endDate;
  String sort = 'Newest first';
  int page = 0;
  bool exporting = false;

  @override
  void dispose() {
    search.dispose();
    minimum.dispose();
    maximum.dispose();
    tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final categories = <String>{
      'All Categories',
      ...data.orders.expand((item) => item.items.map((line) => line.category)),
    }.toList();
    final vendors = <String>{
      'All Stall Holders',
      ...data.orders.map((item) => item.vendorName),
    }.toList();
    final values = _filtered(data.orders);
    final summary = SalesSummary.fromOrders(values);
    final totalPages = (values.length / 10).ceil();
    final safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final visible = values.skip(safePage * 10).take(10).toList();
    return Column(
      children: [
        PageHeader(
          title: 'Sales Reports',
          subtitle:
              'Review marketplace orders, payments, refunds, and net revenue.',
          metrics: [
            MetricCardData(
                value: '${summary.totalOrders}',
                label: 'Total Orders',
                icon: Icons.receipt_long_outlined,
                accent: const Color(0xFF3B82F6)),
            MetricCardData(
                value: '${summary.completedOrders}',
                label: 'Completed Orders',
                icon: Icons.check_circle_outline,
                accent: const Color(0xFF10B981)),
            MetricCardData(
                value: '${summary.pendingOrders}',
                label: 'Pending Orders',
                icon: Icons.schedule_outlined,
                accent: const Color(0xFFF59E0B)),
            MetricCardData(
                value: money(summary.grossSales),
                label: 'Gross Sales',
                icon: Icons.payments_outlined,
                accent: const Color(0xFF8B5CF6)),
            MetricCardData(
                value: money(summary.netRevenue),
                label: 'Net Revenue',
                icon: Icons.account_balance_outlined,
                accent: const Color(0xFF14B8A6)),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 22, 30, 26),
            child: DataPanel(
              title: 'Marketplace Sales',
              subtitle: _periodLabel(),
              headerAction: Wrap(
                spacing: 8,
                children: [
                  FilterButton(
                      label: 'Filters',
                      icon: Icons.tune_rounded,
                      onTap: () => _showFilters(categories, vendors)),
                  FilterMenuButton(
                    label: 'Sort',
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
                  FilterButton(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      onTap:
                          exporting ? null : () => _exportPdf(values, summary)),
                  FilterButton(
                      label: 'Excel',
                      icon: Icons.table_chart_outlined,
                      onTap: exporting
                          ? null
                          : () => _exportExcel(values, summary)),
                ],
              ),
              child: Expanded(
                child: Column(
                  children: [
                    Toolbar(
                      controller: search,
                      searchHint:
                          'Search order, transaction, customer, stall holder, or stall...',
                      onChanged: (_) => setState(() => page = 0),
                      onClear: _clearFilters,
                      trailing: [
                        if (category != 'All Categories')
                          _chip(
                              category,
                              () =>
                                  setState(() => category = 'All Categories')),
                        if (vendor != 'All Stall Holders')
                          _chip(
                              vendor,
                              () =>
                                  setState(() => vendor = 'All Stall Holders')),
                        if (startDate != null || endDate != null)
                          _chip(
                              'Date range',
                              () => setState(() {
                                    startDate = null;
                                    endDate = null;
                                  })),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 2050,
                          child: ScrollableDataTable(
                            columns: const [
                              DataColumn(label: Text('ORDER ID')),
                              DataColumn(label: Text('TRANSACTION')),
                              DataColumn(label: Text('DATE / TIME')),
                              DataColumn(label: Text('CUSTOMER')),
                              DataColumn(label: Text('STALL HOLDER')),
                              DataColumn(label: Text('STALL')),
                              DataColumn(label: Text('ITEMS')),
                              DataColumn(label: Text('CATEGORY')),
                              DataColumn(label: Text('QTY')),
                              DataColumn(label: Text('SUBTOTAL')),
                              DataColumn(label: Text('DISCOUNTS')),
                              DataColumn(label: Text('DELIVERY')),
                              DataColumn(label: Text('PLATFORM FEE')),
                              DataColumn(label: Text('REFUND')),
                              DataColumn(label: Text('TOTAL')),
                              DataColumn(label: Text('PAYMENT')),
                              DataColumn(label: Text('PAYMENT STATUS')),
                              DataColumn(label: Text('ORDER STATUS')),
                            ],
                            rows: visible.map(_row).toList(),
                            verticalController: tableController,
                            minWidth: 2050,
                            rowHeight: 60,
                            emptyState: const EmptyState(
                                message:
                                    'No sales found. Try changing the search or filters.'),
                          ),
                        ),
                      ),
                    ),
                    if (values.isNotEmpty)
                      PaginationBar(
                        total: values.length,
                        start: safePage * 10 + 1,
                        end: ((safePage + 1) * 10).clamp(0, values.length),
                        page: safePage,
                        pageCount: totalPages,
                        onPageChanged: (value) => setState(() => page = value),
                        showSummary: search.text.trim().isNotEmpty,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Order> _filtered(List<Order> source) {
    final query = search.text.trim().toLowerCase();
    final min = double.tryParse(minimum.text.trim());
    final max = double.tryParse(maximum.text.trim());
    final list = source.where((item) {
      final searchable =
          '${item.id} ${item.transactionId} ${item.customerName} ${item.vendorName} ${item.stallName}'
              .toLowerCase();
      final dateMatches = (startDate == null ||
              !item.placedAt.isBefore(startDate!)) &&
          (endDate == null ||
              item.placedAt.isBefore(endDate!.add(const Duration(days: 1))));
      final categoryMatches = category == 'All Categories' ||
          item.items.any((line) => line.category == category);
      return (query.isEmpty || searchable.contains(query)) &&
          (vendor == 'All Stall Holders' || item.vendorName == vendor) &&
          (orderStatus == null || item.status == orderStatus) &&
          (paymentStatus == null || item.paymentStatus == paymentStatus) &&
          (paymentMethod == null || item.paymentMethod == paymentMethod) &&
          categoryMatches &&
          dateMatches &&
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

  DataRow _row(Order item) => DataRow(cells: [
        DataCell(
            Text(item.id, style: const TextStyle(fontWeight: FontWeight.w700))),
        DataCell(Text(item.transactionId)),
        DataCell(Text(longDate.format(item.placedAt))),
        DataCell(Text(item.customerName)),
        DataCell(Text(item.vendorName)),
        DataCell(Text(item.stallName)),
        DataCell(
            Text(item.itemNames, maxLines: 2, overflow: TextOverflow.ellipsis)),
        DataCell(StatusBadge(label: item.categories, kind: BadgeKind.info)),
        DataCell(Text('${item.quantity}')),
        DataCell(Text(money(item.subtotal))),
        DataCell(Text(money(item.discounts))),
        DataCell(Text(money(item.deliveryFee))),
        DataCell(Text(money(item.platformFee))),
        DataCell(Text(money(item.refundAmount))),
        DataCell(Text(money(item.total),
            style: const TextStyle(fontWeight: FontWeight.w800))),
        DataCell(Text(enumLabel(item.paymentMethod))),
        DataCell(StatusBadge(
            label: enumLabel(item.paymentStatus),
            kind: item.paymentStatus == PaymentStatus.paid
                ? BadgeKind.success
                : BadgeKind.info)),
        DataCell(StatusBadge(
            label: enumLabel(item.status),
            kind: item.status == OrderStatus.completed
                ? BadgeKind.success
                : item.status == OrderStatus.cancelled
                    ? BadgeKind.danger
                    : BadgeKind.info)),
      ]);

  Widget _chip(String label, VoidCallback onRemove) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 13),
        visualDensity: VisualDensity.compact,
      );

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
            title: const Text('Sales filters'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
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
                                    (item) => enumLabel(item) == value))),
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
                                    (item) => enumLabel(item) == value))),
                    _dropdown(
                        'Payment method',
                        nextPaymentMethod == null
                            ? 'All methods'
                            : enumLabel(nextPaymentMethod!),
                        ['All methods', ...PaymentMethod.values.map(enumLabel)],
                        (value) => setDialogState(() => nextPaymentMethod =
                            value == 'All methods'
                                ? null
                                : PaymentMethod.values.firstWhere(
                                    (item) => enumLabel(item) == value))),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Minimum amount'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Maximum amount')))
                    ]),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        children: [
                          'Today',
                          'Yesterday',
                          'Last 7 days',
                          'Last 30 days',
                          'This month',
                          'This year',
                        ]
                            .map(
                              (label) => ActionChip(
                                label: Text(
                                  label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () => setDialogState(() {
                                  final range = _quickRange(label);
                                  nextStart = range.$1;
                                  nextEnd = range.$2;
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDateRange:
                                    nextStart != null && nextEnd != null
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
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              nextStart == null
                                  ? 'Choose date range'
                                  : '${shortDate.format(nextStart!)} - ${shortDate.format(nextEnd!)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Clear dates',
                          onPressed: () => setDialogState(() {
                            nextStart = null;
                            nextEnd = null;
                          }),
                          icon: const Icon(Icons.clear_rounded),
                        ),
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: semanticColors(context).danger,
                            fontSize: 11,
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
                onPressed: () {
                  final min = double.tryParse(minController.text.trim());
                  final max = double.tryParse(maxController.text.trim());
                  final hasInvalidAmount =
                      minController.text.trim().isNotEmpty && min == null ||
                          maxController.text.trim().isNotEmpty && max == null;
                  if (hasInvalidAmount) {
                    setDialogState(
                      () => error = 'Amounts must be valid numbers.',
                    );
                    return;
                  }
                  if (min != null && max != null && max < min) {
                    setDialogState(
                      () => error =
                          'Maximum amount cannot be lower than minimum amount.',
                    );
                    return;
                  }
                  if (nextStart != null &&
                      nextEnd != null &&
                      nextEnd!.isBefore(nextStart!)) {
                    setDialogState(
                      () =>
                          error = 'End date cannot be earlier than start date.',
                    );
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
                    page = 0;
                  });
                  Navigator.pop(dialogContext);
                },
                child: const Text('Apply filters'),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: values.contains(value) ? value : values.first,
          decoration: InputDecoration(labelText: label),
          items: values
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  (DateTime, DateTime) _quickRange(String label) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (label) {
      'Today' => (today, today),
      'Yesterday' => (
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 1))
        ),
      'Last 7 days' => (today.subtract(const Duration(days: 6)), today),
      'Last 30 days' => (today.subtract(const Duration(days: 29)), today),
      'This month' => (DateTime(today.year, today.month), today),
      'This year' => (DateTime(today.year), today),
      _ => (today, today),
    };
  }

  void _clearFilters() => setState(() {
        search.clear();
        category = 'All Categories';
        vendor = 'All Stall Holders';
        orderStatus = null;
        paymentStatus = null;
        paymentMethod = null;
        startDate = null;
        endDate = null;
        minimum.clear();
        maximum.clear();
        sort = 'Newest first';
        page = 0;
      });

  String _periodLabel() => startDate == null
      ? 'All available order data'
      : '${shortDate.format(startDate!)} - ${shortDate.format(endDate ?? startDate!)}';

  Future<void> _exportPdf(List<Order> values, SalesSummary summary) async {
    setState(() => exporting = true);
    try {
      final lines = <String>[
        'Generated: ${longDate.format(DateTime.now())}',
        'Period: ${_periodLabel()}',
        'Orders: ${summary.totalOrders} | Completed: ${summary.completedOrders} | Pending: ${summary.pendingOrders}',
        'Gross sales: ${money(summary.grossSales)} | Refunds: ${money(summary.refunds)} | Net: ${money(summary.netRevenue)}',
        '',
        'Order | Date | Customer | Vendor | Category | Total | Payment | Status',
        ...values.map((item) =>
            '${item.id} | ${shortDate.format(item.placedAt)} | ${item.customerName} | ${item.vendorName} | ${item.categories} | ${money(item.total)} | ${enumLabel(item.paymentMethod)} | ${enumLabel(item.status)}'),
      ];
      downloadBytes(
          buildSimplePdf(title: 'PalengkeGo Sales Report', lines: lines),
          'palengkego_sales_report.pdf',
          'application/pdf');
      await ref.read(appDataProvider.notifier).recordAudit(
          action: AuditAction.exportPdf,
          targetEntityType: 'Sales Report',
          targetEntityId: 'sales-report',
          targetUserName: 'System',
          previousValue: '',
          newValue: '${values.length} records');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF report downloaded.')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _exportExcel(List<Order> values, SalesSummary summary) async {
    setState(() => exporting = true);
    try {
      final summaryRows = <List<Object?>>[
        ['PalengkeGo Sales Summary', ''],
        ['Reporting period', _periodLabel()],
        ['Generated by', ref.read(adminProfileProvider).name],
        ['Generated at', longDate.format(DateTime.now())],
        ['Total orders', summary.totalOrders],
        ['Completed orders', summary.completedOrders],
        ['Pending orders', summary.pendingOrders],
        ['Cancelled orders', summary.cancelledOrders],
        ['Refunded orders', summary.refundedOrders],
        ['Gross sales', summary.grossSales],
        ['Discounts', summary.discounts],
        ['Refunds', summary.refunds],
        ['Platform fees', summary.platformFees],
        ['Net revenue', summary.netRevenue],
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
          'Order Status'
        ],
        ...values.map((item) => item.toRow()),
      ];
      downloadBytes(
          buildSalesWorkbook(
              summaryRows: summaryRows, transactionRows: transactions),
          'palengkego_sales_report.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      await ref.read(appDataProvider.notifier).recordAudit(
          action: AuditAction.exportExcel,
          targetEntityType: 'Sales Report',
          targetEntityId: 'sales-report',
          targetUserName: 'System',
          previousValue: '',
          newValue: '${values.length} records');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel workbook downloaded.')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

String money(num value) => 'PHP ${value.toStringAsFixed(2)}';

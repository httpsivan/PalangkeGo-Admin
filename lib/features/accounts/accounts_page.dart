import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});
  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final search = TextEditingController();
  bool customers = false;
  String status = 'All Statuses';
  int page = 0;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    return Column(
      children: [
        PageHeader(
          title: 'Account Management',
          subtitle:
              'Oversee stall holders, customers, and active administrative reports.',
          tabs: _Tabs(
            selected: customers,
            onChanged: (value) => setState(() {
              customers = value;
              page = 0;
            }),
          ),
        ),
        Expanded(
          child: customers
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 30),
                  child: _customerPanel(data.customers),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 30),
                  child: _vendorPanel(data.vendors),
                ),
        ),
      ],
    );
  }

  List<Vendor> get filteredVendors => ref
      .read(appDataProvider)
      .vendors
      .where(
        (v) =>
            (search.text.isEmpty ||
                '${v.name} ${v.email} ${v.id} ${v.stallType}'
                    .toLowerCase()
                    .contains(search.text.toLowerCase())) &&
            (status == 'All Statuses' || enumLabel(v.status) == status),
      )
      .toList();
  List<Customer> get filteredCustomers => ref
      .read(appDataProvider)
      .customers
      .where(
        (v) =>
            (search.text.isEmpty ||
                '${v.name} ${v.email} ${v.id}'.toLowerCase().contains(
                  search.text.toLowerCase(),
                )) &&
            (status == 'All Statuses' || enumLabel(v.status) == status),
      )
      .toList();

  Widget _vendorPanel(List<Vendor> values) {
    final visible = values
        .where(
          (v) =>
              (search.text.isEmpty ||
                  '${v.name} ${v.email} ${v.id} ${v.stallType}'
                      .toLowerCase()
                      .contains(search.text.toLowerCase())) &&
              (status == 'All Statuses' || enumLabel(v.status) == status),
        )
        .toList();
    return DataPanel(
      title: 'Accounts',
      child: Column(
        children: [
          Toolbar(
            controller: search,
            onChanged: (_) => setState(() => page = 0),
            onClear: () => setState(() {
              search.clear();
              status = 'All Statuses';
            }),
            trailing: [
              _filter(context, status, [
                'All Statuses',
                'Active',
                'Offline',
                'Blocked',
              ], (v) => setState(() => status = v)),
              FilterButton(
                label: 'Export',
                icon: Icons.download_outlined,
                onTap: () => _export(visible, 'vendors'),
              ),
            ],
          ),
          _VendorTable(
            values: visible.skip(page * 10).take(10).toList(),
            onOpen: (vendor) => showAccountDrawer(context, ref, vendor),
          ),
          if (visible.isNotEmpty)
            PaginationBar(
              total: visible.length,
              start: page * 10 + 1,
              end: ((page + 1) * 10).clamp(0, visible.length),
              page: page,
              pageCount: (visible.length / 10).ceil(),
              onPageChanged: (value) => setState(() => page = value),
              showSummary: search.text.trim().isNotEmpty,
            )
          else
            const EmptyState(),
        ],
      ),
    );
  }

  Widget _customerPanel(List<Customer> values) {
    final visible = values
        .where(
          (v) =>
              (search.text.isEmpty ||
                  '${v.name} ${v.email} ${v.id}'.toLowerCase().contains(
                    search.text.toLowerCase(),
                  )) &&
              (status == 'All Statuses' || enumLabel(v.status) == status),
        )
        .toList();
    return DataPanel(
      title: 'Customer Directory',
      subtitle: 'Manage and monitor customer activity and status',
      child: Column(
        children: [
          Toolbar(
            controller: search,
            onChanged: (_) => setState(() => page = 0),
            onClear: () => setState(() {
              search.clear();
              status = 'All Statuses';
            }),
            searchHint: 'Search by name, email, or ID...',
            trailing: [
              _filter(context, status, [
                'All Statuses',
                'Active',
                'Blocked',
              ], (v) => setState(() => status = v)),
              FilterButton(
                label: 'Export',
                icon: Icons.download_outlined,
                onTap: () => _export(visible, 'customers'),
              ),
            ],
          ),
          _CustomerTable(values: visible.skip(page * 10).take(10).toList()),
          if (visible.isNotEmpty)
            PaginationBar(
              total: visible.length,
              start: page * 10 + 1,
              end: ((page + 1) * 10).clamp(0, visible.length),
              page: page,
              pageCount: (visible.length / 10).ceil(),
              onPageChanged: (value) => setState(() => page = value),
              showSummary: search.text.trim().isNotEmpty,
            )
          else
            const EmptyState(),
        ],
      ),
    );
  }

  Widget _filter(
    BuildContext context,
    String label,
    List<String> values,
    ValueChanged<String> onChanged,
  ) => FilterButton(
    label: label,
    onTap: () async {
      final value = await showMenu<String>(
        context: context,
        position: const RelativeRect.fromLTRB(350, 280, 0, 0),
        items: values
            .map((item) => PopupMenuItem(value: item, child: Text(item)))
            .toList(),
      );
      if (value != null) onChanged(value);
    },
  );

  void _export(List<dynamic> values, String name) {
    final csv = buildCsv([
      ['ID', 'Name', 'Email', 'Status'],
      ...values.map(
        (item) => [item.id, item.name, item.email, enumLabel(item.status)],
      ),
    ]);
    final anchor = html.AnchorElement(href: csvDataUri(csv))
      ..setAttribute('download', 'palengkego-$name.csv')
      ..click();
    anchor.remove();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV export prepared.')));
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});
  final bool selected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _tab(context, 'Vendors (Stall Holders)', !selected),
      const SizedBox(width: 8),
      _tab(context, 'Customers', selected),
    ],
  );
  Widget _tab(BuildContext context, String label, bool active) => Material(
    color: active ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: () => onChanged(label == 'Customers'),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? semanticColors(context).heroBackground
                : Colors.white.withOpacity(.78),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _VendorTable extends StatelessWidget {
  const _VendorTable({required this.values, required this.onOpen});
  final List<Vendor> values;
  final ValueChanged<Vendor> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (vendor) => DataRow(
            onSelectChanged: (_) => onOpen(vendor),
            cells: [
              DataCell(
                Row(
                  children: [
                    AvatarCircle(name: vendor.name, size: 32),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(vendor.email, style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(vendor.stallType)),
              DataCell(Text(shortDate.format(vendor.registeredAt))),
              DataCell(
                StatusBadge(
                  label: enumLabel(vendor.status),
                  kind: vendor.status == AccountStatus.active
                      ? BadgeKind.success
                      : vendor.status == AccountStatus.blocked
                      ? BadgeKind.danger
                      : BadgeKind.warning,
                ),
              ),
              DataCell(
                IconButton(
                  onPressed: () => onOpen(vendor),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                ),
              ),
            ],
          ),
        )
        .toList();
    const columns = [
      DataColumn(
        columnWidth: FlexColumnWidth(2.2),
        label: Text('TENANTS DETAILS'),
      ),
      DataColumn(
        columnWidth: FlexColumnWidth(1.25),
        label: Text('STALL TYPE'),
      ),
      DataColumn(
        columnWidth: FlexColumnWidth(1.25),
        label: Text('REGISTRATION'),
      ),
      DataColumn(
        columnWidth: FlexColumnWidth(1.35),
        label: Text('ACCOUNT STATUS'),
      ),
      DataColumn(
        columnWidth: FlexColumnWidth(.7),
        label: Text('ACTIONS'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget table({required List<DataRow> rows, double headingHeight = 0}) =>
            SizedBox(
              width: constraints.maxWidth,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStatePropertyAll(
                  semanticColors(context).tableHeader,
                ),
                headingRowHeight: headingHeight,
                dataRowMinHeight: 68,
                dataRowMaxHeight: 68,
                columnSpacing: 20,
                columns: columns,
                rows: rows,
              ),
            );

        return Column(
          children: [
            table(rows: const [], headingHeight: 48),
            SizedBox(
              height: 350,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: table(rows: rows),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({required this.values});
  final List<Customer> values;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (customer) => DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    AvatarCircle(name: customer.name, size: 32),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.email,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(shortDate.format(customer.registeredAt))),
              DataCell(
                Text(
                  '${customer.transactions}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataCell(
                StatusBadge(
                  label: enumLabel(customer.status),
                  kind: customer.status == AccountStatus.active
                      ? BadgeKind.success
                      : BadgeKind.danger,
                ),
              ),
              const DataCell(Icon(Icons.more_vert_rounded, size: 17)),
            ],
          ),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              semanticColors(context).tableHeader,
            ),
            columnSpacing: 20,
            columns: const [
              DataColumn(
                columnWidth: FlexColumnWidth(2.2),
                label: Text('CUSTOMER NAME'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.35),
                label: Text('REGISTRATION DATE'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1),
                label: Text('TRANSACTIONS'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.35),
                label: Text('ACCOUNT STATUS'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(.7),
                label: Text('ACTIONS'),
              ),
            ],
            rows: rows,
          ),
        ),
      ),
    );
  }
}

Future<void> showAccountDrawer(
  BuildContext context,
  WidgetRef ref,
  Vendor vendor,
) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close account details',
  barrierColor: semanticColors(context).overlayScrim,
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, animation, secondaryAnimation) => Align(
    alignment: Alignment.centerRight,
    child: _AccountDrawer(vendor: vendor),
  ),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
);

class _AccountDrawer extends ConsumerStatefulWidget {
  const _AccountDrawer({required this.vendor});
  final Vendor vendor;
  @override
  ConsumerState<_AccountDrawer> createState() => _AccountDrawerState();
}

class _AccountDrawerState extends ConsumerState<_AccountDrawer> {
  late AccountStatus current = widget.vendor.status;
  @override
  Widget build(BuildContext context) {
    final vendor = ref
        .watch(appDataProvider)
        .vendors
        .firstWhere(
          (item) => item.id == widget.vendor.id,
          orElse: () => widget.vendor,
        );
    final colors = semanticColors(context);
    return Material(
      color: colors.elevatedSurface,
      child: SafeArea(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width < 520
              ? MediaQuery.sizeOf(context).width
              : 410,
          height: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Account Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarCircle(name: vendor.name, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'ID: ${vendor.id}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  label: enumLabel(vendor.status),
                                  kind: vendor.status == AccountStatus.active
                                      ? BadgeKind.success
                                      : vendor.status == AccountStatus.blocked
                                      ? BadgeKind.danger
                                      : BadgeKind.warning,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _metric(
                              context,
                              'TOTAL ORDERS',
                              '${vendor.orders}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metric(
                              context,
                              'TOTAL TRANSACTIONS',
                              '₱${(vendor.transactions / 1000).toStringAsFixed(1)}k',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const SectionLabel('Contact Information'),
                      const SizedBox(height: 12),
                      _contact(context, 'Email Address', vendor.email),
                      _contact(context, 'Phone Number', vendor.phone),
                      _contact(context, 'Primary Residence', vendor.residence),
                      const SizedBox(height: 17),
                      const SectionLabel('Account Status'),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<AccountStatus>(
                        value: current,
                        items: AccountStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(enumLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => current = value);
                            ref
                                .read(appDataProvider.notifier)
                                .setVendorStatus(vendor.id, value);
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      const SectionLabel('Recent Activity'),
                      const SizedBox(height: 10),
                      _activity(
                        context,
                        'Renewed Stall Permit #44',
                        'Today at 11:42 AM',
                      ),
                      _activity(
                        context,
                        'Processed monthly maintenance fee',
                        'Yesterday at 4:15 PM',
                      ),
                      _activity(context, 'Updated profile', 'Jan 12, 2024'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: colors.dangerContainer.withOpacity(.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Violation History',
                              style: TextStyle(
                                color: colors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Minor: Stall Encroachment',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Stall extended beyond 2m limit. Warning issued on Nov 05, 2023.',
                              style: TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No major violations recorded in the last 24 months.',
                              style: TextStyle(
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: semanticColors(context).infoContainer.withOpacity(.45),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(fontSize: 8)),
      ],
    ),
  );
  Widget _contact(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 8.5)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => copyToClipboard(context, value),
          icon: const Icon(Icons.copy_rounded, size: 14),
        ),
      ],
    ),
  );
  Widget _activity(BuildContext context, String title, String time) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: semanticColors(context).success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(time, style: const TextStyle(fontSize: 9)),
          ],
        ),
      ],
    ),
  );
}

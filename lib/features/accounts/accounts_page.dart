import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final tableScrollController = ScrollController();
  bool customers = false;
  String status = 'All Statuses';
  String stallCategory = 'All Categories';
  int page = 0;

  @override
  void dispose() {
    search.dispose();
    tableScrollController.dispose();
    super.dispose();
  }

  void _resetTable() {
    setState(() => page = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && tableScrollController.hasClients) {
        tableScrollController.jumpTo(0);
      }
    });
  }

  void _goToPage(int value) {
    setState(() => page = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && tableScrollController.hasClients) {
        tableScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
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
            onChanged: (value) {
              customers = value;
              _resetTable();
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 26, 32, 30),
            child: customers
                ? _customerPanel(data.customers)
                : _vendorPanel(data.vendors),
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
            (search.text.trim().isEmpty ||
                '${v.name} ${v.email} ${v.id} ${v.stallType}'
                    .toLowerCase()
                    .contains(search.text.trim().toLowerCase())) &&
            (status == 'All Statuses' || enumLabel(v.status) == status) &&
            (stallCategory == 'All Categories' || v.stallType == stallCategory),
      )
      .toList();
  List<Customer> get filteredCustomers => ref
      .read(appDataProvider)
      .customers
      .where(
        (v) =>
            (search.text.trim().isEmpty ||
                '${v.name} ${v.email} ${v.id}'.toLowerCase().contains(
                      search.text.trim().toLowerCase(),
                    )) &&
            (status == 'All Statuses' || enumLabel(v.status) == status),
      )
      .toList();

  Widget _vendorPanel(List<Vendor> values) {
    final categories = <String>{
      'All Categories',
      ...values.map((vendor) => vendor.stallType),
    }.toList()
      ..sort();
    categories
      ..remove('All Categories')
      ..insert(0, 'All Categories');
    final visible = values
        .where(
          (v) =>
              (search.text.trim().isEmpty ||
                  '${v.name} ${v.email} ${v.id} ${v.stallType}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' || enumLabel(v.status) == status) &&
              (stallCategory == 'All Categories' ||
                  v.stallType == stallCategory),
        )
        .toList();
    final int totalPages = (visible.length / 10).ceil();
    final int safePage =
        totalPages == 0 ? 0 : page.clamp(0, totalPages - 1) as int;
    return DataPanel(
      title: 'Accounts',
      child: Expanded(
        child: Column(
          children: [
            Toolbar(
              controller: search,
              onChanged: (_) => _resetTable(),
              onClear: () {
                search.clear();
                status = 'All Statuses';
                stallCategory = 'All Categories';
                _resetTable();
              },
              trailing: [
                _filter(context, status, [
                  'All Statuses',
                  'Active',
                  'Offline',
                  'Suspended',
                  'Blocked',
                ], (v) {
                  status = v;
                  _resetTable();
                }),
                _filter(
                    context,
                    stallCategory == 'All Categories'
                        ? 'Stall Category'
                        : stallCategory,
                    categories, (value) {
                  stallCategory = value;
                  _resetTable();
                }),
                FilterButton(
                  label: 'Export',
                  icon: Icons.download_outlined,
                  onTap: () => _export(visible, 'vendors'),
                ),
              ],
            ),
            Expanded(
              child: _VendorTable(
                values: visible.skip(safePage * 10).take(10).toList(),
                verticalController: tableScrollController,
                onOpen: (vendor) =>
                    showAccountDialog(context, ref, vendor: vendor),
              ),
            ),
            if (visible.isNotEmpty)
              PaginationBar(
                total: visible.length,
                start: safePage * 10 + 1,
                end: ((safePage + 1) * 10).clamp(0, visible.length),
                page: safePage,
                pageCount: totalPages,
                onPageChanged: _goToPage,
                showSummary: search.text.trim().isNotEmpty,
              ),
          ],
        ),
      ),
    );
  }

  Widget _customerPanel(List<Customer> values) {
    final visible = values
        .where(
          (v) =>
              (search.text.trim().isEmpty ||
                  '${v.name} ${v.email} ${v.id}'.toLowerCase().contains(
                        search.text.trim().toLowerCase(),
                      )) &&
              (status == 'All Statuses' || enumLabel(v.status) == status),
        )
        .toList();
    final int totalPages = (visible.length / 10).ceil();
    final int safePage =
        totalPages == 0 ? 0 : page.clamp(0, totalPages - 1) as int;
    return DataPanel(
      title: 'Customer Directory',
      subtitle: 'Manage and monitor customer activity and status',
      child: Expanded(
        child: Column(
          children: [
            Toolbar(
              controller: search,
              onChanged: (_) => _resetTable(),
              onClear: () {
                search.clear();
                status = 'All Statuses';
                _resetTable();
              },
              searchHint: 'Search by name, email, or ID...',
              trailing: [
                _filter(context, status, [
                  'All Statuses',
                  'Active',
                  'Suspended',
                  'Blocked',
                ], (v) {
                  status = v;
                  _resetTable();
                }),
                FilterButton(
                  label: 'Export',
                  icon: Icons.download_outlined,
                  onTap: () => _export(visible, 'customers'),
                ),
              ],
            ),
            Expanded(
              child: _CustomerTable(
                values: visible.skip(safePage * 10).take(10).toList(),
                verticalController: tableScrollController,
                onOpen: (customer) => showAccountDialog(
                  context,
                  ref,
                  customer: customer,
                ),
              ),
            ),
            if (visible.isNotEmpty)
              PaginationBar(
                total: visible.length,
                start: safePage * 10 + 1,
                end: ((safePage + 1) * 10).clamp(0, visible.length),
                page: safePage,
                pageCount: totalPages,
                onPageChanged: _goToPage,
                showSummary: search.text.trim().isNotEmpty,
              ),
          ],
        ),
      ),
    );
  }

  Widget _filter(
    BuildContext context,
    String label,
    List<String> values,
    ValueChanged<String> onChanged,
  ) =>
      FilterButton(
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
        color: active
            ? semanticColors(context).activeNavigation
            : Colors.transparent,
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
                    : semanticColors(context).heroMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
}

class _VendorTable extends StatelessWidget {
  const _VendorTable({
    required this.values,
    required this.verticalController,
    required this.onOpen,
  });
  final List<Vendor> values;
  final ScrollController verticalController;
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
    return ScrollableDataTable(
      verticalController: verticalController,
      minWidth: 1100,
      columnSpacing: 20,
      columns: columns,
      rows: rows,
    );
  }
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({
    required this.values,
    required this.verticalController,
    required this.onOpen,
  });
  final List<Customer> values;
  final ScrollController verticalController;
  final ValueChanged<Customer> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (customer) => DataRow(
            onSelectChanged: (_) => onOpen(customer),
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
              DataCell(
                IconButton(
                  onPressed: () => onOpen(customer),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  tooltip: 'Open account details',
                ),
              ),
            ],
          ),
        )
        .toList();
    return ScrollableDataTable(
      verticalController: verticalController,
      minWidth: 1100,
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
    );
  }
}

Future<void> showAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  Vendor? vendor,
  Customer? customer,
}) {
  assert((vendor == null) != (customer == null));
  final account = vendor != null
      ? _AccountDetailsData.fromVendor(vendor)
      : _AccountDetailsData.fromCustomer(customer!);

  Future<void> save(AccountStatus status, String notes) {
    if (vendor != null) {
      return ref.read(appDataProvider.notifier).updateVendorAccount(
            vendor.id,
            status: status,
            administrativeNotes: notes,
          );
    }
    return ref.read(appDataProvider.notifier).updateCustomerAccount(
          customer!.id,
          status: status,
          administrativeNotes: notes,
        );
  }

  final dialogKey = GlobalKey<_AccountDetailsDialogState>();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Account details',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      final colors = semanticColors(context);
      return SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => dialogKey.currentState?.requestClose(),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: ColoredBox(
                    color: colors.overlayScrim,
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 820;
                final width = narrow ? constraints.maxWidth * .94 : 760.0;
                final height = constraints.maxHeight * (narrow ? .9 : .88);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: narrow ? 0 : 650,
                      maxWidth: 780,
                      maxHeight: height,
                    ),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: _AccountDetailsDialog(
                        key: dialogKey,
                        account: account,
                        onSave: save,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

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
    final vendor = ref.watch(appDataProvider).vendors.firstWhere(
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

class _AccountDetailsData {
  const _AccountDetailsData({
    required this.id,
    required this.name,
    required this.email,
    required this.stallType,
    required this.registeredAt,
    required this.status,
    required this.location,
    required this.orders,
    required this.transactions,
    required this.phone,
    required this.residence,
    required this.accountType,
    required this.administrativeNotes,
  });

  factory _AccountDetailsData.fromVendor(Vendor vendor) => _AccountDetailsData(
        id: vendor.id,
        name: vendor.name,
        email: vendor.email,
        stallType: vendor.stallType,
        registeredAt: vendor.registeredAt,
        status: vendor.status,
        location: vendor.location,
        orders: vendor.orders,
        transactions: vendor.transactions,
        phone: vendor.phone,
        residence: vendor.residence,
        accountType: 'Vendor / Stall Holder',
        administrativeNotes: vendor.administrativeNotes,
      );

  factory _AccountDetailsData.fromCustomer(Customer customer) =>
      _AccountDetailsData(
        id: customer.id,
        name: customer.name,
        email: customer.email,
        stallType: 'Customer Account',
        registeredAt: customer.registeredAt,
        status: customer.status,
        location: 'Customer account',
        orders: 0,
        transactions: customer.transactions.toDouble(),
        phone: 'Not provided',
        residence: 'Not provided',
        accountType: 'Customer',
        administrativeNotes: customer.administrativeNotes,
      );

  final String id;
  final String name;
  final String email;
  final String stallType;
  final DateTime registeredAt;
  final AccountStatus status;
  final String location;
  final int orders;
  final double transactions;
  final String phone;
  final String residence;
  final String accountType;
  final String administrativeNotes;
}

class _AccountDetailsDialog extends ConsumerStatefulWidget {
  const _AccountDetailsDialog({
    super.key,
    required this.account,
    required this.onSave,
  });

  final _AccountDetailsData account;
  final Future<void> Function(AccountStatus status, String notes) onSave;

  @override
  ConsumerState<_AccountDetailsDialog> createState() =>
      _AccountDetailsDialogState();
}

class _AccountDetailsDialogState extends ConsumerState<_AccountDetailsDialog> {
  late AccountStatus current = widget.account.status;
  late final TextEditingController notes = TextEditingController(
    text: widget.account.administrativeNotes,
  );
  bool saving = false;

  bool get dirty =>
      current != widget.account.status ||
      notes.text != widget.account.administrativeNotes;

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> requestClose() async {
    if (saving) return;
    if (!dirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Your account changes have not been saved. Close this window anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _selectStatus(AccountStatus? value) async {
    if (value == null || value == current) return;
    if (value == AccountStatus.blocked || value == AccountStatus.suspended) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            value == AccountStatus.blocked
                ? 'Block this account?'
                : 'Suspend this account?',
          ),
          content: Text(
            value == AccountStatus.blocked
                ? 'This user will no longer be able to access vendor services until the account is reactivated.'
                : 'This user will temporarily lose access to vendor services.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(value == AccountStatus.blocked
                  ? 'Confirm Block'
                  : 'Confirm Suspend'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => current = value);
  }

  Future<void> _save() async {
    if (!dirty || saving) return;
    setState(() => saving = true);
    try {
      await widget.onSave(current, notes.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account changes saved.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save account changes: $error')),
      );
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.escape): () => requestClose(),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: colors.elevatedSurface,
          elevation: 20,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summary(context),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              context,
                              '${widget.account.orders}',
                              'TOTAL ORDERS',
                              Icons.receipt_long_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              context,
                              '\u20B1${(widget.account.transactions / 1000).toStringAsFixed(1)}K',
                              'TOTAL TRANSACTIONS',
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 21),
                      _sectionTitle('CONTACT INFORMATION'),
                      const SizedBox(height: 10),
                      _contactRow(
                          context, 'Email Address', widget.account.email),
                      _contactRow(
                          context, 'Phone Number', widget.account.phone),
                      _contactRow(
                        context,
                        'Primary Residence',
                        widget.account.residence,
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('ACCOUNT STATUS'),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<AccountStatus>(
                        value: current,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items: AccountStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(enumLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: _selectStatus,
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('RECENT ACTIVITY'),
                      const SizedBox(height: 10),
                      _activity(context, 'Renewed Stall Permit #44',
                          'Today at 11:42 AM'),
                      _activity(context, 'Processed monthly maintenance fee',
                          'Yesterday at 4:15 PM'),
                      _activity(context, 'Updated profile', 'Jan 12, 2024'),
                      const SizedBox(height: 11),
                      _violationCard(context),
                      const SizedBox(height: 20),
                      _sectionTitle('ADMINISTRATIVE NOTES'),
                      const SizedBox(height: 9),
                      TextField(
                        controller: notes,
                        minLines: 4,
                        maxLines: 4,
                        maxLength: 500,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Add notes about this account...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 12, 13),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    'Account Details',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StatusBadge(
                    label: enumLabel(current),
                    kind: _badgeKind(current),
                  ),
                  Text(
                    'Account ID: ${widget.account.id}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: semanticColors(context).mutedText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: requestClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      );

  Widget _summary(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final profile = Row(
            children: [
              AvatarCircle(name: widget.account.name, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.account.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID: ${widget.account.id}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: semanticColors(context).mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.account.accountType,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: semanticColors(context).mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: enumLabel(current),
                      kind: _badgeKind(current),
                    ),
                  ],
                ),
              ),
            ],
          );
          final metadata = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.stallType,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.account.location,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: semanticColors(context).mutedText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registered ${shortDate.format(widget.account.registeredAt)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: semanticColors(context).mutedText,
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 540) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [profile, const SizedBox(height: 12), metadata],
            );
          }
          return Row(
            children: [
              Expanded(child: profile),
              const SizedBox(width: 22),
              SizedBox(width: 190, child: metadata),
            ],
          );
        },
      );

  Widget _statCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colors = semanticColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.infoContainer.withOpacity(.55),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.heroBackground),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final color = semanticColors(context).mutedText;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .25,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: color.withOpacity(.25))),
      ],
    );
  }

  Widget _contactRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: semanticColors(context).mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              onPressed: () => copyToClipboard(context, value),
              icon: const Icon(Icons.copy_rounded, size: 15),
            ),
          ],
        ),
      );

  Widget _activity(BuildContext context, String title, String time) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: semanticColors(context).success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: semanticColors(context).mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _violationCard(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.dangerContainer.withOpacity(.55),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Violation History',
            style: GoogleFonts.inter(
              color: colors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Minor: Stall Encroachment',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Stall extended beyond the 2m limit. Warning issued on Nov 05, 2023.',
            style: GoogleFonts.inter(fontSize: 10),
          ),
          const SizedBox(height: 7),
          Text(
            'No major violations recorded in the last 24 months.',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: colors.mutedText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 9, 22, 15),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Full profile view is not available yet.')),
                ),
                child: const Text('View Full Profile'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: dirty && !saving ? _save : null,
                child: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      );

  BadgeKind _badgeKind(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return BadgeKind.success;
      case AccountStatus.offline:
      case AccountStatus.suspended:
        return BadgeKind.warning;
      case AccountStatus.blocked:
        return BadgeKind.danger;
    }
  }
}

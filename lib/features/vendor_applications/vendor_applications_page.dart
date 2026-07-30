import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';
import 'verification_dialog.dart';

class VendorApplicationsPage extends ConsumerStatefulWidget {
  const VendorApplicationsPage({super.key});
  @override
  ConsumerState<VendorApplicationsPage> createState() =>
      _VendorApplicationsPageState();
}

class _VendorApplicationsPageState
    extends ConsumerState<VendorApplicationsPage> {
  static const _viewedApplicationsPreference = 'applications_viewed_new_badges';
  final search = TextEditingController();
  final tableScrollController = ScrollController();
  String status = 'All Statuses';
  String stallCategory = 'All Categories';
  int page = 0;

  Set<String> get _viewedApplicationIds =>
      ref
          .read(sharedPreferencesProvider)
          .getStringList(_viewedApplicationsPreference)
          ?.toSet() ??
      <String>{};

  void _markApplicationViewed(String applicationId) {
    final preferences = ref.read(sharedPreferencesProvider);
    final viewed = _viewedApplicationIds;
    if (!viewed.add(applicationId)) return;
    setState(() {});
    preferences.setStringList(
      _viewedApplicationsPreference,
      viewed.toList(),
    );
  }

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
    final categories = <String>{
      'All Categories',
      ...data.applications.map((item) => item.category),
    }.toList()
      ..sort();
    categories
      ..remove('All Categories')
      ..insert(0, 'All Categories');
    final values = data.applications
        .where(
          (item) =>
              (search.text.trim().isEmpty ||
                  '${item.id} ${item.applicant} ${item.stallName}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' ||
                  item.status.toString().split('.').last ==
                      status.toLowerCase().replaceAll(' ', '')) &&
              (stallCategory == 'All Categories' ||
                  item.category == stallCategory),
        )
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final newestApplicationId = _newestId(data.applications);
    final newApplicationId = _viewedApplicationIds.contains(
      newestApplicationId,
    )
        ? null
        : newestApplicationId;
    final int totalPages = (values.length / 10).ceil();
    final int safePage =
        totalPages == 0 ? 0 : page.clamp(0, totalPages - 1) as int;
    return Column(
      children: [
        PageHeader(
          title: 'Vendor Applications',
          subtitle:
              'Review and verify new stall holder applications before granting access to the marketplace.',
          metrics: [
            MetricCardData(
              value:
                  '${data.applications.where((item) => item.status == ApplicationStatus.reviewing).length}',
              label: 'Pending Application',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFFF59E0B),
            ),
            const MetricCardData(
              value: '128',
              label: 'Approved Application',
              icon: Icons.verified_outlined,
              accent: Color(0xFF10B981),
            ),
            const MetricCardData(
              value: '18',
              label: 'Rejected',
              icon: Icons.cancel_outlined,
              accent: Color(0xFFEF4444),
            ),
            const MetricCardData(
              value: '05',
              label: 'New Today',
              icon: Icons.today_outlined,
              accent: Color(0xFF3B82F6),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 30),
            child: DataPanel(
              title: 'Recent Applications',
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
                        _filter(status, [
                          'All Statuses',
                          'Verified',
                          'Reviewing',
                          'Invalid Docs',
                        ], (value) {
                          status = value;
                          _resetTable();
                        }),
                        _filter(
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
                          onTap: () => _export(values),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _ApplicationTable(
                        values: values.skip(safePage * 10).take(10).toList(),
                        newestId: newApplicationId,
                        verticalController: tableScrollController,
                        onOpen: (item) {
                          _markApplicationViewed(item.id);
                          showBlurredDialog(
                            context,
                            (context) => VerificationDialog.application(item),
                          );
                        },
                      ),
                    ),
                    if (values.isNotEmpty)
                      PaginationBar(
                        total: values.length,
                        start: safePage * 10 + 1,
                        end: ((safePage + 1) * 10).clamp(0, values.length),
                        page: safePage,
                        pageCount: totalPages,
                        onPageChanged: _goToPage,
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

  Widget _filter(
    String label,
    List<String> values,
    ValueChanged<String> onChanged,
  ) =>
      FilterMenuButton(
        label: label,
        values: values,
        onSelected: onChanged,
      );

  void _export(List<VendorApplication> values) {
    final csv = buildCsv([
      [
        'Application ID',
        'Applicant',
        'Stall Name',
        'Category',
        'Date Submitted',
        'KYC Status',
      ],
      ...values.map(
        (item) => [
          item.id,
          item.applicant,
          item.stallName,
          item.category,
          item.submittedAt.toIso8601String(),
          enumLabel(item.status),
        ],
      ),
    ]);
    downloadCsv(csv, 'palengkego-vendor-applications.csv');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor applications CSV downloaded.')),
    );
  }

  String? _newestId(List<VendorApplication> values) {
    if (values.isEmpty) return null;
    var newest = values.first;
    for (final item in values.skip(1)) {
      if (item.submittedAt.isAfter(newest.submittedAt)) newest = item;
    }
    return newest.id;
  }
}

class _ApplicationTable extends StatelessWidget {
  const _ApplicationTable({
    required this.values,
    required this.newestId,
    required this.verticalController,
    required this.onOpen,
  });
  final List<VendorApplication> values;
  final String? newestId;
  final ScrollController verticalController;
  final ValueChanged<VendorApplication> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (item) => DataRow(
            onSelectChanged: (_) => onOpen(item),
            cells: [
              DataCell(
                Text(
                  item.id,
                  style: TextStyle(
                    color: semanticColors(context).accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataCell(
                Wrap(
                  spacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AvatarCircle(name: item.applicant, size: 28),
                    Text(item.applicant),
                    if (item.id == newestId) const _NewApplicationIndicator(),
                  ],
                ),
              ),
              DataCell(Text(item.stallName)),
              DataCell(StatusBadge(label: item.category, kind: BadgeKind.info)),
              DataCell(
                Text('${item.submittedAt.month}/${item.submittedAt.day}/2023'),
              ),
              DataCell(
                ApplicationStatusBadge(status: item.status),
              ),
              DataCell(
                TextButton(
                  onPressed: () => onOpen(item),
                  child: const Text('Review'),
                ),
              ),
            ],
          ),
        )
        .toList();
    return ScrollableDataTable(
      verticalController: verticalController,
      minWidth: 1350,
      columnSpacing: 18,
      columns: const [
        DataColumn(
          columnWidth: FlexColumnWidth(1.15),
          label: Text('APPLICATION ID'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.35),
          label: Text('APPLICANT'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.5),
          label: Text('STALL NAME'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(.9),
          label: Text('CATEGORY'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.25),
          label: Text('DATE SUBMITTED'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.2),
          label: Text('KYC STATUS'),
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

class _NewApplicationIndicator extends StatelessWidget {
  const _NewApplicationIndicator();

  @override
  Widget build(BuildContext context) {
    final color = semanticColors(context).info;
    return Tooltip(
      message: 'New application',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.3),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

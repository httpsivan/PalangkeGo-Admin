import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final search = TextEditingController();
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
    final values = data.applications
        .where(
          (item) =>
              (search.text.isEmpty ||
                  '${item.id} ${item.applicant} ${item.stallName}'
                      .toLowerCase()
                      .contains(search.text.toLowerCase())) &&
              (status == 'All Statuses' ||
                  item.status.toString().split('.').last ==
                      status.toLowerCase().replaceAll(' ', '')),
        )
        .toList();
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
                        'Verified',
                        'Reviewing',
                        'Invalid Docs',
                      ], (value) => setState(() => status = value)),
                      FilterButton(label: 'Stall Category'),
                      FilterButton(
                        label: 'Export',
                        icon: Icons.download_outlined,
                        onTap: () => _export(values),
                      ),
                    ],
                  ),
                  _ApplicationTable(
                    values: values.skip(page * 10).take(10).toList(),
                    onOpen: (item) => showBlurredDialog(
                      context,
                      (context) => VerificationDialog.application(item),
                    ),
                  ),
                  if (values.isNotEmpty)
                    PaginationBar(
                      total: values.length,
                      start: page * 10 + 1,
                      end: ((page + 1) * 10).clamp(0, values.length),
                      page: page,
                      pageCount: (values.length / 10).ceil(),
                      onPageChanged: (value) => setState(() => page = value),
                    )
                  else
                    const EmptyState(),
                ],
              ),
            ),
          ),
        ),
      ],
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
        position: const RelativeRect.fromLTRB(350, 300, 0, 0),
        items: values
            .map((item) => PopupMenuItem(value: item, child: Text(item)))
            .toList(),
      );
      if (value != null) onChanged(value);
    },
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
}

class _ApplicationTable extends StatelessWidget {
  const _ApplicationTable({required this.values, required this.onOpen});
  final List<VendorApplication> values;
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
                    color: semanticColors(context).heroBackground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    AvatarCircle(name: item.applicant, size: 28),
                    const SizedBox(width: 7),
                    Text(item.applicant),
                  ],
                ),
              ),
              DataCell(Text(item.stallName)),
              DataCell(StatusBadge(label: item.category, kind: BadgeKind.info)),
              DataCell(
                Text('${item.submittedAt.month}/${item.submittedAt.day}/2023'),
              ),
              DataCell(
                StatusBadge(
                  label: item.status.toString().split('.').last,
                  kind: item.status == ApplicationStatus.verified
                      ? BadgeKind.success
                      : item.status == ApplicationStatus.reviewing
                      ? BadgeKind.info
                      : BadgeKind.danger,
                ),
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

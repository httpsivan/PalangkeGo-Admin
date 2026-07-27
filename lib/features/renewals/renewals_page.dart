import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';
import '../vendor_applications/verification_dialog.dart';

class RenewalsPage extends ConsumerStatefulWidget {
  const RenewalsPage({super.key});
  @override
  ConsumerState<RenewalsPage> createState() => _RenewalsPageState();
}

class _RenewalsPageState extends ConsumerState<RenewalsPage> {
  final search = TextEditingController();
  final tableScrollController = ScrollController();
  String status = 'All Statuses';
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
    final values = data.renewals
        .where(
          (v) =>
              (search.text.trim().isEmpty ||
                  '${v.id} ${v.applicant} ${v.stallName}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' || _status(v.status) == status),
        )
        .toList();
    final int totalPages = (values.length / 10).ceil();
    final int safePage =
        totalPages == 0 ? 0 : page.clamp(0, totalPages - 1) as int;
    final expiring = data.renewals.where((v) {
      final days = v.expiryDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 7;
    }).length;
    final expired = data.renewals
        .where((v) => v.expiryDate.isBefore(DateTime.now()))
        .length;
    return Column(
      children: [
        PageHeader(
          title: 'Renewal Management',
          subtitle:
              'Review and process renewal requests from existing stall holders.',
          metrics: [
            const MetricCardData(
              value: '42',
              label: 'Total Request',
              icon: Icons.assignment_outlined,
              accent: Color(0xFF10B981),
            ),
            const MetricCardData(
              value: '312',
              label: 'Approved Application',
              icon: Icons.verified_outlined,
              accent: Color(0xFF6B7280),
            ),
            MetricCardData(
              value: '$expiring',
              label: 'Expiring 7D',
              icon: Icons.alarm_outlined,
              accent: const Color(0xFFF59E0B),
            ),
            MetricCardData(
              value: '$expired',
              label: 'Expired',
              icon: Icons.event_busy_outlined,
              accent: const Color(0xFFEF4444),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 30),
            child: DataPanel(
              title: 'Renewal',
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
                      trailing: [
                        _filter(
                            context,
                            status,
                            [
                              'All Statuses',
                              'Approved',
                              'Reviewing',
                              'Expired',
                            ],
                            (v) {
                              status = v;
                              _resetTable();
                            }),
                        FilterButton(label: 'Stall Category'),
                        FilterButton(
                          label: 'Export',
                          icon: Icons.download_outlined,
                          onTap: () => _export(values),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _Table(
                        values: values.skip(safePage * 10).take(10).toList(),
                        verticalController: tableScrollController,
                        open: (v) => showBlurredDialog(
                          context,
                          (context) => VerificationDialog.renewal(v),
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
    BuildContext context,
    String label,
    List<String> values,
    ValueChanged<String> onChanged,
  ) =>
      FilterButton(
        label: label,
        onTap: () async {
          final v = await showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(350, 300, 0, 0),
            items: values
                .map((x) => PopupMenuItem(value: x, child: Text(x)))
                .toList(),
          );
          if (v != null) onChanged(v);
        },
      );

  void _export(List<RenewalRequest> values) {
    final csv = buildCsv([
      [
        'Application ID',
        'Applicant',
        'Stall Name',
        'Category',
        'Expiry Date',
        'KYC Status',
      ],
      ...values.map(
        (item) => [
          item.id,
          item.applicant,
          item.stallName,
          item.category,
          item.expiryDate.toIso8601String(),
          enumLabel(item.status),
        ],
      ),
    ]);
    downloadCsv(csv, 'palengkego-renewals.csv');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Renewals CSV downloaded.')),
    );
  }

  String _status(RenewalStatus value) => switch (value) {
        RenewalStatus.approved => 'Approved',
        RenewalStatus.reviewing => 'Reviewing',
        RenewalStatus.expired => 'Expired',
      };
}

class _Table extends StatelessWidget {
  const _Table({
    required this.values,
    required this.verticalController,
    required this.open,
  });
  final List<RenewalRequest> values;
  final ScrollController verticalController;
  final ValueChanged<RenewalRequest> open;
  @override
  Widget build(BuildContext context) {
    final rows = values.map((v) {
      final days = v.expiryDate.difference(DateTime.now()).inDays;
      return DataRow(
        onSelectChanged: (_) => open(v),
        cells: [
          DataCell(
            Text(
              v.id,
              style: TextStyle(
                color: semanticColors(context).heroBackground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                AvatarCircle(name: v.applicant, size: 28),
                const SizedBox(width: 7),
                Text(v.applicant),
              ],
            ),
          ),
          DataCell(Text(v.stallName)),
          DataCell(StatusBadge(label: v.category, kind: BadgeKind.info)),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(shortDate.format(v.expiryDate)),
                Text(
                  days < 0 ? 'Expired ${days.abs()}d ago' : '$days days left',
                  style: TextStyle(
                    fontSize: 9,
                    color: days < 0
                        ? semanticColors(context).danger
                        : semanticColors(context).warning,
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            StatusBadge(
              label: v.status.toString().split('.').last,
              kind: v.status == RenewalStatus.approved
                  ? BadgeKind.success
                  : v.status == RenewalStatus.reviewing
                      ? BadgeKind.info
                      : BadgeKind.danger,
            ),
          ),
          DataCell(
            TextButton(onPressed: () => open(v), child: const Text('Review')),
          ),
        ],
      );
    }).toList();

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
          label: Text('EXPIRY DATE'),
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

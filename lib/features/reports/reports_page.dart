import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final search = TextEditingController();
  final tableScrollController = ScrollController();
  String status = 'All Statuses';
  String? stallCategory = 'All Categories';
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
    final selectedCategory = stallCategory ?? 'All Categories';
    final categories = <String>{
      'All Categories',
      ...data.reports.map((item) => item.category ?? 'FRUITS'),
    }.toList()
      ..sort();
    categories
      ..remove('All Categories')
      ..insert(0, 'All Categories');
    final values = data.reports
        .where(
          (item) =>
              (search.text.trim().isEmpty ||
                  '${item.id} ${item.accountIssue} ${item.submittedBy} ${item.reason}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' ||
                  item.status.toString().split('.').last ==
                      status.toLowerCase().replaceAll(' ', '')) &&
              (selectedCategory == 'All Categories' ||
                  (item.category ?? 'FRUITS') == selectedCategory),
        )
        .toList();
    final int totalPages = (values.length / 10).ceil();
    final int safePage =
        totalPages == 0 ? 0 : page.clamp(0, totalPages - 1) as int;
    return Column(
      children: [
        PageHeader(
          title: 'Reports Management',
          subtitle:
              'Review and manage customer reports, vendor violations, and application support requests submitted from the PalengkeGo mobile application.',
          metrics: [
            MetricCardData(
              value:
                  '${data.reports.where((item) => item.status == ReportStatus.pending).length}',
              label: 'Pending Reports',
              icon: Icons.folder_copy_outlined,
              accent: const Color(0xFFEF4444),
            ),
            MetricCardData(
              value:
                  '${data.reports.where((item) => item.status == ReportStatus.underReview).length}',
              label: 'Under Review',
              icon: Icons.visibility_outlined,
              accent: const Color(0xFF3B82F6),
            ),
            MetricCardData(
              value:
                  '${data.reports.where((item) => item.status == ReportStatus.resolved).length}',
              label: 'Resolved',
              icon: Icons.check_circle_outline_rounded,
              accent: const Color(0xFF10B981),
            ),
            const MetricCardData(
              value: '12,543',
              label: 'Suspended Account',
              icon: Icons.block_outlined,
              accent: Color(0xFFEF4444),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 30),
            child: DataPanel(
              title: 'Recent Reports',
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
                          'Pending',
                          'Under Review',
                          'Resolved',
                        ], (value) {
                          status = value;
                          _resetTable();
                        }),
                        _filter(
                            context,
                            selectedCategory == 'All Categories'
                                ? 'Stall Category'
                                : selectedCategory,
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
                      child: _ReportTable(
                        values: values.skip(safePage * 10).take(10).toList(),
                        verticalController: tableScrollController,
                        onOpen: (item) => showBlurredDialog(
                          context,
                          (context) => ReportReviewDialog(report: item),
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
          final value = await showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(400, 300, 0, 0),
            items: values
                .map((item) => PopupMenuItem(value: item, child: Text(item)))
                .toList(),
          );
          if (value != null) onChanged(value);
        },
      );

  void _export(List<Report> values) {
    final csv = buildCsv([
      [
        'Type',
        'Account / Issue',
        'Submitted By',
        'Reason',
        'Category',
        'Date',
        'Status',
        'Priority'
      ],
      ...values.map(
        (item) => [
          item.type,
          item.accountIssue,
          item.submittedBy,
          item.reason,
          item.category ?? 'FRUITS',
          item.date.toIso8601String(),
          enumLabel(item.status),
          enumLabel(item.priority),
        ],
      ),
    ]);
    downloadCsv(csv, 'palengkego-reports.csv');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports CSV downloaded.')),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.values,
    required this.verticalController,
    required this.onOpen,
  });
  final List<Report> values;
  final ScrollController verticalController;
  final ValueChanged<Report> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (item) => DataRow(
            onSelectChanged: (_) => onOpen(item),
            cells: [
              DataCell(Text(item.type)),
              DataCell(
                Text(
                  item.accountIssue,
                  style: TextStyle(
                    color: semanticColors(context).accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataCell(Text(item.submittedBy)),
              DataCell(Text(item.reason)),
              DataCell(
                StatusBadge(
                  label: item.category ?? 'FRUITS',
                  kind: BadgeKind.info,
                ),
              ),
              DataCell(Text('${item.date.month}/${item.date.day}/2023')),
              DataCell(
                StatusBadge(
                  label: item.status.toString().split('.').last,
                  kind: item.status == ReportStatus.resolved
                      ? BadgeKind.success
                      : item.status == ReportStatus.underReview
                          ? BadgeKind.info
                          : BadgeKind.danger,
                ),
              ),
              DataCell(
                Text(
                  enumLabel(item.priority),
                  style: TextStyle(
                    color: item.priority == Priority.high
                        ? semanticColors(context).danger
                        : item.priority == Priority.medium
                            ? semanticColors(context).warning
                            : semanticColors(context).mutedText,
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();
    return ScrollableDataTable(
      verticalController: verticalController,
      minWidth: 1300,
      columnSpacing: 18,
      columns: const [
        DataColumn(
          columnWidth: FlexColumnWidth(.85),
          label: Text('TYPE'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.4),
          label: Text('ACCOUNT / ISSUE'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.2),
          label: Text('SUBMITTED BY'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.4),
          label: Text('REASON'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.1),
          label: Text('CATEGORY'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(.9),
          label: Text('DATE'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.1),
          label: Text('STATUS'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(.8),
          label: Text('PRIORITY'),
        ),
      ],
      rows: rows,
    );
  }
}

class ReportReviewDialog extends ConsumerStatefulWidget {
  const ReportReviewDialog({super.key, required this.report});
  final Report report;
  @override
  ConsumerState<ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends ConsumerState<ReportReviewDialog> {
  late final notes = TextEditingController(text: widget.report.notes);
  bool processing = false;
  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> resolve() async {
    if (notes.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add investigation findings before resolving.'),
        ),
      );
      return;
    }
    setState(() => processing = true);
    await ref.read(appDataProvider.notifier).updateReport(
          widget.report.id,
          ReportStatus.resolved,
          notes.text.trim(),
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report marked as resolved.')),
      );
    }
  }

  Future<void> action(String title, ReportStatus value) async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a reason or message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    input.dispose();
    if (result == null || result.isEmpty || !mounted) return;
    setState(() => processing = true);
    await ref
        .read(appDataProvider.notifier)
        .updateReport(widget.report.id, value, result);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title completed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Report Review: ${widget.report.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const StatusBadge(
                          label: 'PENDING',
                          kind: BadgeKind.danger,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 14),
              _info(context),
              const SizedBox(height: 17),
              const Text(
                'REASON: SCAM OR FRAUD',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: semanticColors(context).infoContainer.withOpacity(.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.report.description,
                  style: const TextStyle(fontSize: 11, height: 1.45),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'EVIDENCE ATTACHED (2 IMAGES)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _evidence(
                    'assets/images/spoiled_produce.png',
                    'Spoiled produce',
                  ),
                  const SizedBox(width: 10),
                  _evidence(
                    'assets/images/mobile_conversation.png',
                    'Mobile conversation',
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Text(
                'ACCOUNT HISTORY HIGHLIGHTS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _history(context),
              const SizedBox(height: 17),
              const Text(
                'INVESTIGATION FINDINGS & NOTES',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Add investigation findings...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: processing
                          ? null
                          : () => action(
                                'Send warning',
                                ReportStatus.underReview,
                              ),
                      child: const Text('Send Warning'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: processing
                          ? null
                          : () => action(
                                'Suspend vendor',
                                ReportStatus.underReview,
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: semanticColors(context).danger,
                      ),
                      child: const Text('Suspend Vendor'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: processing
                          ? null
                          : () => action(
                                'Dismiss report',
                                ReportStatus.dismissed,
                              ),
                      child: const Text('Dismiss Report'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: processing ? null : resolve,
                      style: FilledButton.styleFrom(
                        backgroundColor: semanticColors(context).heroBackground,
                      ),
                      child: const Text('Mark as Resolved'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(BuildContext context) => Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const AvatarCircle(name: 'Maria Santos', size: 34),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maria Santos',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      widget.report.reporterEmail,
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: semanticColors(context).infoContainer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: semanticColors(context).info,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.vendorName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Vendor: ${widget.report.owner}',
                      style: const TextStyle(fontSize: 9),
                    ),
                    const StatusBadge(
                      label: '2 PREVIOUS VIOLATIONS',
                      kind: BadgeKind.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
  Widget _evidence(String asset, String label) => Expanded(
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              child: InteractiveViewer(
                child: Image.asset(
                  asset,
                  errorBuilder: (context, error, stackTrace) =>
                      _missingEvidence(context),
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _missingEvidence(context),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _missingEvidence(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      color: colors.inputSurface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: colors.mutedText),
          const SizedBox(height: 7),
          Text(
            'Evidence unavailable',
            style: TextStyle(
              color: colors.secondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'The attached image could not be loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedText, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _history(BuildContext context) => Table(
        border: TableBorder.all(color: semanticColors(context).subtleBorder),
        children: [
          TableRow(children: [
            _cell('Date'),
            _cell('Violation Type'),
            _cell('Action Taken'),
            _cell('Status'),
          ]),
          TableRow(children: [
            _cell('Sep 15, 2023'),
            _cell('Late Delivery'),
            _cell('Warning Issued'),
            _cell('Closed'),
          ]),
          TableRow(children: [
            _cell('Aug 02, 2023'),
            _cell('Incorrect Pricing'),
            _cell('System Flag'),
            _cell('Closed'),
          ]),
        ],
      );
  Widget _cell(String value) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(value, style: const TextStyle(fontSize: 9.5)),
      );
}

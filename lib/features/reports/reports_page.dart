import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/formatters.dart';
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
  String stallCategory = 'All Categories';
  bool history = false;
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
    final selectedCategory = stallCategory;
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
              (history
                  ? item.status == ReportStatus.resolved
                  : item.status != ReportStatus.resolved) &&
              (search.text.trim().isEmpty ||
                  '${item.id} ${item.accountIssue} ${item.submittedBy} ${item.reason}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' || enumLabel(item.status) == status) &&
              (selectedCategory == 'All Categories' ||
                  (item.category ?? 'FRUITS') == selectedCategory),
        )
        .toList();
    final int totalPages = (values.length / 10).ceil();
    final int safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
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
            MetricCardData(
              value:
                  '${data.vendors.where((item) => item.status == AccountStatus.blocked).length + data.customers.where((item) => item.status == AccountStatus.blocked).length}',
              label: 'Blocked Accounts',
              icon: Icons.block_outlined,
              accent: Color(0xFFEF4444),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 30),
            child: DataPanel(
              title: history ? 'Resolved Report History' : 'Review Reports',
              headerAction: _ReportViewToggle(
                history: history,
                onChanged: (value) {
                  setState(() {
                    history = value;
                    status = 'All Statuses';
                  });
                  _resetTable();
                },
              ),
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
                        history = false;
                        _resetTable();
                      },
                      trailing: [
                        _filter(status, [
                          'All Statuses',
                          'Pending',
                          'Under Review',
                          'Resolved',
                        ], (value) {
                          status = value;
                          if (value == 'Resolved') history = true;
                          if (value != 'Resolved') history = false;
                          _resetTable();
                        }),
                        _filter(
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        ),
                        child: _ReportTable(
                          key: ValueKey(
                            '$history-${values.map((item) => item.id).join(',')}',
                          ),
                          history: history,
                          values: values.skip(safePage * 10).take(10).toList(),
                          verticalController: tableScrollController,
                          onOpen: (item) => showBlurredDialog(
                            context,
                            (context) => ReportReviewDialog(report: item),
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
    super.key,
    required this.history,
    required this.values,
    required this.verticalController,
    required this.onOpen,
  });
  final bool history;
  final List<Report> values;
  final ScrollController verticalController;
  final ValueChanged<Report> onOpen;
  @override
  Widget build(BuildContext context) {
    final rows = values
        .map(
          (item) => DataRow(
            onSelectChanged: (_) => onOpen(item),
            cells: history
                ? [
                    DataCell(Text(item.type)),
                    DataCell(Text(item.id)),
                    DataCell(
                      Text(
                        item.accountIssue,
                        style: TextStyle(
                          color: semanticColors(context).accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DataCell(Text(item.reason)),
                    DataCell(
                      StatusBadge(
                        label: item.decision ?? 'Resolved',
                        kind: item.decision == 'No Violation'
                            ? BadgeKind.neutral
                            : item.decision == 'Account Blocked'
                                ? BadgeKind.danger
                                : BadgeKind.warning,
                      ),
                    ),
                    DataCell(Text(item.actionTaken ?? 'Resolved')),
                    DataCell(
                      Text(
                        item.resolvedAt == null
                            ? '—'
                            : longDate.format(item.resolvedAt!),
                      ),
                    ),
                    DataCell(Text(item.resolvedBy ?? 'Administrator')),
                  ]
                : [
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
      minWidth: history ? 1450 : 1300,
      columnSpacing: 18,
      columns: history
          ? const [
              DataColumn(
                columnWidth: FlexColumnWidth(.85),
                label: Text('TYPE'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.15),
                label: Text('REPORT ID'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.35),
                label: Text('REPORTED USER'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.25),
                label: Text('REASON'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.3),
                label: Text('DECISION'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.25),
                label: Text('ACTION TAKEN'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.35),
                label: Text('RESOLVED DATE'),
              ),
              DataColumn(
                columnWidth: FlexColumnWidth(1.15),
                label: Text('RESOLVED BY'),
              ),
            ]
          : const [
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

class _ReportViewToggle extends StatelessWidget {
  const _ReportViewToggle({required this.history, required this.onChanged});

  final bool history;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text('Review'),
            icon: Icon(Icons.inbox_outlined, size: 15),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Resolved'),
            icon: Icon(Icons.history_rounded, size: 15),
          ),
        ],
        selected: {history},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      );
}

class _ReportedAccount {
  const _ReportedAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  final String id;
  final String name;
  final String type;
  final AccountStatus status;
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

  _ReportedAccount? _reportedAccount(AppDataState data) {
    if (widget.report.type == 'Vendor') {
      for (final vendor in data.vendors) {
        if (vendor.name == widget.report.accountIssue ||
            vendor.name == widget.report.vendorName) {
          return _ReportedAccount(
            id: vendor.id,
            name: vendor.name,
            type: 'Vendor / Stall Holder',
            status: vendor.status,
          );
        }
      }
    }
    if (widget.report.type == 'Customer') {
      for (final customer in data.customers) {
        if (customer.name == widget.report.accountIssue) {
          return _ReportedAccount(
            id: customer.id,
            name: customer.name,
            type: 'Customer',
            status: customer.status,
          );
        }
      }
      for (final vendor in data.vendors) {
        if (vendor.name == widget.report.vendorName) {
          return _ReportedAccount(
            id: vendor.id,
            name: vendor.name,
            type: 'Vendor / Stall Holder',
            status: vendor.status,
          );
        }
      }
    }
    return null;
  }

  String _reportedAccountTypeLabel() {
    final account = _reportedAccount(ref.read(appDataProvider));
    if (account == null) return widget.report.type.toUpperCase();
    return account.type.startsWith('Vendor') ? 'VENDOR' : 'CUSTOMER';
  }

  String _reportedAccountName() {
    final account = _reportedAccount(ref.read(appDataProvider));
    return account?.name ?? widget.report.vendorName;
  }

  String _reportedAccountSubtitle() {
    final account = _reportedAccount(ref.read(appDataProvider));
    return account?.type == 'Customer'
        ? 'Customer Account'
        : 'Vendor: ${widget.report.owner}';
  }

  Future<void> _dismissReport({bool markResolved = false}) async {
    final resolutionNote = TextEditingController();
    final title = markResolved ? 'Mark Report as Resolved?' : 'Dismiss Report?';
    final confirmation = markResolved
        ? 'This will mark the report as resolved without changing the account '
            'status.'
        : 'This will dismiss the report without changing the account status.';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report: #${widget.report.id}'),
                const SizedBox(height: 7),
                Text('Reported User: ${widget.report.accountIssue}'),
                const SizedBox(height: 14),
                Text(confirmation),
                const SizedBox(height: 14),
                TextField(
                  controller: resolutionNote,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Optional Resolution Note',
                    hintText: 'Enter a note for the resolved report',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  Text(markResolved ? 'Mark as Resolved' : 'Confirm Dismiss'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => processing = true);
      final error = markResolved
          ? await ref.read(appDataProvider.notifier).resolveReport(
                reportId: widget.report.id,
                note: resolutionNote.text,
              )
          : await ref.read(appDataProvider.notifier).dismissReport(
                reportId: widget.report.id,
                note: resolutionNote.text,
              );
      if (!mounted) return;
      if (error != null) {
        setState(() => processing = false);
        _showError(error);
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            markResolved
                ? 'Report resolved successfully. Moved to Resolved Reports.'
                : 'Report dismissed successfully. Moved to Resolved Reports.',
          ),
        ),
      );
    } finally {
      resolutionNote.dispose();
    }
  }

  Future<void> _blockAccount(_ReportedAccount? account) async {
    if (account == null || processing) return;
    final reason = TextEditingController();
    String? validationError;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Block Account?'),
            content: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reported User: ${account.name}'),
                  const SizedBox(height: 6),
                  Text('Account Type: ${account.type}'),
                  const SizedBox(height: 6),
                  Text('Related Report: #${widget.report.id}'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reason,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) {
                      if (validationError != null) {
                        setDialogState(() => validationError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Blocking Reason *',
                      hintText: 'Enter the reason for blocking',
                      errorText: validationError,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: semanticColors(context).danger,
                ),
                onPressed: () {
                  if (reason.text.trim().isEmpty) {
                    setDialogState(
                      () => validationError = 'A blocking reason is required.',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.block_outlined, size: 17),
                label: const Text('Block Account'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => processing = true);
      final error =
          await ref.read(appDataProvider.notifier).blockAccountFromReport(
                reportId: widget.report.id,
                reason: reason.text,
              );
      if (!mounted) return;
      if (error != null) {
        setState(() => processing = false);
        _showError(error);
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Account blocked successfully. Report moved to Resolved.'),
        ),
      );
      if (mounted) {
        context.go(
          '/accounts?accountId=${Uri.encodeComponent(account.id)}&open=1',
        );
      }
    } finally {
      reason.dispose();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> action(String title, ReportStatus value) async {
    final input = TextEditingController();
    try {
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
    } finally {
      input.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.report.status == ReportStatus.resolved;
    final account = _reportedAccount(ref.read(appDataProvider));
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
                        StatusBadge(
                          label: enumLabel(widget.report.status),
                          kind: widget.report.status == ReportStatus.resolved
                              ? BadgeKind.success
                              : widget.report.status == ReportStatus.underReview
                                  ? BadgeKind.info
                                  : BadgeKind.danger,
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
              Text(
                'REASON: ${widget.report.reason.toUpperCase()}',
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
                readOnly: resolved,
                decoration: const InputDecoration(
                  hintText: 'Add investigation findings...',
                ),
              ),
              if (widget.report.decision != null) ...[
                const SizedBox(height: 14),
                _decisionSummary(context),
              ],
              if (!resolved) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = constraints.maxWidth < 520
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 10) / 2;
                    final outlineStyle = OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );
                    final warningStyle = outlineStyle.copyWith(
                      foregroundColor: WidgetStatePropertyAll(
                        semanticColors(context).warning,
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: semanticColors(context).warning),
                      ),
                    );
                    final resolvedStyle = FilledButton.styleFrom(
                      backgroundColor: semanticColors(context).heroBackground,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );
                    final dangerStyle = FilledButton.styleFrom(
                      backgroundColor: semanticColors(context).danger,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );

                    final buttons = [
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          onPressed: processing
                              ? null
                              : () => action(
                                    'Send warning',
                                    ReportStatus.underReview,
                                  ),
                          style: warningStyle,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Send Warning'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          onPressed: processing ? null : _dismissReport,
                          style: outlineStyle,
                          child: const Text('Dismiss Report'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: FilledButton.icon(
                          onPressed: processing
                              ? null
                              : () => _dismissReport(markResolved: true),
                          style: resolvedStyle,
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Mark as Resolved'),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: FilledButton.icon(
                          onPressed: processing || account == null
                              ? null
                              : () => _blockAccount(account),
                          style: dangerStyle,
                          icon: const Icon(Icons.block_outlined, size: 16),
                          label: const Text('Block Account'),
                        ),
                      ),
                    ];

                    if (constraints.maxWidth < 520) {
                      return Column(
                        children: [
                          buttons[0],
                          const SizedBox(height: 10),
                          buttons[1],
                          const SizedBox(height: 10),
                          buttons[2],
                          const SizedBox(height: 10),
                          buttons[3],
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: buttons[0]),
                            const SizedBox(width: 10),
                            Expanded(child: buttons[1]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: buttons[2]),
                            const SizedBox(width: 10),
                            Expanded(child: buttons[3]),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _decisionSummary(BuildContext context) {
    final isDismissed = widget.report.decision == 'No Violation';
    final color = isDismissed
        ? semanticColors(context).mutedText
        : widget.report.decision == 'Account Blocked'
            ? semanticColors(context).danger
            : semanticColors(context).warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINAL DECISION',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.report.decision ?? 'Resolved'),
          if (widget.report.actionTaken != null)
            Text('Action taken: ${widget.report.actionTaken}'),
          if (widget.report.resolutionNote != null &&
              widget.report.resolutionNote!.isNotEmpty)
            Text('Note: ${widget.report.resolutionNote}'),
          if (widget.report.resolvedBy != null)
            Text('Resolved by: ${widget.report.resolvedBy}'),
          if (widget.report.resolvedAt != null)
            Text('Resolved on: ${longDate.format(widget.report.resolvedAt!)}'),
        ],
      ),
    );
  }

  Widget _info(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _infoHeading(context, 'REPORTER INFORMATION')),
              const SizedBox(width: 24),
              Expanded(
                child: _infoHeading(
                  context,
                  'REPORTED ACCOUNT (${_reportedAccountTypeLabel()})',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AvatarCircle(name: 'Maria Santos', size: 34),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maria Santos',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.report.reporterEmail,
                            style: const TextStyle(fontSize: 9),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                widget.report.phone,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _reportedAccountName(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _reportedAccountSubtitle(),
                            style: const TextStyle(fontSize: 9),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'Stall No: ${widget.report.stallNumber}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              StatusBadge(
                                label:
                                    '${widget.report.previousViolations} PREVIOUS VIOLATIONS',
                                kind: BadgeKind.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

  Widget _infoHeading(BuildContext context, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Theme.of(context).dividerColor),
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

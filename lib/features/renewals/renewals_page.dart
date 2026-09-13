import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/export/admin_export_service.dart';
import '../../core/utils/export/module_export_data_builders.dart';
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
  static const _viewedRenewalsPreference = 'renewals_viewed_new_badges';
  final search = TextEditingController();
  final tableScrollController = ScrollController();
  String status = 'All Statuses';
  String stallCategory = 'All Categories';
  int page = 0;
  late Set<String> _viewedRenewalIds;

  @override
  void initState() {
    super.initState();
    _viewedRenewalIds = ref
            .read(sharedPreferencesProvider)
            .getStringList(_viewedRenewalsPreference)
            ?.toSet() ??
        <String>{};
  }

  void _markRenewalViewed(String id) {
    if (!_viewedRenewalIds.add(id)) return;
    setState(() {});
    ref.read(sharedPreferencesProvider).setStringList(
          _viewedRenewalsPreference,
          _viewedRenewalIds.toList(),
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
    final renewals = ref.watch(appDataProvider.select((s) => s.renewals));
    final categories = <String>{
      'All Categories',
      ...renewals.map((item) => item.category),
    }.toList()
      ..sort();
    categories
      ..remove('All Categories')
      ..insert(0, 'All Categories');
    final values = renewals
        .where(
          (v) =>
              (search.text.trim().isEmpty ||
                  '${v.id} ${v.applicant} ${v.stallName}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (status == 'All Statuses' || _status(v.status) == status) &&
              (stallCategory == 'All Categories' ||
                  v.category == stallCategory),
        )
        .toList()
      ..sort((a, b) {
        final aCompleted = a.status == RenewalStatus.approved ||
            a.status == RenewalStatus.expired;
        final bCompleted = b.status == RenewalStatus.approved ||
            b.status == RenewalStatus.expired;
        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }
        final aDate = a.submittedAt ?? a.expiryDate;
        final bDate = b.submittedAt ?? b.expiryDate;
        return bDate.compareTo(aDate);
      });
    final now = DateTime.now();
    final todayRenewals = renewals.where((item) {
      final date = item.submittedAt;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    });
    final todayReviewing = todayRenewals.where(
      (item) => item.status == RenewalStatus.reviewing,
    );
    final Set<String> newRenewalIds;
    if (todayReviewing.isNotEmpty) {
      newRenewalIds = todayReviewing
          .map((item) => item.id)
          .where((id) => !_viewedRenewalIds.contains(id))
          .toSet();
    } else {
      final newestId = _newestRenewalId(renewals);
      newRenewalIds = newestId != null && !_viewedRenewalIds.contains(newestId)
          ? {newestId}
          : <String>{};
    }
    final int totalPages = (values.length / 10).ceil();
    final int safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final totalApproved = renewals
        .where((v) => v.status == RenewalStatus.approved)
        .length;
    final expiring = renewals.where((v) {
      final days = v.expiryDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 7;
    }).length;
    final expired = renewals
        .where((v) =>
            v.status == RenewalStatus.expired ||
            v.expiryDate.isBefore(DateTime.now()))
        .length;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          title: 'Renewal Management',
          subtitle:
              'Review and process renewal requests from existing stall holders.',
          metrics: [
            MetricCardData(
              value: '${renewals.length}',
              label: 'Total Request',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFF10B981),
            ),
            MetricCardData(
              value: '$totalApproved',
              label: 'Approved Application',
              icon: Icons.verified_outlined,
              accent: const Color(0xFF6B7280),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 26, 36, 36),
          child: DataPanel(
            title: 'Renewal',
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
                      'Approved',
                      'Reviewing',
                      'Expired',
                    ], (v) {
                      status = v;
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
                    ExportButton(
                      onExportPdf: () => _exportRenewals(
                        allRenewals: renewals,
                        filteredRenewals: values,
                        format: ExportFormat.pdf,
                      ),
                      onExportExcel: () => _exportRenewals(
                        allRenewals: renewals,
                        filteredRenewals: values,
                        format: ExportFormat.excel,
                      ),
                    ),
                  ],
                ),
                _Table(
                  values: values.skip(safePage * 10).take(10).toList(),
                  newRenewalIds: newRenewalIds,
                  verticalController: tableScrollController,
                  open: (v) {
                    _markRenewalViewed(v.id);
                    showBlurredDialog(
                      context,
                      (context) => VerificationDialog.renewal(v),
                    );
                  },
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

  Future<void> _exportRenewals({
    required List<RenewalRequest> allRenewals,
    required List<RenewalRequest> filteredRenewals,
    required ExportFormat format,
  }) async {
    final filterLabels = <String>[];
    if (search.text.trim().isNotEmpty) {
      filterLabels.add('Search: "${search.text.trim()}"');
    }
    filterLabels.add(status);
    filterLabels.add(stallCategory);

    final doc = RenewalExportData.build(
      allRenewals: allRenewals,
      filteredRenewals: filteredRenewals,
      activeFilters: filterLabels.join(' | '),
    );

    await AdminExportService.export(
      context: context,
      ref: ref,
      doc: doc,
      format: format,
    );
  }

  String _status(RenewalStatus value) => switch (value) {
        RenewalStatus.approved => 'Approved',
        RenewalStatus.reviewing => 'Reviewing',
        RenewalStatus.expired => 'Expired',
      };

  String? _newestRenewalId(List<RenewalRequest> values) {
    final reviewing = values
        .where((item) => item.status == RenewalStatus.reviewing)
        .toList();
    if (reviewing.isEmpty) return null;
    var newest = reviewing.first;
    for (final item in reviewing.skip(1)) {
      final itemDate = item.submittedAt ?? item.expiryDate;
      final newestDate = newest.submittedAt ?? newest.expiryDate;
      if (itemDate.isAfter(newestDate)) newest = item;
    }
    return newest.id;
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.values,
    required this.newRenewalIds,
    required this.verticalController,
    required this.open,
  });
  final List<RenewalRequest> values;
  final Set<String> newRenewalIds;
  final ScrollController verticalController;
  final ValueChanged<RenewalRequest> open;
  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final rows = values.map((v) {
      final days = v.expiryDate.difference(DateTime.now()).inDays;
      final isNew = newRenewalIds.contains(v.id);
      return DataRow(
        color: isNew
            ? WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return colors.info.withValues(alpha: 0.13);
                }
                return colors.info.withValues(alpha: 0.07);
              })
            : null,
        onSelectChanged: (_) => open(v),
        cells: [
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew)
                  Container(
                    width: 3.5,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colors.info,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Text(
                  v.id,
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            Wrap(
              spacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AvatarCircle(name: v.applicant, size: 28),
                Text(
                  v.applicant,
                  style: isNew
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                ),
                if (isNew)
                  const StatusBadge(
                    label: 'NEW',
                    kind: BadgeKind.info,
                  ),
              ],
            ),
          ),
          DataCell(Text(v.stallName)),
          DataCell(CategoryBadge(category: v.category)),
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
                        ? colors.danger
                        : colors.warning,
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
            TableActionReviewButton(onPressed: () => open(v)),
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

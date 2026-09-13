import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/export/admin_export_service.dart';
import '../../core/utils/export/module_export_data_builders.dart';
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
  late Set<String> _viewedApplicationIds;

  @override
  void initState() {
    super.initState();
    _viewedApplicationIds = ref
            .read(sharedPreferencesProvider)
            .getStringList(_viewedApplicationsPreference)
            ?.toSet() ??
        <String>{};
  }

  void _markApplicationViewed(String applicationId) {
    if (!_viewedApplicationIds.add(applicationId)) return;
    setState(() {});
    ref.read(sharedPreferencesProvider).setStringList(
          _viewedApplicationsPreference,
          _viewedApplicationIds.toList(),
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
      ..sort((a, b) {
        final aCompleted = a.status == ApplicationStatus.verified ||
            a.status == ApplicationStatus.rejected ||
            a.status == ApplicationStatus.invalidDocs;
        final bCompleted = b.status == ApplicationStatus.verified ||
            b.status == ApplicationStatus.rejected ||
            b.status == ApplicationStatus.invalidDocs;
        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }
        return b.submittedAt.compareTo(a.submittedAt);
      });
    final now = DateTime.now();
    final todayApplications = data.applications.where(
      (item) =>
          item.submittedAt.year == now.year &&
          item.submittedAt.month == now.month &&
          item.submittedAt.day == now.day,
    );
    final todayReviewing = todayApplications.where(
      (item) => item.status == ApplicationStatus.reviewing,
    );
    final Set<String> newApplicationIds;
    if (todayReviewing.isNotEmpty) {
      newApplicationIds = todayReviewing
          .map((item) => item.id)
          .where((id) => !_viewedApplicationIds.contains(id))
          .toSet();
    } else {
      final newestApplicationId = _newestId(data.applications);
      newApplicationIds = newestApplicationId != null &&
              !_viewedApplicationIds.contains(newestApplicationId)
          ? {newestApplicationId}
          : <String>{};
    }
    final int totalPages = (values.length / 10).ceil();
    final int safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);

    final pendingCount = data.applications
        .where((item) => item.status == ApplicationStatus.reviewing)
        .length;
    final approvedCount = data.applications
        .where((item) => item.status == ApplicationStatus.verified)
        .length;
    final rejectedCount = data.applications
        .where((item) =>
            item.status == ApplicationStatus.rejected ||
            item.status == ApplicationStatus.invalidDocs)
        .length;

    final int newTodayCount;
    if (todayApplications.isNotEmpty) {
      newTodayCount = todayApplications.length;
    } else if (data.applications.isNotEmpty) {
      final latestDate = data.applications
          .map((a) => a.submittedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      newTodayCount = data.applications.where((item) {
        return item.submittedAt.year == latestDate.year &&
            item.submittedAt.month == latestDate.month &&
            item.submittedAt.day == latestDate.day;
      }).length;
    } else {
      newTodayCount = 0;
    }
    final newTodayFormatted =
        newTodayCount < 10 ? '0$newTodayCount' : '$newTodayCount';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          title: 'Stall Holder Applications',
          subtitle:
              'Review and verify new stall holder applications before granting access to the marketplace.',
          metrics: [
            MetricCardData(
              value: '$pendingCount',
              label: 'Pending Application',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFFF59E0B),
            ),
            MetricCardData(
              value: '$approvedCount',
              label: 'Approved Application',
              icon: Icons.verified_outlined,
              accent: const Color(0xFF10B981),
            ),
            MetricCardData(
              value: '$rejectedCount',
              label: 'Rejected',
              icon: Icons.cancel_outlined,
              accent: const Color(0xFFEF4444),
            ),
            MetricCardData(
              value: newTodayFormatted,
              label: 'New Today',
              icon: Icons.today_outlined,
              accent: const Color(0xFF3B82F6),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 26, 36, 36),
          child: DataPanel(
            title: 'Recent Applications',
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
                      'Rejected',
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
                    ExportButton(
                      onExportPdf: () => _exportApplications(
                        allApplications: data.applications,
                        filteredApplications: values,
                        format: ExportFormat.pdf,
                      ),
                      onExportExcel: () => _exportApplications(
                        allApplications: data.applications,
                        filteredApplications: values,
                        format: ExportFormat.excel,
                      ),
                    ),
                  ],
                ),
                _ApplicationTable(
                  values: values.skip(safePage * 10).take(10).toList(),
                  newApplicationIds: newApplicationIds,
                  verticalController: tableScrollController,
                  onOpen: (item) {
                    _markApplicationViewed(item.id);
                    showBlurredDialog(
                      context,
                      (context) => VerificationDialog.application(item),
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

  Future<void> _exportApplications({
    required List<VendorApplication> allApplications,
    required List<VendorApplication> filteredApplications,
    required ExportFormat format,
  }) async {
    final filterLabels = <String>[];
    if (search.text.trim().isNotEmpty) {
      filterLabels.add('Search: "${search.text.trim()}"');
    }
    filterLabels.add(status);
    filterLabels.add(stallCategory);

    final doc = ApplicationExportData.build(
      allApplications: allApplications,
      filteredApplications: filteredApplications,
      activeFilters: filterLabels.join(' | '),
    );

    await AdminExportService.export(
      context: context,
      ref: ref,
      doc: doc,
      format: format,
    );
  }

  String? _newestId(List<VendorApplication> values) {
    final pending = values
        .where((item) => item.status == ApplicationStatus.reviewing)
        .toList();
    if (pending.isEmpty) return null;
    var newest = pending.first;
    for (final item in pending.skip(1)) {
      if (item.submittedAt.isAfter(newest.submittedAt)) newest = item;
    }
    return newest.id;
  }
}

class _ApplicationTable extends StatelessWidget {
  const _ApplicationTable({
    required this.values,
    required this.newApplicationIds,
    required this.verticalController,
    required this.onOpen,
  });
  final List<VendorApplication> values;
  final Set<String> newApplicationIds;
  final ScrollController verticalController;
  final ValueChanged<VendorApplication> onOpen;
  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final rows = values
        .map(
          (item) {
            final isNew = newApplicationIds.contains(item.id);
            return DataRow(
              color: isNew
                  ? WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return colors.info.withValues(alpha: 0.13);
                      }
                      return colors.info.withValues(alpha: 0.07);
                    })
                  : null,
              onSelectChanged: (_) => onOpen(item),
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
                        item.id,
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
                      AvatarCircle(name: item.applicant, size: 28),
                      Text(
                        item.applicant,
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
                DataCell(Text(item.stallName)),
                DataCell(CategoryBadge(category: item.category)),
                DataCell(
                  Text(
                    '${item.submittedAt.month.toString().padLeft(2, '0')}/${item.submittedAt.day.toString().padLeft(2, '0')}/${item.submittedAt.year}',
                  ),
                ),
                DataCell(
                  ApplicationStatusBadge(status: item.status),
                ),
                DataCell(
                  TableActionReviewButton(
                    onPressed: () => onOpen(item),
                  ),
                ),
              ],
            );
          },
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

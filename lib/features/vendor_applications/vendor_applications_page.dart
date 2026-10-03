import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/export/admin_export_service.dart';
import '../../core/utils/export/module_export_data_builders.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/app_models.dart';
import 'application_utils.dart';
import 'verification_dialog.dart';

enum _ApplicationView { all, pending, history }

class VendorApplicationsPage extends ConsumerStatefulWidget {
  const VendorApplicationsPage({
    super.key,
    this.selectedApplicationId,
    this.openDetailsOnLoad = false,
  });

  final String? selectedApplicationId;
  final bool openDetailsOnLoad;

  @override
  ConsumerState<VendorApplicationsPage> createState() =>
      _VendorApplicationsPageState();
}

class _VendorApplicationsPageState
    extends ConsumerState<VendorApplicationsPage> {
  static const _viewedApplicationsPreference = 'applications_viewed_new_badges';
  final search = TextEditingController();
  final tableScrollController = ScrollController();
  String status = 'All Applications';
  String stallCategory = 'All Categories';
  _ApplicationView get view => switch (status) {
        'All Applications' => _ApplicationView.all,
        'Pending Review' => _ApplicationView.pending,
        _ => _ApplicationView.history,
      };
  int page = 0;
  late Set<String> _viewedApplicationIds;
  bool _selectedApplicationOpened = false;

  @override
  void initState() {
    super.initState();
    _viewedApplicationIds = ref
            .read(sharedPreferencesProvider)
            .getStringList(_viewedApplicationsPreference)
            ?.toSet() ??
        <String>{};
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openSelectedApplication(),
    );
  }

  @override
  void didUpdateWidget(covariant VendorApplicationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedApplicationId != oldWidget.selectedApplicationId ||
        widget.openDetailsOnLoad != oldWidget.openDetailsOnLoad) {
      _selectedApplicationOpened = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openSelectedApplication(),
      );
    }
  }

  void _openSelectedApplication() {
    if (!mounted ||
        _selectedApplicationOpened ||
        !widget.openDetailsOnLoad ||
        widget.selectedApplicationId == null) {
      return;
    }
    VendorApplication? selected;
    for (final item in ref.read(appDataProvider).applications) {
      if (item.id == widget.selectedApplicationId) {
        selected = item;
        break;
      }
    }
    if (selected == null) return;
    _selectedApplicationOpened = true;
    _markApplicationViewed(selected.id);
    showBlurredDialog(
      context,
      (context) => VerificationDialog.application(selected!),
    );
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

  DateTime _getEffectiveToday(List<VendorApplication> applications) {
    final now = DateTime.now();
    final hasToday =
        applications.any((item) => isSameCalendarDay(item.submittedAt, now));
    if (hasToday || applications.isEmpty) {
      return now;
    }
    return applications
        .map((a) => a.submittedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final pendingCount = data.applications
        .where((item) => item.status == ApplicationStatus.reviewing)
        .length;
    final approvedCount = data.applications
        .where((item) => item.status == ApplicationStatus.verified)
        .length;
    final invalidDocsCount = data.applications
        .where((item) => item.status == ApplicationStatus.invalidDocs)
        .length;
    final rejectedCount = data.applications
        .where((item) => item.status == ApplicationStatus.rejected)
        .length;

    final categories = <String>{
      'All Categories',
      ...data.applications.map((item) => item.category),
    }.toList()
      ..sort();
    categories
      ..remove('All Categories')
      ..insert(0, 'All Categories');

    final effectiveToday = _getEffectiveToday(data.applications);
    final newApplications = data.applications
        .where((item) =>
            item.status == ApplicationStatus.reviewing &&
            isApplicationNew(item, _viewedApplicationIds, effectiveToday))
        .toList();
    final newApplicationIds = newApplications.map((item) => item.id).toSet();
    final newTodayCount = newApplications.length;
    final newTodayFormatted = '$newTodayCount';

    final values = data.applications
        .where(
          (item) =>
              (search.text.trim().isEmpty ||
                  '${item.id} ${item.applicant} ${item.stallName}'
                      .toLowerCase()
                      .contains(search.text.trim().toLowerCase())) &&
              (switch (status) {
                'All Applications' => true,
                'Pending Review' =>
                  item.status == ApplicationStatus.reviewing,
                'Application History' =>
                  item.status != ApplicationStatus.reviewing,
                'Verified' => item.status == ApplicationStatus.verified,
                'Re-Upload Requested' =>
                  item.status == ApplicationStatus.invalidDocs,
                'Rejected' => item.status == ApplicationStatus.rejected,
                _ => false,
              }) &&
              (stallCategory == 'All Categories' ||
                  item.category == stallCategory),
        )
        .toList()
      ..sort((a, b) {
        final aIsNew = newApplicationIds.contains(a.id);
        final bIsNew = newApplicationIds.contains(b.id);
        if (aIsNew != bIsNew) {
          return aIsNew ? -1 : 1;
        }
        return b.submittedAt.compareTo(a.submittedAt);
      });

    final int totalPages = (values.length / 10).ceil();
    final int safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);

    final hasActiveFilters = search.text.trim().isNotEmpty ||
        (status != 'All Applications' &&
            status != 'Pending Review' &&
            status != 'Application History') ||
        stallCategory != 'All Categories';

    final Widget emptyStateWidget;
    if (hasActiveFilters) {
      emptyStateWidget = const EmptyState(
        message: 'No results found',
        description: 'Try changing your search or filter selection.',
        icon: Icons.search_off_rounded,
      );
    } else if (view == _ApplicationView.pending) {
      emptyStateWidget = EmptyState(
        message: 'No pending applications',
        description:
            'All applications have been processed. Check Application History for past records.',
        icon: Icons.task_alt_rounded,
        action: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              status = 'Application History';
            });
            _resetTable();
          },
          icon: const Icon(Icons.history_rounded, size: 16),
          label: const Text('View Application History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: semanticColors(context).accent,
            side: BorderSide(color: semanticColors(context).accent),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else if (view == _ApplicationView.all) {
      emptyStateWidget = const EmptyState(
        message: 'No applications found',
        description:
            'Stall holder applications will appear here when submitted.',
        icon: Icons.assignment_outlined,
      );
    } else {
      emptyStateWidget = const EmptyState(
        message: 'No application history found',
        description: 'No processed stall holder applications recorded yet.',
        icon: Icons.history_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          title: 'Stall Holder Applications',
          subtitle:
              'Review and verify new stall holder applications before granting access to the marketplace.',
          metrics: [
            MetricCardData(
              value: '${data.applications.length}',
              label: 'Total Applications',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFF10B981),
              onTap: () {
                setState(() {
                  search.clear();
                  stallCategory = 'All Categories';
                  status = 'All Applications';
                });
                _resetTable();
              },
            ),
            MetricCardData(
              value: '$pendingCount',
              label: 'Pending Application',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFFF59E0B),
              onTap: () {
                setState(() {
                  status = 'Pending Review';
                });
                _resetTable();
              },
            ),
            MetricCardData(
              value: '$approvedCount',
              label: 'Approved Application',
              icon: Icons.verified_outlined,
              accent: const Color(0xFF10B981),
              onTap: () {
                setState(() {
                  status = 'Verified';
                });
                _resetTable();
              },
            ),
            MetricCardData(
              value: '$invalidDocsCount',
              label: 'Re-Upload Requested',
              icon: Icons.document_scanner_outlined,
              accent: const Color(0xFFD97706),
              onTap: () {
                setState(() {
                  status = 'Re-Upload Requested';
                });
                _resetTable();
              },
            ),
            MetricCardData(
              value: '$rejectedCount',
              label: 'Rejected',
              icon: Icons.cancel_outlined,
              accent: const Color(0xFFEF4444),
              onTap: () {
                setState(() {
                  status = 'Rejected';
                });
                _resetTable();
              },
            ),
            MetricCardData(
              value: newTodayFormatted,
              label: 'New Today',
              icon: Icons.today_outlined,
              accent: const Color(0xFF3B82F6),
              onTap: () {
                setState(() {
                  status = 'Pending Review';
                });
                _resetTable();
              },
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            26,
            Responsive.horizontalPadding(context),
            36,
          ),
          child: DataPanel(
            title: switch (view) {
              _ApplicationView.all => 'All Applications',
              _ApplicationView.pending => 'Recent Applications',
              _ApplicationView.history => 'Application History',
            },
            child: Column(
              children: [
                Toolbar(
                  controller: search,
                  onChanged: (_) => _resetTable(),
                  onClear: () {
                    search.clear();
                    status = 'All Applications';
                    stallCategory = 'All Categories';
                    _resetTable();
                  },
                  trailing: [
                    _filter(
                      status,
                      const [
                        'All Applications',
                        'Pending Review',
                        'Application History',
                        'Verified',
                        'Re-Upload Requested',
                        'Rejected',
                      ],
                      (value) {
                        setState(() {
                          status = value;
                        });
                        _resetTable();
                      },
                    ),
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
                  history: view == _ApplicationView.history,
                  values: values.skip(safePage * 10).take(10).toList(),
                  newApplicationIds: newApplicationIds,
                  verticalController: tableScrollController,
                  emptyState: emptyStateWidget,
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
}

class _ApplicationTable extends StatelessWidget {
  const _ApplicationTable({
    required this.history,
    required this.values,
    required this.newApplicationIds,
    required this.verticalController,
    required this.onOpen,
    required this.emptyState,
  });
  final bool history;
  final List<VendorApplication> values;
  final Set<String> newApplicationIds;
  final ScrollController verticalController;
  final ValueChanged<VendorApplication> onOpen;
  final Widget emptyState;
  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final rows = values
        .map(
          (item) {
            final isResolved = item.status == ApplicationStatus.verified ||
                item.status == ApplicationStatus.rejected ||
                item.status == ApplicationStatus.invalidDocs;
            final isNew = !history && !isResolved && newApplicationIds.contains(item.id);
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
                    DateFormat('MM/dd/yyyy, h:mm a').format(item.submittedAt),
                  ),
                ),
                DataCell(
                  ApplicationStatusBadge(status: item.status),
                ),
                DataCell(
                  TableActionReviewButton(
                    label: isResolved ? 'View Details' : 'Review',
                    tooltip: isResolved
                        ? 'View application details'
                        : 'Review application',
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
      minWidth: 1500,
      columnSpacing: 18,
      emptyState: emptyState,
      columns: const [
        DataColumn(
          columnWidth: FlexColumnWidth(1.25),
          label: Text('APPLICATION ID'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.25),
          label: Text('APPLICANT'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.35),
          label: Text('STALL NAME'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(0.95),
          label: Text('CATEGORY'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.25),
          label: Text('DATE SUBMITTED'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(1.75),
          label: Text('VERIFICATION STATUS'),
        ),
        DataColumn(
          columnWidth: FlexColumnWidth(0.8),
          label: Text('ACTIONS'),
        ),
      ],
      rows: rows,
    );
  }
}

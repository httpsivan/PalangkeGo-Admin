import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../core/widgets/formatted_text.dart';
import '../../core/widgets/sales_line_chart.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../announcements/announcement_dialog.dart';
import '../vendor_applications/verification_dialog.dart';

enum OverviewPanelId { kyc, salesChart, topSellers, announcements }

class _PanelState {
  _PanelState({
    required this.id,
    required this.title,
    this.isFullWidth = false,
    this.isExpanded = false,
    bool? defaultFullWidth,
    bool? defaultExpanded,
  })  : defaultFullWidth = defaultFullWidth ?? isFullWidth,
        defaultExpanded = defaultExpanded ?? isExpanded;

  final OverviewPanelId id;
  final String title;
  bool isFullWidth;
  bool isExpanded;
  final bool defaultFullWidth;
  final bool defaultExpanded;

  bool get isZoomed =>
      isFullWidth != defaultFullWidth || isExpanded != defaultExpanded;
}

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  late List<_PanelState> _panels;

  @override
  void initState() {
    super.initState();
    _resetLayout();
  }

  void _resetLayout() {
    setState(() {
      _panels = [
        _PanelState(
          id: OverviewPanelId.kyc,
          title: 'Needs Action: KYC Approvals',
          isFullWidth: true,
          isExpanded: false,
        ),
        _PanelState(
          id: OverviewPanelId.salesChart,
          title: 'SALES OVERVIEW',
          isFullWidth: true,
          isExpanded: false,
        ),
        _PanelState(
          id: OverviewPanelId.topSellers,
          title: 'TOP SELLERS',
          isFullWidth: false,
          isExpanded: false,
        ),
        _PanelState(
          id: OverviewPanelId.announcements,
          title: 'ANNOUNCEMENTS',
          isFullWidth: false,
          isExpanded: false,
        ),
      ];
    });
  }

  void _reorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      final item = _panels.removeAt(fromIndex);
      _panels.insert(toIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      appDataProvider.select(
        (s) => (
          applications: s.applications,
          renewals: s.renewals,
          reports: s.reports,
          orders: s.orders,
          vendors: s.vendors,
          customers: s.customers,
          announcements: s.announcements,
        ),
      ),
    );
    final colors = semanticColors(context);

    Widget buildPanelWidget(_PanelState state, int index) {
      Widget childWidget;
      Widget headerAction;

      switch (state.id) {
        case OverviewPanelId.kyc:
          headerAction = Tooltip(
            message: 'View all KYC applications',
            child: OutlinedButton(
              onPressed: () => context.go('/applications'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.secondaryText,
                backgroundColor: colors.hoverSurface,
                side: BorderSide(color: colors.subtleBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            ),
          );
          final kycActionItems = data.applications
              .where((item) => item.status == ApplicationStatus.reviewing)
              .toList()
            ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          childWidget = _ApprovalTable(
            items:
                (kycActionItems.isNotEmpty ? kycActionItems : data.applications)
                    .take(state.isExpanded ? 6 : 3)
                    .toList(),
          );
          break;

        case OverviewPanelId.salesChart:
          headerAction = Tooltip(
            message: 'View full sales reports',
            child: OutlinedButton(
              onPressed: () => context.go('/sales-reports'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.secondaryText,
                backgroundColor: colors.hoverSurface,
                side: BorderSide(color: colors.subtleBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            ),
          );
          final today = DateUtils.dateOnly(DateTime.now());
          final snapshotStart = today.subtract(const Duration(days: 29));
          final snapshotOrders = data.orders
              .where((order) =>
                  order.contributesToSales &&
                  !order.placedAt.isBefore(snapshotStart))
              .toList();
          final snapshot = SalesSummary.fromOrders(snapshotOrders);
          childWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  'Last 30 days',
                  style: TextStyle(fontSize: 11, color: colors.mutedText),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: state.isExpanded ? 260 : 170,
                  child: SalesLineChart(
                    orders: snapshotOrders,
                    startDate: snapshotStart,
                    endDate: today,
                    isSales: true,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SnapshotMetric(
                        label: 'NET REVENUE',
                        value: _shortPeso(snapshot.netRevenue),
                      ),
                    ),
                    Expanded(
                      child: _SnapshotMetric(
                        label: 'ORDERS',
                        value: '${snapshot.totalOrders}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          break;

        case OverviewPanelId.topSellers:
          headerAction = Tooltip(
            message: 'View sales reports',
            child: OutlinedButton(
              onPressed: () => context.go('/sales-reports'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.secondaryText,
                backgroundColor: colors.hoverSurface,
                side: BorderSide(color: colors.subtleBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            ),
          );
          childWidget = _TopSellers(
            orders: data.orders
                .where((order) =>
                    order.contributesToSales &&
                    !order.placedAt.isBefore(
                      DateUtils.dateOnly(DateTime.now())
                          .subtract(const Duration(days: 29)),
                    ))
                .toList(),
            limit: state.isExpanded ? 6 : 3,
          );
          break;

        case OverviewPanelId.announcements:
          headerAction = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Announcement History',
                onPressed: () => context.go('/announcements'),
                icon: const Icon(Icons.history_rounded, size: 18),
              ),
              IconButton(
                tooltip: 'New Announcement',
                onPressed: () => showBlurredDialog(
                  context,
                  (context) => const AnnouncementDialog(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          );
          childWidget = data.announcements.isNotEmpty
              ? _Announcement(
                  announcement: data.announcements.first,
                  totalCount: data.announcements.length,
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 26,
                          color: colors.mutedText,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No active announcements',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
          break;
      }

      return _ResizablePanel(
        key: ValueKey(state.id),
        state: state,
        index: index,
        headerAction: headerAction,
        childWidget: childWidget,
        onReorder: _reorder,
        onStateChanged: () => setState(() {}),
      );
    }

    List<Widget> buildDashboardRows(bool isDesktop) {
      final widgets = <Widget>[];
      int i = 0;
      while (i < _panels.length) {
        final current = _panels[i];
        final isNextHalf =
            (i + 1 < _panels.length) && !_panels[i + 1].isFullWidth;

        if (!isDesktop || current.isFullWidth) {
          widgets.add(buildPanelWidget(current, i));
          widgets.add(const SizedBox(height: 18));
          i++;
        } else if (isNextHalf) {
          final next = _panels[i + 1];
          widgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildPanelWidget(current, i)),
                const SizedBox(width: 18),
                Expanded(child: buildPanelWidget(next, i + 1)),
              ],
            ),
          );
          widgets.add(const SizedBox(height: 18));
          i += 2;
        } else {
          widgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildPanelWidget(current, i)),
                const SizedBox(width: 18),
                const Expanded(child: SizedBox()),
              ],
            ),
          );
          widgets.add(const SizedBox(height: 18));
          i++;
        }
      }
      return widgets;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        final horizontalPad = Responsive.horizontalPadding(context);
        final isPhone = constraints.maxWidth < 600;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _OverviewHero(),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(horizontalPad, 18, horizontalPad, 12),
              child: isPhone
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCKABLE & RESIZABLE DASHBOARD',
                          style: GoogleFonts.inter(
                            color: colors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _resetLayout,
                          icon: Icon(
                            Icons.rotate_left_rounded,
                            size: 15,
                            color: colors.secondaryText,
                          ),
                          label: Text(
                            'Reset Layout',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.secondaryText,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.secondaryText,
                            backgroundColor: colors.hoverSurface,
                            side: BorderSide(color: colors.subtleBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          'DOCKABLE & RESIZABLE DASHBOARD',
                          style: GoogleFonts.inter(
                            color: colors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _resetLayout,
                          icon: Icon(
                            Icons.rotate_left_rounded,
                            size: 15,
                            color: colors.secondaryText,
                          ),
                          label: Text(
                            'Reset Layout',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.secondaryText,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.secondaryText,
                            backgroundColor: colors.hoverSurface,
                            side: BorderSide(color: colors.subtleBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: Column(
                children: buildDashboardRows(desktop),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _ResizablePanel extends StatelessWidget {
  const _ResizablePanel({
    super.key,
    required this.state,
    required this.index,
    required this.headerAction,
    required this.childWidget,
    required this.onReorder,
    required this.onStateChanged,
  });

  final _PanelState state;
  final int index;
  final Widget headerAction;
  final Widget childWidget;
  final void Function(int from, int to) onReorder;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);

    final headerButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerAction,
        const SizedBox(width: 6),
        Tooltip(
          message: state.isZoomed
              ? 'Collapse panel to default'
              : 'Expand / Zoom panel',
          child: InkWell(
            onTap: () {
              if (state.isZoomed) {
                state.isFullWidth = state.defaultFullWidth;
                state.isExpanded = state.defaultExpanded;
              } else {
                state.isFullWidth = true;
                state.isExpanded = true;
              }
              onStateChanged();
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.hoverSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.subtleBorder),
              ),
              child: Icon(
                state.isZoomed
                    ? Icons.close_fullscreen_rounded
                    : Icons.open_in_full_rounded,
                size: 16,
                color: colors.secondaryText,
              ),
            ),
          ),
        ),
      ],
    );

    final dragHandle = Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Opacity(
            opacity: 0.9,
            child: Transform.scale(
              scale: 1.02,
              child: DataPanel(
                title: state.title,
                titleStyle: GoogleFonts.inter(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                headerAction: headerAction,
                child: childWidget,
              ),
            ),
          ),
        ),
      ),
      child: Tooltip(
        message: 'Drag handle: Click and drag to reorder panel',
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: colors.hoverSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.subtleBorder),
            ),
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: colors.secondaryText,
            ),
          ),
        ),
      ),
    );

    final headerControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerButtons,
        const SizedBox(width: 6),
        dragHandle,
      ],
    );

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: DataPanel(
        title: state.title,
        titleStyle: GoogleFonts.inter(
          color: colors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        headerAction: headerControls,
        child: childWidget,
      ),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isHoveringTarget = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHoveringTarget
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFF10B981), width: 2.5),
                )
              : null,
          child: cardContent,
        );
      },
    );
  }
}

class _OverviewHero extends ConsumerWidget {
  const _OverviewHero();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminProfileProvider);
    final data = ref.watch(appDataProvider);
    final colors = semanticColors(context);
    // Keep the hero metrics on the same explicit period as Sales Overview.
    final today = DateUtils.dateOnly(DateTime.now());
    final salesWindowStart = today.subtract(const Duration(days: 29));
    final sales = SalesSummary.fromOrders(
      data.orders
          .where((order) =>
              order.contributesToSales &&
              !order.placedAt.isBefore(salesWindowStart)),
    );
    final activeVendors = data.vendors
        .where((vendor) => vendor.status == AccountStatus.active)
        .length;
    final activeCustomers = data.customers
        .where((customer) => customer.status == AccountStatus.active)
        .length;
    final pendingKyc = data.applications
        .where(
            (application) => application.status == ApplicationStatus.reviewing)
        .length;
    final metrics = [
      MetricCardData(
        value: '$activeVendors',
        label: 'Active Stall Holders',
        icon: Icons.storefront_rounded,
        accent: const Color(0xFF10B981),
        onTap: () => context.go('/accounts'),
      ),
      MetricCardData(
        value: '$pendingKyc',
        label: 'Pending KYC Requests',
        icon: Icons.assignment_outlined,
        accent: const Color(0xFFF59E0B),
        onTap: () => context.go('/applications'),
      ),
      MetricCardData(
        value: '${sales.totalOrders}',
        label: '30-Day Orders',
        icon: Icons.receipt_long_outlined,
        accent: const Color(0xFF3B82F6),
        onTap: () => context.go('/sales-reports'),
      ),
      MetricCardData(
        value: _shortPeso(sales.netRevenue),
        label: '30-Day Net Revenue',
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF059669),
        onTap: () => context.go('/sales-reports'),
      ),
      MetricCardData(
        value: '$activeCustomers',
        label: 'Active Customers',
        icon: Icons.people_outline_rounded,
        accent: const Color(0xFF3B82F6),
        onTap: () => context.go('/accounts?tab=customers'),
      ),
    ];
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Marhay na Aga,'
        : hour < 18
            ? 'Marhay na Hapon,'
            : 'Marhay na Banggi,';
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1080;
        final isPhone = constraints.maxWidth < 600;
        final horizontalPad = Responsive.horizontalPadding(context);

        final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            isPhone ? 16 : 26,
            horizontalPad,
            isPhone ? 18 : 24,
          ),
          decoration: BoxDecoration(
            color: colors.heroBackground,
            border: Border(
              bottom: BorderSide(color: colors.borderOnHero),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting.toUpperCase(),
                          style: TextStyle(
                            color: colors.heroMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.name,
                          style: GoogleFonts.plusJakartaSans(
                            color: colors.heroForeground,
                            fontSize: isPhone ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (desktop)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              PageHeaderMetricRibbon(metrics: metrics),
            ],
          ),
        );
      },
    );
  }
}

String _shortPeso(double value) {
  if (value >= 1000000) return '₱${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(1)}K';
  return '₱${value.toStringAsFixed(0)}';
}

String _fmtMoney(num value) => '₱${NumberFormat('#,##0.00').format(value)}';

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.mutedText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.primaryText,
          ),
        ),
      ],
    );
  }
}

class _ApprovalTable extends StatelessWidget {
  const _ApprovalTable({required this.items});
  final List<VendorApplication> items;
  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final rows = items
        .map(
          (item) => DataRow(
            onSelectChanged: (_) => showBlurredDialog(
              context,
              (context) => VerificationDialog.application(item),
            ),
            cells: [
              DataCell(Text(item.id)),
              DataCell(
                Row(
                  children: [
                    AvatarCircle(name: item.applicant, size: 25),
                    const SizedBox(width: 7),
                    Text(item.applicant),
                  ],
                ),
              ),
              DataCell(Text(item.stallName)),
              DataCell(CategoryBadge(category: item.category)),
              DataCell(
                ApplicationStatusBadge(status: item.status),
              ),
              DataCell(
                TableActionReviewButton(
                  tooltip: 'Review application ${item.id}',
                  onPressed: () => showBlurredDialog(
                    context,
                    (context) => VerificationDialog.application(item),
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStatePropertyAll(
                colors.tableHeader,
              ),
              headingTextStyle: GoogleFonts.inter(
                color: colors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
              dataTextStyle: GoogleFonts.inter(
                color: colors.primaryText,
                fontSize: 13,
              ),
              headingRowHeight: 44,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 64,
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('APPLICATION ID')),
                DataColumn(label: Text('APPLICANT')),
                DataColumn(label: Text('STALL NAME')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('VERIFICATION STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: rows,
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return colors.hoverSurface;
                }
                return colors.cardBackground;
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Announcement extends StatelessWidget {
  const _Announcement({required this.announcement, this.totalCount = 1});
  final Announcement announcement;
  final int totalCount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            InkWell(
              onTap: () => context.go('/announcements'),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: semanticColors(context).hoverSurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          label:
                              announcement.audience.toLowerCase() == 'vendors'
                                  ? 'Stall Holders'
                                  : announcement.audience,
                          kind: switch (announcement.audience.toLowerCase()) {
                            'vendors' || 'stall holders' => BadgeKind.info,
                            'customers' => BadgeKind.warning,
                            _ => BadgeKind.success,
                          },
                        ),
                        const Spacer(),
                        Text(
                          relativeTime(announcement.createdAt),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      announcement.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    FormattedText(
                      announcement.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: semanticColors(context).secondaryText,
                  backgroundColor: semanticColors(context).hoverSurface,
                  side: BorderSide(color: semanticColors(context).subtleBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => context.go('/announcements'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all history ($totalCount)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: semanticColors(context).secondaryText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: semanticColors(context).secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _TopSellers extends StatelessWidget {
  const _TopSellers({
    required this.orders,
    this.limit = 3,
  });

  final List<Order> orders;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);

    // Dynamic calculation from orders (matching sales report)
    final vendorMap = <String, (int count, double revenue)>{};
    for (final o in orders) {
      final current = vendorMap[o.vendorName] ?? (0, 0.0);
      vendorMap[o.vendorName] = (current.$1 + 1, current.$2 + o.total);
    }
    final sortedVendors = vendorMap.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    final count = sortedVendors.length.clamp(0, limit);

    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No seller records available',
            style: TextStyle(
              fontSize: 12,
              color: colors.mutedText,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: List.generate(
          count,
          (index) {
            final entry = sortedVendors[index];
            final sellerName = entry.key;
            final orderCount = entry.value.$1;
            final revenue = entry.value.$2;

            return Padding(
              padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarCircle(name: sellerName, size: 32),
                      Positioned(
                        right: -3,
                        top: -4,
                        child: Container(
                          width: 15,
                          height: 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.elevatedSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.subtleBorder,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$orderCount orders',
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtMoney(revenue),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revenue',
                        style: TextStyle(
                          fontSize: 9,
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

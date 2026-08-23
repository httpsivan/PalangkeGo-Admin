import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../core/animations/animated_widgets.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../announcements/announcement_dialog.dart';

enum OverviewPanelId { kyc, topSellers, announcements }

class _PanelState {
  _PanelState({
    required this.id,
    required this.title,
    this.isFullWidth = false,
    this.isExpanded = false,
  });

  final OverviewPanelId id;
  final String title;
  bool isFullWidth;
  bool isExpanded;
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
          headerAction = TextButton(
            onPressed: () => context.go('/applications'),
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                color: colors.mutedText,
                fontSize: 14,
              ),
            ),
          );
          childWidget = _ApprovalTable(
            items: data.applications
                .take(state.isExpanded ? 6 : 3)
                .toList(),
          );
          break;

        case OverviewPanelId.topSellers:
          headerAction = IconButton(
            onPressed: () => context.go('/sales-reports'),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
          );
          childWidget = _TopSellers(limit: state.isExpanded ? 6 : 3);
          break;

        case OverviewPanelId.announcements:
          headerAction = IconButton(
            onPressed: () => showBlurredDialog(
              context,
              (context) => const AnnouncementDialog(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
          );
          childWidget = data.announcements.isNotEmpty
              ? _Announcement(announcement: data.announcements.first)
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
        final isNextHalf = (i + 1 < _panels.length) && !_panels[i + 1].isFullWidth;

        if (!isDesktop || current.isFullWidth || !isNextHalf) {
          widgets.add(buildPanelWidget(current, i));
          widgets.add(const SizedBox(height: 18));
          i++;
        } else {
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
        }
      }
      return widgets;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _OverviewHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 20, 36, 12),
              child: Row(
                children: [
                  Text(
                    'DOCKABLE & RESIZABLE DASHBOARD (OPTION B)',
                    style: GoogleFonts.inter(
                      color: colors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetLayout,
                    icon: Icon(
                      Icons.rotate_left_rounded,
                      size: 16,
                      color: colors.secondaryText,
                    ),
                    label: Text(
                      'Reset Layout',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
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

class _ResizablePanel extends StatefulWidget {
  const _ResizablePanel({
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
  State<_ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<_ResizablePanel> {
  double _dragX = 0;
  double _dragY = 0;
  bool _isResizing = false;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);

    final headerControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.headerAction,
        const SizedBox(width: 6),
        Draggable<int>(
          data: widget.index,
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Opacity(
                opacity: 0.9,
                child: Transform.scale(
                  scale: 1.02,
                  child: DataPanel(
                    title: widget.state.title,
                    titleStyle: GoogleFonts.inter(
                      color: colors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    headerAction: widget.headerAction,
                    child: widget.childWidget,
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
        ),
      ],
    );

    final cardContent = Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: DataPanel(
            title: widget.state.title,
            titleStyle: GoogleFonts.inter(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            headerAction: headerControls,
            child: widget.childWidget,
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              setState(() {
                _dragX = 0;
                _dragY = 0;
                _isResizing = true;
              });
            },
            onPanUpdate: (details) {
              _dragX += details.delta.dx;
              _dragY += details.delta.dy;

              if (_dragX > 35 && !widget.state.isFullWidth) {
                widget.state.isFullWidth = true;
                _dragX = 0;
                widget.onStateChanged();
              } else if (_dragX < -35 && widget.state.isFullWidth) {
                widget.state.isFullWidth = false;
                _dragX = 0;
                widget.onStateChanged();
              }

              if (_dragY > 30 && !widget.state.isExpanded) {
                widget.state.isExpanded = true;
                _dragY = 0;
                widget.onStateChanged();
              } else if (_dragY < -30 && widget.state.isExpanded) {
                widget.state.isExpanded = false;
                _dragY = 0;
                widget.onStateChanged();
              }
            },
            onPanEnd: (_) {
              setState(() {
                _dragX = 0;
                _dragY = 0;
                _isResizing = false;
              });
            },
            child: Tooltip(
              message: 'Drag corner horizontally for width, vertically for height.\nClick to toggle width.',
              child: InkWell(
                onTap: () {
                  widget.state.isFullWidth = !widget.state.isFullWidth;
                  widget.onStateChanged();
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isResizing
                        ? const Color(0xFF10B981)
                        : colors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isResizing
                          ? const Color(0xFF059669)
                          : colors.subtleBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isResizing ? 0.15 : 0.06),
                        blurRadius: _isResizing ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.state.isFullWidth
                            ? Icons.view_column_outlined
                            : Icons.crop_square_rounded,
                        size: 13,
                        color: _isResizing ? Colors.white : colors.secondaryText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.state.isFullWidth ? 'SPAN 100%' : 'SPAN 50%',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: _isResizing ? Colors.white : colors.secondaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 11,
                        color: _isResizing ? Colors.white : colors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.index,
      onAcceptWithDetails: (details) => widget.onReorder(details.data, widget.index),
      builder: (context, candidateData, rejectedData) {
        final isHoveringTarget = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: isHoveringTarget
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981), width: 2.5),
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
    final sales = SalesSummary.fromOrders(data.orders);
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
    final overviewNumberStyle = GoogleFonts.montserrat(
      fontSize: 26,
      fontWeight: FontWeight.w800,
    );
    final metrics = [
      MetricCardData(
        value: '$activeVendors',
        label: 'Active Stall Holders',
        icon: Icons.storefront_rounded,
        accent: const Color(0xFF3B82F6),
        valueStyle: overviewNumberStyle,
        onTap: () => context.go('/accounts'),
      ),
      MetricCardData(
        value: '$pendingKyc',
        label: 'Pending KYC Requests',
        icon: Icons.assignment_outlined,
        accent: const Color(0xFFF59E0B),
        valueStyle: overviewNumberStyle,
        onTap: () => context.go('/applications'),
      ),
      MetricCardData(
        value: '${sales.totalOrders}',
        label: 'Total Orders',
        icon: Icons.shopping_bag_outlined,
        accent: const Color(0xFFEF4444),
        valueStyle: overviewNumberStyle,
      ),
      MetricCardData(
        value: _shortPeso(sales.netRevenue),
        label: 'Net Revenue',
        icon: Icons.payments_outlined,
        accent: const Color(0xFF10B981),
        valueStyle: overviewNumberStyle,
      ),
      MetricCardData(
        value: '$activeCustomers',
        label: 'Active Customers',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF8B5CF6),
        valueStyle: overviewNumberStyle,
        onTap: () => context.go('/accounts'),
      ),
    ];
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 18
            ? 'Good Afternoon,'
            : 'Good Evening,';
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1080;

        final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(36, 26, 36, 24),
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
                  Column(
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (desktop)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
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
              _ExecutiveMetricRibbon(metrics: metrics),
            ],
          ),
        );
      },
    );
  }
}

class _ExecutiveMetricRibbon extends StatelessWidget {
  const _ExecutiveMetricRibbon({required this.metrics});
  final List<MetricCardData> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (!isWide) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 550 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 80,
              ),
              itemBuilder: (context, i) => _ExecutiveMetricTile(data: metrics[i]),
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  Expanded(
                    child: _ExecutiveMetricTile(data: metrics[i]),
                  ),
                  if (i < metrics.length - 1)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colors.subtleBorder,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExecutiveMetricTile extends StatelessWidget {
  const _ExecutiveMetricTile({required this.data});
  final MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  data.icon,
                  size: 16,
                  color: data.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: data.value,
              style: GoogleFonts.plusJakartaSans(
                color: colors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortPeso(double value) {
  if (value >= 1000000) return '₱${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(1)}K';
  return '₱${value.toStringAsFixed(0)}';
}

class _ApprovalTable extends StatelessWidget {
  const _ApprovalTable({required this.items});
  final List<VendorApplication> items;
  @override
  Widget build(BuildContext context) {
    final rows = items
        .map(
          (item) => DataRow(
            onSelectChanged: (_) => context.go('/applications'),
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
              DataCell(StatusBadge(label: item.category, kind: BadgeKind.info)),
              DataCell(
                ApplicationStatusBadge(status: item.status),
              ),
            ],
          ),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(
              semanticColors(context).tableHeader,
            ),
            headingTextStyle: GoogleFonts.inter(
              color: semanticColors(context).secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            dataTextStyle: GoogleFonts.inter(
              color: semanticColors(context).primaryText,
              fontSize: 13,
            ),
            headingRowHeight: 48,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 68,
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(
                label: Text(
                  'APPLICATION ID',
                  style: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'APPLICANT',
                  style: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STALL NAME',
                  style: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'CATEGORY',
                  style: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: rows,
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return semanticColors(context).hoverSurface;
              }
              return semanticColors(context).cardBackground;
            }),
          ),
        ),
      ),
    );
  }
}

class _Announcement extends StatelessWidget {
  const _Announcement({required this.announcement});
  final Announcement announcement;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    label: announcement.audience,
                    kind: BadgeKind.success,
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
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                announcement.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5),
              ),
            ],
          ),
        ),
      );
}

class _TopSellers extends StatelessWidget {
  const _TopSellers({this.limit = 3});
  final int limit;

  @override
  Widget build(BuildContext context) {
    final count = limit.clamp(1, topSellerNames.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: List.generate(
          count,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarCircle(name: topSellerNames[index], size: 32),
                      Positioned(
                        right: -3,
                        top: -4,
                        child: Container(
                          width: 15,
                          height: 15,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: semanticColors(context).elevatedSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: semanticColors(context).subtleBorder,
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
                          topSellerNames[index],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topSellerOrders[index],
                          style: TextStyle(
                            fontSize: 9,
                            color: semanticColors(context).mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        topSellerRevenue[index],
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
                          color: semanticColors(context).mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

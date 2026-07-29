import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../announcements/announcement_dialog.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final colors = semanticColors(context);
    final action = DataPanel(
      title: 'Needs Action: KYC Approvals',
      titleStyle: GoogleFonts.inter(
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      headerAction: TextButton(
        onPressed: () => context.go('/applications'),
        child: Text(
          'View All',
          style: GoogleFonts.inter(
            color: colors.mutedText,
            fontSize: 14,
          ),
        ),
      ),
      child: _ApprovalTable(items: data.applications.take(3).toList()),
    );
    final announcements = DataPanel(
      title: 'ANNOUNCEMENTS',
      titleStyle: GoogleFonts.inter(
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      headerAction: IconButton(
        onPressed: () => showBlurredDialog(
          context,
          (context) => const AnnouncementDialog(),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
      ),
      child: _Announcement(announcement: data.announcements.first),
    );
    final topSellers = DataPanel(
      title: 'TOP SELLERS',
      titleStyle: GoogleFonts.inter(
        color: colors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      headerAction: IconButton(
        onPressed: () => context.go('/sales-reports'),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
      ),
      child: const _TopSellers(),
    );
    final side = Column(
      children: [topSellers, const SizedBox(height: 18), announcements],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 920;
        if (desktop && constraints.hasBoundedHeight) {
          return Column(
            children: [
              const _OverviewHero(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(34, 0, 34, 26),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 63,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: action,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 37,
                        child: Column(
                          children: [
                            topSellers,
                            const SizedBox(height: 18),
                            Expanded(child: announcements),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _OverviewHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 26),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 63, child: action),
                        const SizedBox(width: 18),
                        Expanded(flex: 37, child: side),
                      ],
                    )
                  : Column(
                      children: [action, const SizedBox(height: 18), side],
                    ),
            ),
          ],
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
    final pendingKyc = data.applications
        .where((application) => application.status == ApplicationStatus.reviewing)
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
        value: '${data.customers.length}',
        label: 'Registered Customers',
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
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                color: colors.heroMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile.name,
              style: GoogleFonts.montserrat(
                color: colors.heroForeground,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
        final metricGrid = GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: desktop
                ? 5
                : constraints.maxWidth >= 650
                    ? 2
                    : 1,
            crossAxisSpacing: desktop ? 20 : 16,
            mainAxisSpacing: 12,
            mainAxisExtent: desktop ? 146 : 116,
          ),
          itemBuilder: (context, index) => MetricCard(data: metrics[index]),
        );

        if (!desktop) {
          return Container(
            color: semanticColors(context).heroBackground,
            padding: const EdgeInsets.fromLTRB(34, 21, 34, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 40),
                metricGrid,
              ],
            ),
          );
        }

        return SizedBox(
          height: 313,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: 162,
                color: semanticColors(context).heroBackground,
                padding: const EdgeInsets.fromLTRB(34, 21, 34, 18),
                child: intro,
              ),
              Positioned(
                top: 135,
                left: 34,
                right: 34,
                child: SizedBox(height: 146, child: metricGrid),
              ),
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

class _ApprovalTable extends StatelessWidget {
  const _ApprovalTable({required this.items});
  final List<dynamic> items;
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
        child: SizedBox(
          width: constraints.maxWidth,
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
                columnWidth: FlexColumnWidth(1.2),
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
                columnWidth: FlexColumnWidth(1.35),
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
                columnWidth: FlexColumnWidth(1.65),
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
                columnWidth: FlexColumnWidth(1.1),
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
                columnWidth: FlexColumnWidth(1.1),
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
  final dynamic announcement;
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
  const _TopSellers();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 16),
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

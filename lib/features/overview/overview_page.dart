import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/mock_repository.dart';
import '../announcements/announcement_dialog.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final action = DataPanel(
      title: 'Needs Action: KYC Approvals',
      headerAction: TextButton(
        onPressed: () => context.go('/applications'),
        child: const Text('View All'),
      ),
      child: _ApprovalTable(items: data.applications.take(3).toList()),
    );
    final side = Column(
      children: [
        DataPanel(
          title: 'ANNOUNCEMENTS',
          headerAction: IconButton(
            onPressed: () => showBlurredDialog(
              context,
              (context) => const AnnouncementDialog(),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
          child: _Announcement(announcement: data.announcements.first),
        ),
        const SizedBox(height: 18),
        DataPanel(
          title: 'TOP SELLERS',
          headerAction: IconButton(
            onPressed: () => context.go('/reports'),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
          ),
          child: const _TopSellers(),
        ),
      ],
    );
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _OverviewHero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(34, 18, 34, 26),
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 920
                ? Column(children: [action, const SizedBox(height: 18), side])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 63, child: action),
                      const SizedBox(width: 18),
                      Expanded(flex: 37, child: side),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero();
  @override
  Widget build(BuildContext context) {
    final metrics = [
      MetricCardData(
        value: '1,284',
        label: 'Active Stall Holders',
        icon: Icons.storefront_rounded,
        accent: const Color(0xFF3B82F6),
        onTap: () => context.go('/accounts'),
      ),
      MetricCardData(
        value: '42',
        label: 'Pending KYC Requests',
        icon: Icons.assignment_outlined,
        accent: const Color(0xFFF59E0B),
        onTap: () => context.go('/applications'),
      ),
      const MetricCardData(
        value: '₱84,200',
        label: 'Outstanding Balances',
        icon: Icons.warning_amber_rounded,
        accent: Color(0xFFEF4444),
      ),
      const MetricCardData(
        value: '₱2.48M',
        label: 'Total Collection (Rent)',
        icon: Icons.payments_outlined,
        accent: Color(0xFF10B981),
      ),
      MetricCardData(
        value: '22',
        label: 'New Users',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF8B5CF6),
        onTap: () => context.go('/accounts'),
      ),
    ];
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 18
        ? 'Good Afternoon,'
        : 'Good Evening,';
    return Container(
      color: semanticColors(context).heroBackground,
      padding: const EdgeInsets.fromLTRB(34, 21, 34, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              color: Colors.white.withOpacity(.62),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Kirren Michael Fraginal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 1080
                  ? 5
                  : constraints.maxWidth >= 650
                  ? 2
                  : 1;
              return GridView.builder(
                itemCount: metrics.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 136,
                ),
                itemBuilder: (context, index) =>
                    MetricCard(data: metrics[index]),
              );
            },
          ),
        ],
      ),
    );
  }
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
                StatusBadge(
                  label: item.status.toString().split('.').last,
                  kind: BadgeKind.info,
                ),
              ),
            ],
          ),
        )
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          semanticColors(context).tableHeader,
        ),
        columns: const [
          DataColumn(label: Text('APPLICATION ID')),
          DataColumn(label: Text('APPLICANT')),
          DataColumn(label: Text('STALL NAME')),
          DataColumn(label: Text('CATEGORY')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: rows,
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            announcement.summary,
            maxLines: 2,
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
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
    child: Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: Row(
            children: [
              AvatarCircle(name: topSellerNames[index], size: 32),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  topSellerNames[index],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                topSellerRevenue[index],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

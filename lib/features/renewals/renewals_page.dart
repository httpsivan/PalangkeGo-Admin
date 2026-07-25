import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String status = 'All Statuses';
  int page = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final values = data.renewals
        .where(
          (v) =>
              (search.text.isEmpty ||
                  '${v.id} ${v.applicant} ${v.stallName}'
                      .toLowerCase()
                      .contains(search.text.toLowerCase())) &&
              (status == 'All Statuses' || _status(v.status) == status),
        )
        .toList();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 30),
            child: DataPanel(
              title: 'Renewal',
              child: Column(
                children: [
                  Toolbar(
                    controller: search,
                    onChanged: (_) => setState(() => page = 0),
                    onClear: () => setState(() {
                      search.clear();
                      status = 'All Statuses';
                    }),
                    trailing: [
                      _filter(context, status, [
                        'All Statuses',
                        'Approved',
                        'Reviewing',
                        'Expired',
                      ], (v) => setState(() => status = v)),
                      FilterButton(label: 'Stall Category'),
                      FilterButton(
                        label: 'Export',
                        icon: Icons.download_outlined,
                      ),
                    ],
                  ),
                  _Table(
                    values: values.skip(page * 10).take(10).toList(),
                    open: (v) => showBlurredDialog(
                      context,
                      (context) => VerificationDialog.renewal(v),
                    ),
                  ),
                  if (values.isNotEmpty)
                    PaginationBar(
                      total: values.length,
                      start: page * 10 + 1,
                      end: ((page + 1) * 10).clamp(0, values.length),
                      page: page,
                      pageCount: (values.length / 10).ceil(),
                      onPageChanged: (v) => setState(() => page = v),
                    )
                  else
                    const EmptyState(),
                ],
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
  ) => FilterButton(
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
  String _status(RenewalStatus value) => switch (value) {
    RenewalStatus.approved => 'Approved',
    RenewalStatus.reviewing => 'Reviewing',
    RenewalStatus.expired => 'Expired',
  };
}

class _Table extends StatelessWidget {
  const _Table({required this.values, required this.open});
  final List<RenewalRequest> values;
  final ValueChanged<RenewalRequest> open;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
        DataColumn(label: Text('EXPIRY DATE')),
        DataColumn(label: Text('KYC STATUS')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: values.map((v) {
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
      }).toList(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  final search = TextEditingController();
  final scrollController = ScrollController();
  AuditAction? action;
  String entity = 'All entities';
  int page = 0;

  @override
  void dispose() {
    search.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final entities = <String>{
      'All entities',
      ...data.auditLogs.map((item) => item.targetEntityType),
    }.toList();
    final values = data.auditLogs.where((item) {
      final query = search.text.trim().toLowerCase();
      final text =
          '${item.id} ${item.administratorName} ${item.targetUserName} ${item.targetEntityId} ${item.reason}'
              .toLowerCase();
      return (query.isEmpty || text.contains(query)) &&
          (action == null || item.action == action) &&
          (entity == 'All entities' || item.targetEntityType == entity);
    }).toList();
    final totalPages = (values.length / 15).ceil();
    final safePage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    final visible = values.skip(safePage * 15).take(15).toList();
    return Column(
      children: [
        PageHeader(
          title: 'Admin Audit Log',
          subtitle:
              'Immutable local activity history for sensitive administrator actions.',
          metrics: [
            MetricCardData(
                value: '${data.auditLogs.length}',
                label: 'Recorded Actions',
                icon: Icons.history_rounded,
                accent: const Color(0xFF3B82F6)),
            MetricCardData(
                value:
                    '${data.auditLogs.where((item) => item.action == AuditAction.approveKyc || item.action == AuditAction.rejectKyc).length}',
                label: 'KYC Actions',
                icon: Icons.verified_user_outlined,
                accent: const Color(0xFF10B981)),
            MetricCardData(
                value:
                    '${data.auditLogs.where((item) => item.action == AuditAction.blockAccount || item.action == AuditAction.suspendAccount).length}',
                label: 'Account Controls',
                icon: Icons.shield_outlined,
                accent: const Color(0xFFF59E0B)),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 22, 30, 26),
            child: DataPanel(
              title: 'Activity History',
              headerAction: FilterButton(
                  label: 'Export CSV',
                  icon: Icons.download_outlined,
                  onTap: () => _export(values)),
              child: Expanded(
                child: Column(
                  children: [
                    Toolbar(
                      controller: search,
                      searchHint:
                          'Search administrator, action, target, or reason...',
                      onChanged: (_) => setState(() => page = 0),
                      onClear: () => setState(() {
                        search.clear();
                        action = null;
                        entity = 'All entities';
                        page = 0;
                      }),
                      trailing: [
                        FilterMenuButton(
                          label: action == null
                              ? 'All Actions'
                              : enumLabel(action!),
                          values: [
                            'All Actions',
                            ...AuditAction.values.map(enumLabel),
                          ],
                          onSelected: (value) => setState(() {
                            action = value == 'All Actions'
                                ? null
                                : AuditAction.values.firstWhere(
                                    (item) => enumLabel(item) == value,
                                  );
                            page = 0;
                          }),
                        ),
                        FilterMenuButton(
                          label: entity,
                          values: entities,
                          onSelected: (value) => setState(() {
                            entity = value;
                            page = 0;
                          }),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ScrollableDataTable(
                        columns: const [
                          DataColumn(label: Text('TIMESTAMP')),
                          DataColumn(label: Text('ADMINISTRATOR')),
                          DataColumn(label: Text('ACTION')),
                          DataColumn(label: Text('TARGET')),
                          DataColumn(label: Text('PREVIOUS')),
                          DataColumn(label: Text('NEW VALUE')),
                          DataColumn(label: Text('REASON')),
                        ],
                        rows: visible
                            .map((item) => DataRow(
                                  onSelectChanged: (_) => _showDetails(item),
                                  cells: [
                                    DataCell(
                                        Text(longDate.format(item.timestamp))),
                                    DataCell(Text(item.administratorName)),
                                    DataCell(StatusBadge(
                                        label: enumLabel(item.action),
                                        kind: BadgeKind.info)),
                                    DataCell(Text(
                                        '${item.targetEntityType} / ${item.targetUserName}')),
                                    DataCell(Text(item.previousValue)),
                                    DataCell(Text(item.newValue)),
                                    DataCell(Text(
                                        item.reason.isEmpty ? '—' : item.reason,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                  ],
                                ))
                            .toList(),
                        verticalController: scrollController,
                        minWidth: 1120,
                        emptyState: const EmptyState(
                            message: 'No audit entries match these filters.'),
                      ),
                    ),
                    if (values.isNotEmpty)
                      PaginationBar(
                        total: values.length,
                        start: safePage * 15 + 1,
                        end: ((safePage + 1) * 15).clamp(0, values.length),
                        page: safePage,
                        pageCount: totalPages,
                        onPageChanged: (value) => setState(() => page = value),
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

  void _export(List<AuditLog> values) {
    final csv = buildCsv([
      [
        'Audit ID',
        'Administrator',
        'Action',
        'Entity Type',
        'Entity ID',
        'Target User',
        'Previous',
        'New Value',
        'Reason',
        'Timestamp'
      ],
      ...values.map((item) => item.toRow()),
    ]);
    downloadCsv(csv, 'palengkego-admin-audit-log.csv');
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Audit log exported.')));
  }

  Future<void> _showDetails(AuditLog item) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(enumLabel(item.action)),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Audit ID', item.id),
                _detail('Administrator',
                    '${item.administratorName} (${item.administratorId})'),
                _detail('Target',
                    '${item.targetEntityType} / ${item.targetEntityId}'),
                _detail('Target user', item.targetUserName),
                _detail('Previous value', item.previousValue),
                _detail('New value', item.newValue),
                for (final entry in item.metadata.entries)
                  _detail(enumLabel(entry.key), entry.value),
                _detail('Reason', item.reason.isEmpty ? '—' : item.reason),
                _detail('Timestamp', longDate.format(item.timestamp)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

import 'package:flutter/material.dart';

/// Common data models for PalengkeGo PDF and Excel exports.
class ReportHeader {
  const ReportHeader({
    this.organization = 'PalengkeGo Market',
    required this.reportTitle,
    required this.exportDate,
    this.dateRange,
    required this.activeFilters,
  });

  final String organization;
  final String reportTitle;
  final DateTime exportDate;
  final String? dateRange;
  final String activeFilters;
}

class ReportSummaryItem {
  const ReportSummaryItem({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;
}

class ReportSummary {
  const ReportSummary({
    this.title = 'REPORT SUMMARY',
    required this.items,
  });

  final String title;
  final List<ReportSummaryItem> items;
}

class ReportColumn {
  const ReportColumn({
    required this.label,
    this.flex = 1.0,
    this.isNumeric = false,
  });

  final String label;
  final double flex;
  final bool isNumeric;
}

class ReportRow {
  const ReportRow({
    required this.cells,
    this.statusColor,
  });

  final List<Object?> cells;
  final Color? statusColor;
}

class ReportTable {
  const ReportTable({
    required this.columns,
    required this.rows,
  });

  final List<ReportColumn> columns;
  final List<ReportRow> rows;
}

class ExportDocument {
  const ExportDocument({
    required this.filenamePrefix,
    required this.reportName,
    required this.header,
    required this.summary,
    required this.table,
    this.historyRows,
  });

  final String filenamePrefix;
  final String reportName;
  final ReportHeader header;
  final ReportSummary summary;
  final ReportTable table;
  final List<ReportRow>? historyRows;
}

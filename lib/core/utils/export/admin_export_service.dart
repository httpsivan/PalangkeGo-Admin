import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mock_repository.dart';
import '../../../models/admin_models.dart';
import '../platform_file_saver.dart';
import 'admin_export_models.dart';
import 'excel_report_service.dart';
import 'export_filename_service.dart';
import 'pdf_report_service.dart';

enum ExportFormat { pdf, excel }

class AdminExportService {
  AdminExportService._();

  static Future<void> export({
    required BuildContext context,
    required WidgetRef ref,
    required ExportDocument doc,
    required ExportFormat format,
  }) async {
    final Uint8List bytes;
    final String filename;
    final String mimeType;
    final AuditAction auditAction;

    if (format == ExportFormat.pdf) {
      bytes = PdfReportService.generatePdf(doc);
      filename = ExportFilenameService.generateFilename(
        prefix: doc.filenamePrefix,
        extension: 'pdf',
        timestamp: doc.header.exportDate,
      );
      mimeType = 'application/pdf';
      auditAction = AuditAction.exportPdf;
    } else {
      bytes = ExcelReportService.generateExcel(doc);
      filename = ExportFilenameService.generateFilename(
        prefix: doc.filenamePrefix,
        extension: 'xlsx',
        timestamp: doc.header.exportDate,
      );
      mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      auditAction = AuditAction.exportExcel;
    }

    await saveFileBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    // Record audit event in immutable audit log
    await ref.read(appDataProvider.notifier).recordAudit(
          action: auditAction,
          targetEntityType: doc.reportName,
          targetEntityId: doc.filenamePrefix,
          targetUserName: 'System',
          previousValue: '',
          newValue:
              '${doc.table.rows.length} records (${doc.header.activeFilters})',
        );

    if (context.mounted) {
      final formatLabel = format == ExportFormat.pdf ? 'PDF' : 'Excel';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${doc.reportName} $formatLabel report exported successfully.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

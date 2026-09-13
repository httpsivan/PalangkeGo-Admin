import 'package:intl/intl.dart';

class ExportFilenameService {
  ExportFilenameService._();

  static final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd_HHmmss');

  static String generateFilename({
    required String prefix,
    required String extension,
    DateTime? timestamp,
  }) {
    final timeStr = _timestampFormat.format(timestamp ?? DateTime.now());
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '${prefix}_$timeStr.$ext';
  }

  static const String accountsPrefix = 'palengkego_accounts_report';
  static const String applicationsPrefix =
      'palengkego_stall_holder_application_report';
  static const String renewalsPrefix = 'palengkego_renewal_report';
  static const String complaintsPrefix = 'palengkego_complaints_report';
  static const String announcementsPrefix = 'palengkego_announcements_report';
  static const String auditLogPrefix = 'palengkego_admin_audit_log';
}

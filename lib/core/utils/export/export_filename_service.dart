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
  static const String stallHolderAccountsPrefix =
      'palengkego_stall_holder_accounts_report';
  static const String customerAccountsPrefix =
      'palengkego_customer_accounts_report';
  static const String applicationsPrefix =
      'palengkego_stall_holder_application_report';
  static const String renewalsPrefix = 'palengkego_renewal_report';
  static const String complaintsPrefix = 'palengkego_complaints_report';
  static const String stallHolderComplaintsPrefix =
      'palengkego_stall_holder_complaints_report';
  static const String customerComplaintsPrefix =
      'palengkego_customer_complaints_report';
  static const String announcementsPrefix = 'palengkego_announcements_report';
  static const String stallHolderAnnouncementsPrefix =
      'palengkego_stall_holder_announcements_report';
  static const String customerAnnouncementsPrefix =
      'palengkego_customer_announcements_report';
  static const String auditLogPrefix = 'palengkego_admin_audit_log';
  static const String salesPrefix = 'palengkego_sales_report';
}

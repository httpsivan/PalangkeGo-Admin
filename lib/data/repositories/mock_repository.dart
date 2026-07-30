import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../mock_data.dart';
import '../../core/theme/theme_controller.dart';

const defaultAdminName = 'Kirren Michael Fraginal';
const defaultAdminEmail = 'admin@palengkego.gov.ph';
const defaultAdminPassword = 'Admin123!';

class AdminProfile {
  const AdminProfile({
    required this.name,
    required this.email,
    required this.password,
    this.avatarBytes,
  });

  final String name;
  final String email;
  final String password;
  final Uint8List? avatarBytes;

  AdminProfile copyWith({
    String? name,
    String? password,
    Uint8List? avatarBytes,
  }) =>
      AdminProfile(
        name: name ?? this.name,
        email: email,
        password: password ?? this.password,
        avatarBytes: avatarBytes ?? this.avatarBytes,
      );
}

Uint8List? _readAdminAvatar(SharedPreferences preferences) {
  final encoded = preferences.getString('admin_avatar');
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } on FormatException {
    return null;
  }
}

final adminProfileProvider =
    StateNotifierProvider<AdminProfileController, AdminProfile>((ref) {
  return AdminProfileController(ref.watch(sharedPreferencesProvider));
});

class AdminProfileController extends StateNotifier<AdminProfile> {
  AdminProfileController(this._preferences)
      : super(
          AdminProfile(
            name: _preferences.getString('admin_name') ?? defaultAdminName,
            email: defaultAdminEmail,
            password: _preferences.getString('admin_password') ??
                defaultAdminPassword,
            avatarBytes: _readAdminAvatar(_preferences),
          ),
        );

  final SharedPreferences _preferences;

  Future<void> updateProfile({
    required String name,
    String? password,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) async {
    final nextPassword = password == null || password.trim().isEmpty
        ? state.password
        : password.trim();
    final nextAvatar = removeAvatar ? null : avatarBytes ?? state.avatarBytes;
    state = AdminProfile(
      name: name.trim(),
      email: state.email,
      password: nextPassword,
      avatarBytes: nextAvatar,
    );
    await _preferences.setString('admin_name', state.name);
    await _preferences.setString('admin_password', state.password);
    if (nextAvatar == null) {
      await _preferences.remove('admin_avatar');
    } else {
      await _preferences.setString('admin_avatar', base64Encode(nextAvatar));
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref.watch(sharedPreferencesProvider));
});

class AuthController extends StateNotifier<bool> {
  AuthController(this._preferences)
      : super(_preferences.getBool('isLoggedIn') ?? false);

  final SharedPreferences _preferences;

  Future<String?> login(
    String email,
    String password,
    bool keepSignedIn,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final savedPassword =
        _preferences.getString('admin_password') ?? defaultAdminPassword;
    if (email.trim().toLowerCase() != defaultAdminEmail ||
        password != savedPassword) {
      return 'The email or password is incorrect.';
    }
    state = true;
    await _preferences.setBool('isLoggedIn', keepSignedIn);
    await _appendAuthAudit(_preferences, AuditAction.login);
    return null;
  }

  Future<void> logout() async {
    await _appendAuthAudit(_preferences, AuditAction.logout);
    state = false;
    await _preferences.remove('isLoggedIn');
  }
}

class AppDataState {
  const AppDataState({
    required this.vendors,
    required this.customers,
    required this.applications,
    required this.renewals,
    required this.reports,
    required this.announcements,
    this.orders = const [],
    this.suspensions = const [],
    this.auditLogs = const [],
  });

  final List<Vendor> vendors;
  final List<Customer> customers;
  final List<VendorApplication> applications;
  final List<RenewalRequest> renewals;
  final List<Report> reports;
  final List<Announcement> announcements;
  final List<Order> orders;
  final List<Suspension> suspensions;
  final List<AuditLog> auditLogs;

  AppDataState copyWith({
    List<Vendor>? vendors,
    List<Customer>? customers,
    List<VendorApplication>? applications,
    List<RenewalRequest>? renewals,
    List<Report>? reports,
    List<Announcement>? announcements,
    List<Order>? orders,
    List<Suspension>? suspensions,
    List<AuditLog>? auditLogs,
  }) {
    return AppDataState(
      vendors: vendors ?? this.vendors,
      customers: customers ?? this.customers,
      applications: applications ?? this.applications,
      renewals: renewals ?? this.renewals,
      reports: reports ?? this.reports,
      announcements: announcements ?? this.announcements,
      orders: orders ?? this.orders,
      suspensions: suspensions ?? this.suspensions,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

final appDataProvider = StateNotifierProvider<AppDataController, AppDataState>((
  ref,
) {
  return AppDataController(ref.watch(sharedPreferencesProvider));
});

class AppDataController extends StateNotifier<AppDataState> {
  AppDataController(this._preferences)
      : super(
          AppDataState(
            vendors: seedVendors(),
            customers: seedCustomers(),
            applications: seedApplications(),
            renewals: seedRenewals(),
            reports: seedReports(),
            announcements: seedAnnouncements(),
            orders: seedOrders(),
          ),
        ) {
    _restore();
  }

  final SharedPreferences _preferences;

  Future<void> _restore() async {
    final blockedVendors =
        _preferences.getStringList('blocked_vendors') ?? <String>[];
    final blockedCustomers =
        _preferences.getStringList('blocked_customers') ?? <String>[];
    final unblockedVendors =
        _preferences.getStringList('unblocked_vendors') ?? <String>[];
    final unblockedCustomers =
        _preferences.getStringList('unblocked_customers') ?? <String>[];
    final vendorIds = blockedVendors.toSet();
    final customerIds = blockedCustomers.toSet();
    final unblockedVendorIds = unblockedVendors.toSet();
    final unblockedCustomerIds = unblockedCustomers.toSet();
    final storedAudits = _readAuditLogs();
    final storedSuspensions = _readSuspensions();
    final activeSuspensionIds = storedSuspensions
        .where((item) => item.isActive)
        .map((item) => item.accountId)
        .toSet();
    state = state.copyWith(
      vendors: state.vendors
          .map(
            (vendor) => vendorIds.contains(vendor.id)
                ? vendor.copyWith(status: AccountStatus.blocked)
                : activeSuspensionIds.contains(vendor.id)
                    ? vendor.copyWith(status: AccountStatus.suspended)
                    : unblockedVendorIds.contains(vendor.id)
                        ? vendor.copyWith(status: AccountStatus.active)
                        : vendor,
          )
          .toList(),
      customers: state.customers
          .map(
            (customer) => customerIds.contains(customer.id)
                ? customer.copyWith(status: AccountStatus.blocked)
                : activeSuspensionIds.contains(customer.id)
                    ? customer.copyWith(status: AccountStatus.suspended)
                    : unblockedCustomerIds.contains(customer.id)
                        ? customer.copyWith(status: AccountStatus.active)
                        : customer,
          )
          .toList(),
      auditLogs: storedAudits,
      suspensions: storedSuspensions,
    );
    await _expireSuspensions();
  }

  Future<void> setVendorStatus(String id, AccountStatus status) async {
    await _wait();
    final previous = _firstOrNull(state.vendors.where((item) => item.id == id));
    final vendors = state.vendors
        .map(
          (vendor) =>
              vendor.id == id ? vendor.copyWith(status: status) : vendor,
        )
        .toList();
    state = state.copyWith(vendors: vendors);
    final blocked = vendors
        .where((vendor) => vendor.status == AccountStatus.blocked)
        .map((vendor) => vendor.id)
        .toList();
    await _preferences.setStringList('blocked_vendors', blocked);
    await _updateUnblockedOverride(
      key: 'unblocked_vendors',
      id: id,
      status: status,
    );
    await recordAudit(
      action: status == AccountStatus.blocked
          ? AuditAction.blockAccount
          : status == AccountStatus.active
              ? AuditAction.unblockAccount
              : AuditAction.editAccountStatus,
      targetEntityType: 'Vendor',
      targetEntityId: id,
      targetUserName: previous?.name ?? id,
      previousValue: enumLabel(previous?.status ?? AccountStatus.active),
      newValue: enumLabel(status),
    );
  }

  Future<void> updateVendorAccount(
    String id, {
    required AccountStatus status,
    required String administrativeNotes,
  }) async {
    await _wait();
    final previous = _firstOrNull(state.vendors.where((item) => item.id == id));
    final vendors = state.vendors
        .map(
          (vendor) => vendor.id == id
              ? vendor.copyWith(
                  status: status,
                  administrativeNotes: administrativeNotes,
                )
              : vendor,
        )
        .toList();
    state = state.copyWith(vendors: vendors);
    final blocked = vendors
        .where((vendor) => vendor.status == AccountStatus.blocked)
        .map((vendor) => vendor.id)
        .toList();
    await _preferences.setStringList('blocked_vendors', blocked);
    await _updateUnblockedOverride(
      key: 'unblocked_vendors',
      id: id,
      status: status,
    );
    await recordAudit(
      action: status == AccountStatus.blocked
          ? AuditAction.blockAccount
          : status == AccountStatus.active
              ? AuditAction.unblockAccount
              : AuditAction.editAccountStatus,
      targetEntityType: 'Vendor',
      targetEntityId: id,
      targetUserName: previous?.name ?? id,
      previousValue: enumLabel(previous?.status ?? AccountStatus.active),
      newValue: enumLabel(status),
      reason: administrativeNotes,
    );
  }

  Future<void> updateCustomerAccount(
    String id, {
    required AccountStatus status,
    required String administrativeNotes,
  }) async {
    await _wait();
    final previous =
        _firstOrNull(state.customers.where((item) => item.id == id));
    state = state.copyWith(
      customers: state.customers
          .map(
            (customer) => customer.id == id
                ? customer.copyWith(
                    status: status,
                    administrativeNotes: administrativeNotes,
                  )
                : customer,
          )
          .toList(),
    );
    final blockedCustomers = state.customers
        .where((item) => item.status == AccountStatus.blocked)
        .map((item) => item.id)
        .toList();
    await _preferences.setStringList('blocked_customers', blockedCustomers);
    await _updateUnblockedOverride(
      key: 'unblocked_customers',
      id: id,
      status: status,
    );
    await recordAudit(
      action: status == AccountStatus.blocked
          ? AuditAction.blockAccount
          : status == AccountStatus.active
              ? AuditAction.unblockAccount
              : AuditAction.editAccountStatus,
      targetEntityType: 'Customer',
      targetEntityId: id,
      targetUserName: previous?.name ?? id,
      previousValue: enumLabel(previous?.status ?? AccountStatus.active),
      newValue: enumLabel(status),
      reason: administrativeNotes,
    );
  }

  Future<void> _updateUnblockedOverride({
    required String key,
    required String id,
    required AccountStatus status,
  }) async {
    final ids = {
      ...?_preferences.getStringList(key),
    };
    if (status == AccountStatus.active) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    await _preferences.setStringList(key, ids.toList()..sort());
  }

  Future<void> updateApplication(
    String id,
    ApplicationStatus status, {
    String? rejectionReason,
  }) async {
    await _wait();
    final current = _firstOrNull(
      state.applications.where((item) => item.id == id),
    );
    final reviewedAt = DateTime.now();
    state = state.copyWith(
      applications: state.applications
          .map(
            (item) => item.id == id
                ? item.copyWith(
                    status: status,
                    rejectionReason: rejectionReason,
                    reviewedAt: reviewedAt,
                    reviewedBy: 'ADM-001',
                  )
                : item,
          )
          .toList(),
    );
    await recordAudit(
      action: status == ApplicationStatus.verified
          ? AuditAction.approveKyc
          : AuditAction.rejectKyc,
      targetEntityType: 'KYC Submission',
      targetEntityId: id,
      targetUserName: current?.applicant ?? id,
      previousValue: enumLabel(current?.status ?? ApplicationStatus.reviewing),
      newValue: enumLabel(status),
      reason: rejectionReason ?? '',
    );
  }

  Future<void> updateRenewal(String id, RenewalStatus status) async {
    await _wait();
    state = state.copyWith(
      renewals: state.renewals
          .map((item) => item.id == id ? item.copyWith(status: status) : item)
          .toList(),
    );
    await recordAudit(
      action: AuditAction.editAccountStatus,
      targetEntityType: 'Renewal',
      targetEntityId: id,
      targetUserName: id,
      previousValue: 'unknown',
      newValue: enumLabel(status),
    );
  }

  Future<void> updateReport(
    String id,
    ReportStatus status,
    String notes,
  ) async {
    await _wait();
    state = state.copyWith(
      reports: state.reports
          .map(
            (item) => item.id == id
                ? item.copyWith(status: status, notes: notes)
                : item,
          )
          .toList(),
    );
    await _preferences.setString('report_notes_$id', notes);
    await recordAudit(
      action: AuditAction.editAccountStatus,
      targetEntityType: 'Report',
      targetEntityId: id,
      targetUserName: id,
      previousValue: 'unknown',
      newValue: enumLabel(status),
      reason: notes,
    );
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    await _wait();
    state = state.copyWith(
      announcements: [announcement, ...state.announcements],
    );
    await _preferences.setString('last_announcement', announcement.title);
    await recordAudit(
      action: AuditAction.sendAnnouncement,
      targetEntityType: 'Announcement',
      targetEntityId:
          announcement.id.isEmpty ? announcement.title : announcement.id,
      targetUserName: announcement.audience,
      previousValue: '',
      newValue: announcement.title,
    );
  }

  Future<String?> createSuspension({
    required String accountId,
    required String accountName,
    required String accountType,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    required String note,
    required bool notifyUser,
  }) async {
    if (reason.trim().isEmpty) return 'A suspension reason is required.';
    if (!endDate.isAfter(startDate)) {
      return 'The suspension end date must be after the start date.';
    }
    if (endDate.isBefore(DateTime.now())) {
      return 'The suspension cannot end in the past.';
    }
    if (state.suspensions
        .any((item) => item.accountId == accountId && item.isActive)) {
      return 'This account already has an active suspension.';
    }
    final suspension = Suspension(
      id: 'SUS-${DateTime.now().millisecondsSinceEpoch}',
      accountId: accountId,
      accountName: accountName,
      accountType: accountType,
      reason: reason.trim(),
      startDate: startDate,
      endDate: endDate,
      administratorId: 'ADM-001',
      createdAt: DateTime.now(),
      note: note.trim(),
      notifyUser: notifyUser,
    );
    state = state.copyWith(
      suspensions: [suspension, ...state.suspensions],
      vendors: state.vendors
          .map((item) => item.id == accountId
              ? item.copyWith(status: AccountStatus.suspended)
              : item)
          .toList(),
      customers: state.customers
          .map((item) => item.id == accountId
              ? item.copyWith(status: AccountStatus.suspended)
              : item)
          .toList(),
    );
    await _persistSuspensions();
    await recordAudit(
      action: AuditAction.suspendAccount,
      targetEntityType: accountType,
      targetEntityId: accountId,
      targetUserName: accountName,
      previousValue: 'Active',
      newValue: 'Suspended',
      reason: reason,
      metadata: {'endDate': endDate.toIso8601String()},
    );
    return null;
  }

  Future<String?> liftSuspension(String suspensionId) async {
    final current = _firstOrNull(
      state.suspensions.where((item) => item.id == suspensionId),
    );
    if (current == null) return 'Suspension not found.';
    final lifted = current.lift(DateTime.now());
    state = state.copyWith(
      suspensions: state.suspensions
          .map((item) => item.id == suspensionId ? lifted : item)
          .toList(),
      vendors: state.vendors
          .map((item) => item.id == current.accountId
              ? item.copyWith(status: AccountStatus.active)
              : item)
          .toList(),
      customers: state.customers
          .map((item) => item.id == current.accountId
              ? item.copyWith(status: AccountStatus.active)
              : item)
          .toList(),
    );
    await _persistSuspensions();
    await recordAudit(
      action: AuditAction.liftSuspension,
      targetEntityType: current.accountType,
      targetEntityId: current.accountId,
      targetUserName: current.accountName,
      previousValue: 'Suspended',
      newValue: 'Active',
      reason: 'Suspension lifted early',
    );
    return null;
  }

  Future<void> _expireSuspensions() async {
    final expired = state.suspensions.where((item) => item.isExpired).toList();
    if (expired.isEmpty) return;
    final ids = expired.map((item) => item.accountId).toSet();
    state = state.copyWith(
      suspensions: state.suspensions
          .map((item) => item.isExpired ? item.lift(item.endDate) : item)
          .toList(),
      vendors: state.vendors
          .map((item) =>
              ids.contains(item.id) && item.status == AccountStatus.suspended
                  ? item.copyWith(status: AccountStatus.active)
                  : item)
          .toList(),
      customers: state.customers
          .map((item) =>
              ids.contains(item.id) && item.status == AccountStatus.suspended
                  ? item.copyWith(status: AccountStatus.active)
                  : item)
          .toList(),
    );
    await _persistSuspensions();
    for (final item in expired) {
      await recordAudit(
        action: AuditAction.liftSuspension,
        targetEntityType: item.accountType,
        targetEntityId: item.accountId,
        targetUserName: item.accountName,
        previousValue: 'Suspended',
        newValue: 'Active',
        reason: 'Suspension expired automatically',
      );
    }
  }

  Future<void> recordAudit({
    required AuditAction action,
    required String targetEntityType,
    required String targetEntityId,
    required String targetUserName,
    required String previousValue,
    required String newValue,
    String reason = '',
    Map<String, String> metadata = const {},
  }) async {
    final audit = AuditLog(
      id: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
      administratorId: 'ADM-001',
      administratorName:
          _preferences.getString('admin_name') ?? defaultAdminName,
      action: action,
      targetEntityType: targetEntityType,
      targetEntityId: targetEntityId,
      targetUserName: targetUserName,
      previousValue: previousValue,
      newValue: newValue,
      reason: reason,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(auditLogs: [audit, ...state.auditLogs]);
    await _preferences.setStringList(
      'admin_audit_logs',
      state.auditLogs.map((item) => jsonEncode(_auditToMap(item))).toList(),
    );
  }

  List<AuditLog> _readAuditLogs() {
    final raw = _preferences.getStringList('admin_audit_logs') ?? [];
    return raw
        .map((item) {
          try {
            return _auditFromMap(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AuditLog>()
        .toList();
  }

  List<Suspension> _readSuspensions() {
    final raw = _preferences.getStringList('admin_suspensions') ?? [];
    return raw
        .map((item) {
          try {
            return _suspensionFromMap(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Suspension>()
        .toList();
  }

  Future<void> _persistSuspensions() => _preferences.setStringList(
        'admin_suspensions',
        state.suspensions
            .map((item) => jsonEncode(_suspensionToMap(item)))
            .toList(),
      );

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 500));
}

Map<String, dynamic> _auditToMap(AuditLog item) => {
      'id': item.id,
      'administratorId': item.administratorId,
      'administratorName': item.administratorName,
      'action': item.action.name,
      'targetEntityType': item.targetEntityType,
      'targetEntityId': item.targetEntityId,
      'targetUserName': item.targetUserName,
      'previousValue': item.previousValue,
      'newValue': item.newValue,
      'reason': item.reason,
      'metadata': item.metadata,
      'timestamp': item.timestamp.toIso8601String(),
    };

AuditLog _auditFromMap(Map<String, dynamic> map) => AuditLog(
      id: map['id'] as String,
      administratorId: map['administratorId'] as String,
      administratorName: map['administratorName'] as String,
      action: AuditAction.values.byName(map['action'] as String),
      targetEntityType: map['targetEntityType'] as String,
      targetEntityId: map['targetEntityId'] as String,
      targetUserName: map['targetUserName'] as String,
      previousValue: map['previousValue'] as String,
      newValue: map['newValue'] as String,
      reason: map['reason'] as String,
      metadata: Map<String, String>.from(map['metadata'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );

Map<String, dynamic> _suspensionToMap(Suspension item) => {
      'id': item.id,
      'accountId': item.accountId,
      'accountName': item.accountName,
      'accountType': item.accountType,
      'reason': item.reason,
      'startDate': item.startDate.toIso8601String(),
      'endDate': item.endDate.toIso8601String(),
      'administratorId': item.administratorId,
      'createdAt': item.createdAt.toIso8601String(),
      'note': item.note,
      'notifyUser': item.notifyUser,
      'liftedAt': item.liftedAt?.toIso8601String(),
    };

Suspension _suspensionFromMap(Map<String, dynamic> map) => Suspension(
      id: map['id'] as String,
      accountId: map['accountId'] as String,
      accountName: map['accountName'] as String,
      accountType: map['accountType'] as String,
      reason: map['reason'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      administratorId: map['administratorId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String,
      notifyUser: map['notifyUser'] as bool,
      liftedAt: map['liftedAt'] == null
          ? null
          : DateTime.parse(map['liftedAt'] as String),
    );

T? _firstOrNull<T>(Iterable<T> values) => values.isEmpty ? null : values.first;

Future<void> _appendAuthAudit(
  SharedPreferences preferences,
  AuditAction action,
) async {
  final now = DateTime.now();
  final audit = AuditLog(
    id: 'AUD-${now.microsecondsSinceEpoch}',
    administratorId: 'ADM-001',
    administratorName: preferences.getString('admin_name') ?? defaultAdminName,
    action: action,
    targetEntityType: 'Authentication',
    targetEntityId: 'admin-session',
    targetUserName: defaultAdminEmail,
    previousValue: action == AuditAction.login ? 'Signed out' : 'Signed in',
    newValue: action == AuditAction.login ? 'Signed in' : 'Signed out',
    reason: '',
    metadata: const {},
    timestamp: now,
  );
  final existing = preferences.getStringList('admin_audit_logs') ?? <String>[];
  await preferences.setStringList(
    'admin_audit_logs',
    [jsonEncode(_auditToMap(audit)), ...existing],
  );
}

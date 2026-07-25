import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_models.dart';
import '../mock_data.dart';
import '../../core/theme/theme_controller.dart';

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
    if (email.trim().toLowerCase() != 'admin@palengkego.gov.ph' ||
        password != 'Admin123!') {
      return 'The email or password is incorrect.';
    }
    state = true;
    await _preferences.setBool('isLoggedIn', keepSignedIn);
    return null;
  }

  Future<void> logout() async {
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
  });

  final List<Vendor> vendors;
  final List<Customer> customers;
  final List<VendorApplication> applications;
  final List<RenewalRequest> renewals;
  final List<Report> reports;
  final List<Announcement> announcements;

  AppDataState copyWith({
    List<Vendor>? vendors,
    List<Customer>? customers,
    List<VendorApplication>? applications,
    List<RenewalRequest>? renewals,
    List<Report>? reports,
    List<Announcement>? announcements,
  }) {
    return AppDataState(
      vendors: vendors ?? this.vendors,
      customers: customers ?? this.customers,
      applications: applications ?? this.applications,
      renewals: renewals ?? this.renewals,
      reports: reports ?? this.reports,
      announcements: announcements ?? this.announcements,
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
        ),
      ) {
    _restore();
  }

  final SharedPreferences _preferences;

  Future<void> _restore() async {
    final blockedVendors =
        _preferences.getStringList('blocked_vendors') ?? <String>[];
    final vendorIds = blockedVendors.toSet();
    state = state.copyWith(
      vendors: state.vendors
          .map(
            (vendor) => vendorIds.contains(vendor.id)
                ? vendor.copyWith(status: AccountStatus.blocked)
                : vendor,
          )
          .toList(),
    );
  }

  Future<void> setVendorStatus(String id, AccountStatus status) async {
    await _wait();
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
  }

  Future<void> updateApplication(String id, ApplicationStatus status) async {
    await _wait();
    state = state.copyWith(
      applications: state.applications
          .map((item) => item.id == id ? item.copyWith(status: status) : item)
          .toList(),
    );
  }

  Future<void> updateRenewal(String id, RenewalStatus status) async {
    await _wait();
    state = state.copyWith(
      renewals: state.renewals
          .map((item) => item.id == id ? item.copyWith(status: status) : item)
          .toList(),
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
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    await _wait();
    state = state.copyWith(
      announcements: [announcement, ...state.announcements],
    );
    await _preferences.setString('last_announcement', announcement.title);
  }

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 500));
}

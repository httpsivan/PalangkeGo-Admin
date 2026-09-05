import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/admin_notification.dart';
import '../../core/theme/theme_controller.dart';

final notificationProvider =
    StateNotifierProvider<NotificationController, List<AdminNotification>>(
        (ref) {
  return NotificationController(ref.watch(sharedPreferencesProvider));
});

class NotificationController extends StateNotifier<List<AdminNotification>> {
  NotificationController(this._preferences) : super(_seedNotifications()) {
    _restore();
  }

  final SharedPreferences _preferences;
  final Set<String> _dismissed = <String>{};

  int get unreadCount => state.where((item) => !item.isRead).length;

  Future<void> markRead(String id) async {
    state = [
      for (final item in state)
        item.id == id ? item.copyWith(isRead: true) : item,
    ];
    await _persistReadState();
  }

  Future<void> markAllRead() async {
    state = [for (final item in state) item.copyWith(isRead: true)];
    await _persistReadState();
  }

  Future<void> dismiss(String id) async {
    _dismissed.add(id);
    state = state.where((item) => item.id != id).toList();
    await _persistDismissedState();
  }

  Future<void> clearRead() async {
    state = state.where((item) => !item.isRead).toList();
    await _persistReadState();
    await _persistDismissedState();
  }

  Future<void> _restore() async {
    final read = _preferences.getStringList('admin_notification_read') ?? [];
    _dismissed.addAll(
      _preferences.getStringList('admin_notification_dismissed') ?? [],
    );
    final readIds = read.toSet();
    state = state
        .where((item) => !_dismissed.contains(item.id))
        .map((item) =>
            item.copyWith(isRead: item.isRead || readIds.contains(item.id)))
        .toList();
  }

  Future<void> _persistReadState() => _preferences.setStringList(
        'admin_notification_read',
        state.where((item) => item.isRead).map((item) => item.id).toList(),
      );

  Future<void> _persistDismissedState() => _preferences.setStringList(
        'admin_notification_dismissed',
        _dismissed.toList(),
      );
}

List<AdminNotification> _seedNotifications() {
  final now = DateTime.now();
  return [
    AdminNotification(
      id: 'vendor-application-1',
      title: 'New Stall Holder Application',
      message: 'Fresh Finds Cooperative submitted a stall holder application.',
      type: NotificationType.vendorApplication,
      createdAt: now.subtract(const Duration(minutes: 5)),
      isRead: false,
      route: '/applications',
      actionLabel: 'Review Application',
    ),
    AdminNotification(
      id: 'account-update-1',
      title: 'Account Status Update',
      message: 'Seaside Catch\'s stall holder account was blocked.',
      type: NotificationType.accountUpdate,
      createdAt: now.subtract(const Duration(minutes: 38)),
      isRead: false,
      route: '/accounts',
      actionLabel: 'View Account',
    ),
    AdminNotification(
      id: 'renewal-1',
      title: 'Renewal Request',
      message: 'Seven Hills Grocer submitted a stall renewal request.',
      type: NotificationType.renewal,
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      route: '/renewal',
      actionLabel: 'Review Renewal',
    ),
    AdminNotification(
      id: 'customer-1',
      title: 'New Customer Registration',
      message: 'A new customer account was created.',
      type: NotificationType.customer,
      createdAt: now.subtract(const Duration(hours: 7)),
      isRead: true,
      route: '/accounts',
      actionLabel: 'View Customer',
    ),
    AdminNotification(
      id: 'report-1',
      title: 'Report Generated',
      message: 'The monthly sales report is now available.',
      type: NotificationType.report,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: false,
      route: '/reports',
      actionLabel: 'View Report',
    ),
    AdminNotification(
      id: 'system-1',
      title: 'System Alert',
      message: 'A stall holder account has been inactive for 30 days.',
      type: NotificationType.system,
      createdAt: now.subtract(const Duration(days: 2)),
      isRead: true,
      route: '/accounts',
      actionLabel: 'Review Account',
    ),
  ];
}

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

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationTarget? target,
    String? actionLabel,
  }) {
    final item = AdminNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      target: target,
      actionLabel: actionLabel,
    );
    state = [item, ...state];
  }

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
      message: 'Ricardo Santos submitted a stall holder application.',
      type: NotificationType.vendorApplication,
      createdAt: now.subtract(const Duration(minutes: 5)),
      isRead: false,
      target: const NotificationTarget(
        type: NotificationTargetType.application,
        id: '#APP-92839',
      ),
      actionLabel: 'Review Application',
    ),
    AdminNotification(
      id: 'stall-holder-report-1',
      title: 'New Stall Holder Report',
      message: 'A report about Alcel Castillo needs review.',
      type: NotificationType.report,
      createdAt: now.subtract(const Duration(minutes: 38)),
      isRead: false,
      target: const NotificationTarget(
        type: NotificationTargetType.report,
        id: '#RPT-100',
      ),
      actionLabel: 'Review Stall Holder Report',
    ),
    AdminNotification(
      id: 'renewal-1',
      title: 'Renewal Request',
      message: 'Rico Fernandez submitted a stall renewal request.',
      type: NotificationType.renewal,
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      target: const NotificationTarget(
        type: NotificationTargetType.renewal,
        id: '#RN-92835',
      ),
      actionLabel: 'Review Renewal',
    ),
    AdminNotification(
      id: 'customer-1',
      title: 'New Customer Registration',
      message: 'A new customer account was created.',
      type: NotificationType.customer,
      createdAt: now.subtract(const Duration(hours: 7)),
      isRead: true,
      target: const NotificationTarget(
        type: NotificationTargetType.customer,
        id: 'CUS-1200',
      ),
      actionLabel: 'View Customer',
    ),
    AdminNotification(
      id: 'customer-report-1',
      title: 'New Customer Report',
      message: 'A report about Juan Dela Cruz needs review.',
      type: NotificationType.report,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: false,
      target: const NotificationTarget(
        type: NotificationTargetType.report,
        id: '#RPT-200',
      ),
      actionLabel: 'Review Customer Report',
    ),
  ];
}

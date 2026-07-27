enum NotificationType {
  vendorApplication,
  accountUpdate,
  renewal,
  customer,
  report,
  system,
}

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.route,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? route;
  final String? actionLabel;

  AdminNotification copyWith({bool? isRead}) => AdminNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        route: route,
        actionLabel: actionLabel,
      );
}

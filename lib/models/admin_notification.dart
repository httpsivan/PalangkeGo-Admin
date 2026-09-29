enum NotificationType {
  vendorApplication,
  accountUpdate,
  renewal,
  customer,
  report,
  system,
}

/// Identifies the exact record an admin should review.
///
/// This maps directly to the future backend notification fields
/// (`targetType` and `targetId`) while keeping navigation details out of the
/// seeded mock records.
enum NotificationTargetType { application, renewal, report, customer }

class NotificationTarget {
  const NotificationTarget({required this.type, required this.id});

  final NotificationTargetType type;
  final String id;

  String get destination {
    final parameters = <String, String>{'open': '1'};
    final path = switch (type) {
      NotificationTargetType.application => '/applications',
      NotificationTargetType.renewal => '/renewal',
      NotificationTargetType.report => '/reports',
      NotificationTargetType.customer => '/accounts',
    };
    switch (type) {
      case NotificationTargetType.application:
        parameters['applicationId'] = id;
      case NotificationTargetType.renewal:
        parameters['renewalId'] = id;
      case NotificationTargetType.report:
        parameters['reportId'] = id;
      case NotificationTargetType.customer:
        parameters['accountId'] = id;
        parameters['tab'] = 'customers';
    }
    return Uri(path: path, queryParameters: parameters).toString();
  }
}

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.target,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final NotificationTarget? target;
  final String? actionLabel;

  String? get destination => target?.destination;

  AdminNotification copyWith({bool? isRead}) => AdminNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        target: target,
        actionLabel: actionLabel,
      );
}

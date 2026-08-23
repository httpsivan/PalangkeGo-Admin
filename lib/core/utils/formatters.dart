import 'package:intl/intl.dart';

final shortDate = DateFormat('MMM dd, yyyy');
final longDate = DateFormat('MMM dd, yyyy • hh:mm a');
String relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
  }
  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
}

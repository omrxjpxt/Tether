import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/core/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

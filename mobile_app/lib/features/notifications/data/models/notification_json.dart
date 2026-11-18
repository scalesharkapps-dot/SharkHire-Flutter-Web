import '../../../../shared/models/json_mappers.dart';
import '../../presentation/providers/notifications_provider.dart';

/// `notifications` row.
///
/// ```json
/// {"id": "uuid", "title": "You're shortlisted", "message": "…",
///  "notification_type": "application_update", "related_entity_id": "uuid",
///  "is_read": false, "created_at": "…"}
/// ```
AppNotification notificationFromJson(Map<String, Object?> j) => AppNotification(
  id: '${j['id']}',
  kind: switch (j['notification_type']) {
    'new_matches' => NotificationKind.newMatches,
    'application_update' => NotificationKind.applicationUpdate,
    'saved_job_reminder' => NotificationKind.savedReminder,
    'employer_response' => NotificationKind.employerResponse,
    _ => NotificationKind.system,
  },
  title: j['title'] as String? ?? '',
  message: j['message'] as String? ?? '',
  createdAt: parseDate(j['created_at']) ?? DateTime.now(),
  relatedId: j['related_entity_id'] as String?,
  isRead: j['is_read'] as bool? ?? false,
);

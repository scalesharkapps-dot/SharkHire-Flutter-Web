import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';

/// Kinds of in-app notification (guide §3.5 "Notifications for …").
enum NotificationKind {
  newMatches,
  applicationUpdate,
  savedReminder,
  employerResponse,
  system,
}

/// Mirrors the `notifications` table (Appendix A).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.relatedId,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime createdAt;

  /// Job or application the notification is about.
  final String? relatedId;
  final bool isRead;

  AppNotification read() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    message: message,
    createdAt: createdAt,
    relatedId: relatedId,
    isRead: true,
  );
}

/// In-app notifications. Push delivery (Firebase Cloud Messaging) feeds the
/// same list once connected.
class NotificationsController extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    // Real API: no sample data until this screen is connected.
    if (ApiConfig.isConfigured) return const [];
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.newMatches,
        title: '3 new jobs match your CV',
        message: 'Senior Flutter Developer at Indus Ledger is a 92% match.',
        createdAt: now.subtract(const Duration(minutes: 40)),
        relatedId: 'job-01',
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.applicationUpdate,
        title: 'You\'re shortlisted',
        message: 'Harbor & Co. shortlisted you for Junior FastAPI Developer.',
        createdAt: now.subtract(const Duration(hours: 5)),
        relatedId: 'app-3',
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.employerResponse,
        title: 'Interview invitation',
        message:
            'Harbor & Co. invited you to interview for QA Engineer on Thursday.',
        createdAt: now.subtract(const Duration(days: 2)),
        relatedId: 'app-4',
        isRead: true,
      ),
      AppNotification(
        id: 'n4',
        kind: NotificationKind.savedReminder,
        title: 'A saved job closes soon',
        message:
            'Data Analyst at Insight Grid stops taking applications in 3 days.',
        createdAt: now.subtract(const Duration(days: 3)),
        relatedId: 'job-06',
        isRead: true,
      ),
    ];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markRead(String id) =>
      state = [for (final n in state) n.id == id ? n.read() : n];

  void markAllRead() => state = [for (final n in state) n.read()];

  /// Removes a notification and returns it so the UI can offer undo.
  AppNotification? dismiss(String id) {
    final n = state.where((x) => x.id == id).firstOrNull;
    state = state.where((x) => x.id != id).toList();
    return n;
  }

  void restore(AppNotification n) =>
      state = [...state, n]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.isRead).length,
);

enum AlertFrequency { daily, weekly }

/// Saved search alert. Mirrors `job_alerts`.
@immutable
class JobAlert {
  const JobAlert({
    required this.id,
    required this.name,
    required this.query,
    this.frequency = AlertFrequency.daily,
    this.isActive = true,
    this.filtersLabel,
  });

  final String id;
  final String name;
  final String query;
  final AlertFrequency frequency;
  final bool isActive;
  final String? filtersLabel;

  JobAlert copyWith({bool? isActive}) => JobAlert(
    id: id,
    name: name,
    query: query,
    frequency: frequency,
    isActive: isActive ?? this.isActive,
    filtersLabel: filtersLabel,
  );
}

class JobAlertsController extends Notifier<List<JobAlert>> {
  @override
  List<JobAlert> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : const [
          JobAlert(
            id: 'a1',
            name: 'Flutter jobs',
            query: 'Flutter developer',
            filtersLabel: 'Pakistan & remote',
          ),
          JobAlert(
            id: 'a2',
            name: 'Remote mobile roles',
            query: 'Mobile engineer',
            frequency: AlertFrequency.weekly,
            filtersLabel: 'Remote · Worldwide',
            isActive: false,
          ),
        ];

  void add(String name, String query, AlertFrequency frequency) => state = [
    ...state,
    JobAlert(
      id: 'a${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      query: query,
      frequency: frequency,
    ),
  ];

  void toggle(String id) => state = [
    for (final a in state) a.id == id ? a.copyWith(isActive: !a.isActive) : a,
  ];

  void remove(String id) => state = state.where((a) => a.id != id).toList();
}

final jobAlertsProvider = NotifierProvider<JobAlertsController, List<JobAlert>>(
  JobAlertsController.new,
);

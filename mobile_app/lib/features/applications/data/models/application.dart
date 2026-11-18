import 'package:flutter/foundation.dart';

import '../../../../shared/models/job_summary.dart';

/// One step in an application's history (`application_status_history`).
@immutable
class StatusChange {
  const StatusChange(this.status, this.at, {this.note});

  final ApplicationStatus status;
  final DateTime at;
  final String? note;
}

/// An internal application to a SharkHire employer job (`applications`).
/// External jobs are never stored here – only their apply clicks are
/// recorded, because we can't confirm an external submission (guide §3.5).
@immutable
class JobApplication {
  const JobApplication({
    required this.id,
    required this.job,
    required this.history,
    this.cvFileName,
    this.coverLetter,
  });

  final String id;
  final JobSummary job;
  final List<StatusChange> history;
  final String? cvFileName;
  final String? coverLetter;

  ApplicationStatus get status => history.last.status;
  DateTime get submittedAt => history.first.at;
  DateTime get updatedAt => history.last.at;

  bool get isActive => !const {
    ApplicationStatus.rejected,
    ApplicationStatus.accepted,
    ApplicationStatus.withdrawn,
  }.contains(status);

  bool get canWithdraw => isActive;

  JobApplication withStatus(
    ApplicationStatus s, {
    String? note,
    DateTime? at,
  }) => JobApplication(
    id: id,
    job: job,
    cvFileName: cvFileName,
    coverLetter: coverLetter,
    history: [
      ...history,
      StatusChange(s, at ?? DateTime.now(), note: note),
    ],
  );
}

/// The normal order of statuses, used to draw progress.
const applicationFlow = [
  ApplicationStatus.submitted,
  ApplicationStatus.underReview,
  ApplicationStatus.shortlisted,
  ApplicationStatus.interview,
  ApplicationStatus.accepted,
];

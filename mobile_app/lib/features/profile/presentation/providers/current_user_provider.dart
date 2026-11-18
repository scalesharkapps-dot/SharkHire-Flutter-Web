import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../data/models/job_preferences.dart';

/// The signed-in user (from the session). Screens behind the auth guard can
/// rely on it being a real user; [AppUser.guest] covers the sign-out instant.
final currentUserProvider = Provider<AppUser>(
  (ref) => ref.watch(sessionProvider).user ?? AppUser.guest,
);

/// The job seeker's saved preferences (in memory until `/profiles/me`).
class JobPreferencesController extends Notifier<JobPreferences> {
  @override
  JobPreferences build() => const JobPreferences(
    categories: {'Software', 'Data / AI'},
    employmentTypes: {EmploymentType.fullTime},
  );

  void save(JobPreferences prefs) => state = prefs;
}

final jobPreferencesProvider =
    NotifierProvider<JobPreferencesController, JobPreferences>(
      JobPreferencesController.new,
    );

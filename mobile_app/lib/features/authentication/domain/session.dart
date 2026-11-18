import 'package:flutter/foundation.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/domain_enums.dart';

/// Where a user is in the sign-in journey. The router uses this to decide
/// which part of the app they may see.
enum SessionStage {
  /// Not signed in – welcome, login, registration only.
  signedOut,

  /// Account created but the email address is not confirmed yet.
  unverified,

  /// Job seeker who has not set job preferences yet.
  needsOnboarding,

  /// Fully signed in.
  ready,
}

@immutable
class Session {
  const Session({
    this.user,
    this.emailVerified = false,
    this.onboardingComplete = false,
  });

  static const signedOut = Session();

  final AppUser? user;
  final bool emailVerified;

  /// Job seekers complete job preferences once after sign-up.
  /// Employers are onboarded through their company profile instead.
  final bool onboardingComplete;

  bool get isSignedIn => user != null;
  bool get isEmployer => user?.roles.contains(AppRole.employer) ?? false;
  bool get isAdmin => user?.roles.contains(AppRole.admin) ?? false;

  SessionStage get stage {
    if (user == null) return SessionStage.signedOut;
    if (!emailVerified) return SessionStage.unverified;
    if (!isEmployer && !isAdmin && !onboardingComplete) {
      return SessionStage.needsOnboarding;
    }
    return SessionStage.ready;
  }

  Session copyWith({
    AppUser? user,
    bool? emailVerified,
    bool? onboardingComplete,
  }) => Session(
    user: user ?? this.user,
    emailVerified: emailVerified ?? this.emailVerified,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}

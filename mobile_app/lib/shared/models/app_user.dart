import 'package:flutter/foundation.dart';

import 'domain_enums.dart';

/// Signed-in user as the UI needs it. Mirrors `profiles` + `user_roles`
/// (Appendix A); replaced by the API-backed model at integration.
///
/// Roles come from the server (RBAC) – the app only *reads* them to choose
/// navigation; it never grants a role itself (guide §3.4).
@immutable
class AppUser {
  const AppUser({
    this.id = '',
    required this.fullName,
    required this.email,
    this.roles = const {AppRole.jobSeeker},
    this.headline,
    this.location,
    this.phone,
    this.profileCompletion = 0.2,
    this.hasCv = false,
    this.isPremium = false,
  });

  /// Shown only in the brief moment between sign-out and redirect.
  static const guest = AppUser(fullName: 'Guest', email: '');

  /// Backend (Supabase auth) user ID, also used as the RevenueCat App User
  /// ID. Empty for demo users and older test fixtures.
  final String id;
  final String fullName;
  final String email;
  final Set<AppRole> roles;
  final String? headline;
  final String? location;
  final String? phone;

  /// 0.0 – 1.0
  final double profileCompletion;
  final bool hasCv;
  final bool isPremium;

  bool get isEmployer => roles.contains(AppRole.employer);
  bool get isAdmin => roles.contains(AppRole.admin);

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  AppUser copyWith({
    String? fullName,
    String? headline,
    String? location,
    String? phone,
    double? profileCompletion,
    bool? hasCv,
    bool? isPremium,
  }) => AppUser(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email,
    roles: roles,
    headline: headline ?? this.headline,
    location: location ?? this.location,
    phone: phone ?? this.phone,
    profileCompletion: profileCompletion ?? this.profileCompletion,
    hasCv: hasCv ?? this.hasCv,
    isPremium: isPremium ?? this.isPremium,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.newMatches = true,
    this.applicationUpdates = true,
    this.savedJobReminders = true,
    this.employerMessages = true,
    this.emailUpdates = false,
    this.aiParsingConsent = false,
  });

  final bool newMatches;
  final bool applicationUpdates;
  final bool savedJobReminders;
  final bool employerMessages;
  final bool emailUpdates;

  /// Consent to send CV text to an external AI provider for extraction
  /// (guide §3.12). Off by default; rule-based parsing works without it.
  final bool aiParsingConsent;

  AppSettings copyWith({
    bool? newMatches,
    bool? applicationUpdates,
    bool? savedJobReminders,
    bool? employerMessages,
    bool? emailUpdates,
    bool? aiParsingConsent,
  }) => AppSettings(
    newMatches: newMatches ?? this.newMatches,
    applicationUpdates: applicationUpdates ?? this.applicationUpdates,
    savedJobReminders: savedJobReminders ?? this.savedJobReminders,
    employerMessages: employerMessages ?? this.employerMessages,
    emailUpdates: emailUpdates ?? this.emailUpdates,
    aiParsingConsent: aiParsingConsent ?? this.aiParsingConsent,
  );
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings Function(AppSettings s) change) =>
      state = change(state);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

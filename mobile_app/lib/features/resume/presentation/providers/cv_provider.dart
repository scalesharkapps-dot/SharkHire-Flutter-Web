import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../shared/models/domain_enums.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/models/resume_models.dart';
import '../../data/repositories/resume_repository.dart';

/// Opens the system file picker for a CV. Overridden in tests.
typedef CvPicker = Future<PickedCvFile?> Function();

final cvPickerProvider = Provider<CvPicker>(
  (ref) => () async {
    final f = await FilePicker.pickFile(
      dialogTitle: 'Choose your CV',
      type: FileType.custom,
      allowedExtensions: CvRules.allowedExtensions,
    );
    if (f == null) return null;
    final size = await f.length() ?? 0;
    return PickedCvFile(
      name: f.name,
      sizeBytes: size,
      path: f.path,
      // Android often returns a content:// file without a path, and the web
      // has no paths at all, so read the bytes (CVs are at most 5 MB).
      bytes: size > 0 && size <= CvRules.maxSizeBytes
          ? await f.readAsBytes()
          : null,
    );
  },
);

@immutable
class CvState {
  const CvState({this.active, this.profile});

  final Resume? active;
  final ParsedProfile? profile;

  bool get hasCv => active != null;
}

/// The candidate's active CV and the profile extracted from it.
class CvController extends Notifier<CvState> {
  ResumeRepository get _repo => ref.read(resumeRepositoryProvider);

  @override
  CvState build() {
    // Load the signed-in user's current CV from the server.
    final email = ref.watch(sessionProvider.select((s) => s.user?.email));
    if (email != null && ApiConfig.isConfigured) {
      Future.microtask(_syncActive);
    }
    return const CvState();
  }

  Future<void> _syncActive() async {
    try {
      final active = await _repo.fetchActive();
      if (!ref.mounted) return;
      if (active != null && active.status == ResumeStatus.processed) {
        state = CvState(active: active, profile: state.profile);
      }
    } catch (_) {
      // Keep the current state; screens offer upload again.
    }
  }

  /// Records a processed upload and marks the profile as having a CV.
  void markUploaded(PickedCvFile file) {
    state = CvState(
      active: Resume(
        id: 'cv-${DateTime.now().millisecondsSinceEpoch}',
        fileName: file.name,
        sizeBytes: file.sizeBytes,
        uploadedAt: DateTime.now(),
        status: ResumeStatus.processed,
      ),
    );
    // Replace the placeholder with the server's record (real id and date).
    if (ApiConfig.isConfigured) _syncActive();
    ref
        .read(sessionProvider.notifier)
        .updateUser(
          (u) => u.copyWith(
            hasCv: true,
            profileCompletion: math.max(u.profileCompletion, 0.75),
          ),
        );
  }

  Future<ParsedProfile> loadProfile() async {
    final existing = state.profile;
    if (existing != null) return existing;
    final profile = await _repo.fetchParsedProfile(
      ref.read(currentUserProvider),
    );
    state = CvState(active: state.active, profile: profile);
    return profile;
  }

  Future<void> saveProfile(ParsedProfile profile) async {
    await _repo.saveCorrections(profile);
    state = CvState(active: state.active, profile: profile);
    ref
        .read(sessionProvider.notifier)
        .updateUser(
          (u) => u.copyWith(
            location: profile.location,
            profileCompletion: math.max(u.profileCompletion, 0.9),
          ),
        );
  }

  /// Deletes the CV on the server, then clears it locally.
  Future<void> remove() async {
    final id = state.active?.id;
    if (id != null && ApiConfig.isConfigured) await _repo.delete(id);
    state = const CvState();
    ref
        .read(sessionProvider.notifier)
        .updateUser(
          (u) => u.copyWith(
            hasCv: false,
            profileCompletion: math.min(u.profileCompletion, 0.45),
          ),
        );
  }
}

final cvProvider = NotifierProvider<CvController, CvState>(CvController.new);

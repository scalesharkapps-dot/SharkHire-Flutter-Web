import '../../../../shared/models/app_user.dart';
import '../models/resume_models.dart';
import 'resume_repository.dart';

/// MOCK – simulates upload and extraction with example data.
class MockResumeRepository implements ResumeRepository {
  const MockResumeRepository({
    this.stepDelay = const Duration(milliseconds: 900),
  });

  final Duration stepDelay;

  @override
  Stream<CvProcessingStage> uploadAndProcess(PickedCvFile file) async* {
    for (final stage in CvProcessingStage.values) {
      yield stage;
      if (stage != CvProcessingStage.done) {
        await Future<void>.delayed(stepDelay);
      }
    }
  }

  @override
  Future<ParsedProfile> fetchParsedProfile(AppUser user) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ParsedProfile(
      fullName: user.fullName,
      email: user.email,
      location: user.location ?? 'Lahore, Pakistan',
      jobTitles: const ['Flutter Developer', 'Mobile Engineer'],
      skills: const [
        'Flutter',
        'Dart',
        'Firebase',
        'REST APIs',
        'Git',
        'UI design',
        'SQL',
      ],
      yearsOfExperience: 2,
      experience: const [
        ExperienceEntry(
          jobTitle: 'Flutter Developer',
          organization: 'Northstar Apps',
          period: 'Jan 2024 – Present',
          description:
              'Built and shipped two consumer apps to the Play Store and App Store.',
        ),
        ExperienceEntry(
          jobTitle: 'Mobile Developer Intern',
          organization: 'Codebridge Studio',
          period: 'Jun 2023 – Dec 2023',
        ),
      ],
      education: const [
        EducationEntry(
          qualification: 'BS Computer Science',
          institution: 'University of the Punjab',
          period: '2019 – 2023',
        ),
      ],
      certifications: const ['Google Associate Android Developer'],
      projects: const ['Expense tracker app (Flutter + Firebase)'],
    );
  }

  @override
  Future<void> saveCorrections(ParsedProfile profile) =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  /// Mock users start without a CV.
  @override
  Future<Resume?> fetchActive() async => null;

  @override
  Future<void> delete(String id) async {}
}

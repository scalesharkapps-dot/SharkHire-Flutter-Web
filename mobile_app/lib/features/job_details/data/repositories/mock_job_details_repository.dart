import '../../../../shared/models/job_summary.dart';
import '../../../job_search/data/repositories/jobs_repository.dart';
import '../models/job_details.dart';
import 'job_details_repository.dart';

/// MOCK – builds example details from the mock job list.
class MockJobDetailsRepository implements JobDetailsRepository {
  const MockJobDetailsRepository(this._jobs);

  final JobsRepository _jobs;

  static const _skillsByCategory = {
    'Software': ['Flutter', 'Dart', 'REST APIs', 'Git', 'Firebase', 'CI/CD'],
    'Data / AI': ['Python', 'SQL', 'Machine Learning', 'Pandas', 'Power BI'],
    'Design': ['Figma', 'Prototyping', 'User research', 'Design systems'],
    'Marketing': ['SEO', 'Content', 'Google Analytics', 'Paid social'],
    'Operations': ['AWS', 'Docker', 'Kubernetes', 'Terraform', 'Linux'],
  };

  @override
  Future<JobDetails> fetch(String jobId) async {
    final jobs = await _jobs.fetchJobs();
    final summary = jobs.where((j) => j.id == jobId).firstOrNull;
    if (summary == null) throw const JobNotFound();
    return _detailsFor(summary);
  }

  @override
  Future<void> recordExternalApplyClick(String jobId) =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  JobDetails _detailsFor(JobSummary s) {
    final skills =
        _skillsByCategory[s.category] ?? const ['Communication', 'Teamwork'];
    final score = s.matchScore ?? 0;
    return JobDetails(
      summary: s,
      description:
          '${s.companyName} is hiring a ${s.title} to join a growing team. You\'ll work closely '
          'with product, design and engineering to ship work that real customers use every day.',
      responsibilities: const [
        'Own features end to end, from planning to release',
        'Work with the team on reviews, testing and quality',
        'Share progress clearly and help others when they\'re stuck',
      ],
      requirements: [
        'Hands-on experience with ${skills.take(2).join(' and ')}',
        if (s.employmentType == EmploymentType.internship)
          'Currently studying or recently graduated'
        else
          '1+ years in a similar role',
        'Good written and spoken English',
      ],
      requiredSkills: skills,
      matchReasons: [
        if (score >= 60)
          'Your ${skills.first} and ${skills[1]} skills match this role',
        if (score >= 75) 'Your experience level suits what they\'re asking for',
        if (s.workMode == WorkMode.remote)
          'This job is remote, which fits your preference',
        if (s.workMode != WorkMode.remote && !s.isInternational)
          'The location is in Pakistan, as you prefer',
        if (score < 80) 'Some required skills are missing from your CV',
      ],
      experienceLevel: s.employmentType == EmploymentType.internship
          ? ExperienceLevel.internship
          : (s.title.startsWith('Senior')
                ? ExperienceLevel.senior
                : ExperienceLevel.junior),
      education: s.isInternal ? 'Bachelor\'s degree or equivalent' : null,
      vacancies: s.isInternal ? 2 : null,
      deadline: s.isInternal ? s.postedAt.add(const Duration(days: 30)) : null,
      applicationInstructions: s.isInternal
          ? 'Attach your CV and a short note on a project you\'re proud of.'
          : null,
      applyUrl: s.isInternal
          ? null
          : 'https://example.com/careers/${s.companyName.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-')}',
      publisher: s.isInternal ? null : 'Company careers site',
      lastCheckedAt: s.isInternal
          ? null
          : DateTime.now().subtract(const Duration(hours: 2)),
      companyAbout:
          '${s.companyName} builds digital products for customers in Pakistan and abroad. '
          'Teams are small, senior-led and focused on shipping.',
      verifiedEmployer: s.isInternal,
    );
  }
}

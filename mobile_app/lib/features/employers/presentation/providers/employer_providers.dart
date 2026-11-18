import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';

import '../../../../shared/models/domain_enums.dart';
import '../../data/models/employer_models.dart';

/// The employer's job posts (`/api/v1/employer/jobs`). In memory for now.
class EmployerJobsController extends Notifier<List<EmployerJob>> {
  @override
  List<EmployerJob> build() {
    // Real API: no sample data until this screen is connected.
    if (ApiConfig.isConfigured) return const [];
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    return [
      EmployerJob(
        id: 'ej-1',
        title: 'Backend Developer',
        location: 'Karachi, Pakistan',
        workMode: WorkMode.hybrid,
        employmentType: EmploymentType.fullTime,
        status: JobStatus.pending,
        createdAt: ago(1),
        vacancies: 2,
        requiredSkills: const ['Python', 'FastAPI', 'SQL'],
        experienceLevel: ExperienceLevel.junior,
        salaryMin: 200000,
        salaryMax: 300000,
        description: 'Build and maintain REST APIs for our hiring products.',
      ),
      EmployerJob(
        id: 'ej-2',
        title: 'ML Intern',
        location: 'Lahore, Pakistan',
        workMode: WorkMode.onsite,
        employmentType: EmploymentType.internship,
        status: JobStatus.pending,
        createdAt: ago(2),
        requiredSkills: const ['Python', 'Pandas'],
        experienceLevel: ExperienceLevel.internship,
      ),
      EmployerJob(
        id: 'ej-3',
        title: 'UI Designer',
        location: 'Remote',
        workMode: WorkMode.remote,
        employmentType: EmploymentType.contract,
        status: JobStatus.approved,
        createdAt: ago(9),
        requiredSkills: const ['Figma', 'Design systems'],
        views: 412,
      ),
      EmployerJob(
        id: 'ej-4',
        title: 'QA Engineer',
        location: 'Lahore, Pakistan',
        workMode: WorkMode.hybrid,
        employmentType: EmploymentType.fullTime,
        status: JobStatus.rejected,
        createdAt: ago(5),
        vacancies: 3,
        rejectionReason: 'Please add a salary range and clearer requirements.',
      ),
      EmployerJob(
        id: 'ej-5',
        title: 'Data Analyst',
        location: 'Islamabad, Pakistan',
        workMode: WorkMode.onsite,
        employmentType: EmploymentType.fullTime,
        status: JobStatus.closed,
        createdAt: ago(40),
        views: 980,
      ),
      EmployerJob(
        id: 'ej-6',
        title: 'Senior Flutter Developer',
        location: 'Lahore, Pakistan',
        workMode: WorkMode.hybrid,
        employmentType: EmploymentType.fullTime,
        status: JobStatus.approved,
        createdAt: ago(3),
        vacancies: 2,
        requiredSkills: const ['Flutter', 'Dart', 'Firebase'],
        salaryMin: 450000,
        salaryMax: 600000,
        views: 1240,
      ),
    ];
  }

  EmployerJob? byId(String id) => state.where((j) => j.id == id).firstOrNull;

  /// New and edited jobs go to admin review as Pending (guide §3.6).
  Future<EmployerJob> save(EmployerJob job) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final pending = job.copyWith(status: JobStatus.pending);
    final exists = state.any((j) => j.id == job.id);
    state = exists
        ? [for (final j in state) j.id == job.id ? pending : j]
        : [pending, ...state];
    return pending;
  }

  void close(String id) => state = [
    for (final j in state)
      j.id == id ? j.copyWith(status: JobStatus.closed) : j,
  ];
}

final employerJobsProvider =
    NotifierProvider<EmployerJobsController, List<EmployerJob>>(
      EmployerJobsController.new,
    );

/// Candidates who applied to the employer's jobs.
class ApplicantsController extends Notifier<List<Applicant>> {
  @override
  List<Applicant> build() {
    // Real API: no sample data until this screen is connected.
    if (ApiConfig.isConfigured) return const [];
    final now = DateTime.now();
    DateTime ago(int h) => now.subtract(Duration(hours: h));
    return [
      Applicant(
        id: 'c-1',
        name: 'Ali Raza',
        jobId: 'ej-6',
        jobTitle: 'Senior Flutter Developer',
        status: ApplicationStatus.submitted,
        appliedAt: ago(3),
        headline: 'Flutter Developer · 4 years',
        location: 'Lahore, Pakistan',
        skills: const ['Flutter', 'Dart', 'Firebase', 'Riverpod'],
        experienceSummary:
            'Flutter Developer at Northstar Apps · 2 years\nMobile Engineer at Codebridge · 2 years',
        education: 'BS Computer Science, FAST NUCES',
        cvFileName: 'Ali_Raza_CV.pdf',
        coverLetter:
            'I\'ve shipped three Flutter apps with over 100k installs and would love to help scale yours.',
        matchScore: 91,
      ),
      Applicant(
        id: 'c-2',
        name: 'Sara Khan',
        jobId: 'ej-6',
        jobTitle: 'Senior Flutter Developer',
        status: ApplicationStatus.underReview,
        appliedAt: ago(26),
        headline: 'Mobile Engineer · 5 years',
        location: 'Karachi, Pakistan',
        skills: const ['Flutter', 'Kotlin', 'Swift'],
        experienceSummary: 'Mobile Engineer at Bluefin Media · 5 years',
        education: 'BE Software Engineering, NED',
        cvFileName: 'Sara_Khan_CV.pdf',
        matchScore: 86,
      ),
      Applicant(
        id: 'c-3',
        name: 'Hamza Ahmed',
        jobId: 'ej-3',
        jobTitle: 'UI Designer',
        status: ApplicationStatus.shortlisted,
        appliedAt: ago(70),
        headline: 'Product Designer · 3 years',
        location: 'Remote',
        skills: const ['Figma', 'Prototyping', 'Design systems'],
        experienceSummary: 'Product Designer at Harbor & Co. · 3 years',
        education: 'BDes, NCA Lahore',
        cvFileName: 'Hamza_Ahmed_Portfolio.pdf',
        matchScore: 82,
      ),
      Applicant(
        id: 'c-4',
        name: 'Zainab Ali',
        jobId: 'ej-3',
        jobTitle: 'UI Designer',
        status: ApplicationStatus.interview,
        appliedAt: ago(120),
        headline: 'UI/UX Designer · 2 years',
        location: 'Islamabad, Pakistan',
        skills: const ['Figma', 'User research'],
        cvFileName: 'Zainab_Ali_CV.pdf',
        matchScore: 78,
      ),
      Applicant(
        id: 'c-5',
        name: 'Usman Tariq',
        jobId: 'ej-6',
        jobTitle: 'Senior Flutter Developer',
        status: ApplicationStatus.rejected,
        appliedAt: ago(200),
        headline: 'Android Developer · 1 year',
        skills: const ['Kotlin', 'Java'],
        cvFileName: 'Usman_Tariq_CV.docx',
        matchScore: 54,
      ),
    ];
  }

  Applicant? byId(String id) => state.where((a) => a.id == id).firstOrNull;

  /// `PATCH` application status; the candidate is notified by the backend.
  Future<void> setStatus(
    String id,
    ApplicationStatus status, {
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = [
      for (final a in state)
        a.id == id
            ? a.copyWith(
                status: status,
                notes: (note == null || note.trim().isEmpty)
                    ? a.notes
                    : [...a.notes, note.trim()],
              )
            : a,
    ];
  }
}

final applicantsProvider =
    NotifierProvider<ApplicantsController, List<Applicant>>(
      ApplicantsController.new,
    );

class CompanyController extends Notifier<Company> {
  @override
  Company build() => ApiConfig.isConfigured
      ? const Company(name: '')
      : const Company(
          name: 'Indus Ledger',
          website: 'https://indusledger.example',
          industry: 'Financial technology',
          companySize: '51–200 employees',
          headquarters: 'Lahore, Pakistan',
          description:
              'Indus Ledger builds accounting and payments software for businesses in Pakistan.',
          verification: VerificationStatus.verified,
        );

  Future<void> save(Company c) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = c;
  }
}

final companyProvider = NotifierProvider<CompanyController, Company>(
  CompanyController.new,
);

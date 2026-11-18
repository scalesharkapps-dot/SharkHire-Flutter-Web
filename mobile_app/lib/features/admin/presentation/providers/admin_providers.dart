import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';

import '../../../profile/presentation/providers/current_user_provider.dart';
import '../../data/models/admin_models.dart';

// In-memory admin data until the admin API (`/api/v1/admin/*`) is connected.
// Admin access itself is enforced by the backend's admin role (guide §3.4).
// Every moderation action writes an audit entry (guide §3.7).

DateTime _ago({int days = 0, int hours = 0}) =>
    DateTime.now().subtract(Duration(days: days, hours: hours));

class AuditLog extends Notifier<List<AuditEntry>> {
  @override
  List<AuditEntry> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : [
          AuditEntry(
            admin: 'Sana Iqbal',
            action: 'Approved job',
            entityType: 'Job',
            entityLabel: 'Senior Flutter Developer · Indus Ledger',
            at: _ago(hours: 20),
          ),
          AuditEntry(
            admin: 'Sana Iqbal',
            action: 'Rejected job',
            entityType: 'Job',
            entityLabel: 'QA Engineer · Indus Ledger',
            at: _ago(days: 1, hours: 4),
            details: 'Please add a salary range and clearer requirements.',
          ),
          AuditEntry(
            admin: 'Omar Farooq',
            action: 'Verified employer',
            entityType: 'Company',
            entityLabel: 'Kestrel Systems',
            at: _ago(days: 2),
          ),
          AuditEntry(
            admin: 'Omar Farooq',
            action: 'Blocked user',
            entityType: 'User',
            entityLabel: 'spam.account@example.com',
            at: _ago(days: 3),
            details: 'Repeated fake job applications',
          ),
        ];

  void log(
    String action,
    String entityType,
    String entityLabel, {
    String? details,
  }) {
    final admin = ref.read(currentUserProvider).fullName;
    state = [
      AuditEntry(
        admin: admin,
        action: action,
        entityType: entityType,
        entityLabel: entityLabel,
        at: DateTime.now(),
        details: details,
      ),
      ...state,
    ];
  }
}

final auditLogProvider = NotifierProvider<AuditLog, List<AuditEntry>>(
  AuditLog.new,
);

class ModerationJobs extends Notifier<List<ModerationJob>> {
  @override
  List<ModerationJob> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : [
          ModerationJob(
            id: 'j1',
            title: 'Backend Developer',
            company: 'Indus Ledger',
            location: 'Karachi, Pakistan',
            employmentType: EmploymentType.fullTime,
            workMode: WorkMode.hybrid,
            submittedAt: _ago(hours: 6),
            status: JobStatus.pending,
            skills: const ['Python', 'FastAPI', 'SQL'],
            salaryLabel: 'PKR 200K – 300K',
            description:
                'Build and maintain REST APIs for our hiring products.',
          ),
          ModerationJob(
            id: 'j2',
            title: 'ML Intern',
            company: 'Indus Ledger',
            location: 'Lahore, Pakistan',
            employmentType: EmploymentType.internship,
            workMode: WorkMode.onsite,
            submittedAt: _ago(hours: 30),
            status: JobStatus.pending,
            skills: const ['Python', 'Pandas'],
            description:
                'Support the data team with model experiments and reporting.',
          ),
          ModerationJob(
            id: 'j3',
            title: 'Customer Success Lead',
            company: 'Harbor & Co.',
            location: 'Remote',
            employmentType: EmploymentType.fullTime,
            workMode: WorkMode.remote,
            submittedAt: _ago(hours: 44),
            status: JobStatus.pending,
            skills: const ['Customer support', 'Zendesk'],
            description:
                'Lead a small team that supports our enterprise customers.',
          ),
          ModerationJob(
            id: 'j4',
            title: 'Senior Flutter Developer',
            company: 'Indus Ledger',
            location: 'Lahore, Pakistan',
            employmentType: EmploymentType.fullTime,
            workMode: WorkMode.hybrid,
            submittedAt: _ago(days: 3),
            status: JobStatus.approved,
            skills: const ['Flutter', 'Dart'],
            salaryLabel: 'PKR 450K – 600K',
          ),
          ModerationJob(
            id: 'j5',
            title: 'UI Designer',
            company: 'Indus Ledger',
            location: 'Remote',
            employmentType: EmploymentType.contract,
            workMode: WorkMode.remote,
            submittedAt: _ago(days: 9),
            status: JobStatus.approved,
          ),
          ModerationJob(
            id: 'j6',
            title: 'QA Engineer',
            company: 'Indus Ledger',
            location: 'Lahore, Pakistan',
            employmentType: EmploymentType.fullTime,
            workMode: WorkMode.hybrid,
            submittedAt: _ago(days: 5),
            status: JobStatus.rejected,
            rejectionReason:
                'Please add a salary range and clearer requirements.',
          ),
        ];

  /// `PATCH /api/v1/admin/jobs/{id}/approve`
  void approve(String id) {
    final job = state.firstWhere((j) => j.id == id);
    state = [
      for (final j in state) j.id == id ? j.withStatus(JobStatus.approved) : j,
    ];
    ref
        .read(auditLogProvider.notifier)
        .log('Approved job', 'Job', '${job.title} · ${job.company}');
  }

  /// `PATCH /api/v1/admin/jobs/{id}/reject` – the employer sees [reason].
  void reject(String id, String reason) {
    final job = state.firstWhere((j) => j.id == id);
    state = [
      for (final j in state)
        j.id == id ? j.withStatus(JobStatus.rejected, reason: reason) : j,
    ];
    ref
        .read(auditLogProvider.notifier)
        .log(
          'Rejected job',
          'Job',
          '${job.title} · ${job.company}',
          details: reason,
        );
  }

  void remove(String id) {
    final job = state.firstWhere((j) => j.id == id);
    state = state.where((j) => j.id != id).toList();
    ref
        .read(auditLogProvider.notifier)
        .log('Removed job', 'Job', '${job.title} · ${job.company}');
  }
}

final moderationJobsProvider =
    NotifierProvider<ModerationJobs, List<ModerationJob>>(ModerationJobs.new);

class AdminUsers extends Notifier<List<AdminUserRecord>> {
  @override
  List<AdminUserRecord> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : [
          AdminUserRecord(
            id: 'u1',
            name: 'Ayesha Khan',
            email: 'seeker@sharkhire.app',
            role: AppRole.jobSeeker,
            joinedAt: _ago(days: 12),
            location: 'Lahore',
          ),
          AdminUserRecord(
            id: 'u2',
            name: 'Bilal Ahmed',
            email: 'employer@sharkhire.app',
            role: AppRole.employer,
            joinedAt: _ago(days: 30),
            location: 'Lahore',
          ),
          AdminUserRecord(
            id: 'u3',
            name: 'Ali Raza',
            email: 'ali.raza@example.com',
            role: AppRole.jobSeeker,
            joinedAt: _ago(days: 4),
            location: 'Lahore',
          ),
          AdminUserRecord(
            id: 'u4',
            name: 'Sara Khan',
            email: 'sara.khan@example.com',
            role: AppRole.jobSeeker,
            joinedAt: _ago(days: 6),
            location: 'Karachi',
          ),
          AdminUserRecord(
            id: 'u5',
            name: 'Nadia Hussain',
            email: 'nadia@harborco.example',
            role: AppRole.employer,
            joinedAt: _ago(days: 18),
            location: 'Remote',
          ),
          AdminUserRecord(
            id: 'u6',
            name: 'Spam Account',
            email: 'spam.account@example.com',
            role: AppRole.jobSeeker,
            joinedAt: _ago(days: 3),
            status: AccountStatus.blocked,
          ),
          AdminUserRecord(
            id: 'u7',
            name: 'Hamza Ahmed',
            email: 'hamza@example.com',
            role: AppRole.jobSeeker,
            joinedAt: _ago(days: 9),
            location: 'Islamabad',
          ),
        ];

  void setStatus(String id, AccountStatus s) {
    final u = state.firstWhere((x) => x.id == id);
    state = [for (final x in state) x.id == id ? x.withStatus(s) : x];
    final verb = switch (s) {
      AccountStatus.active => 'Reactivated user',
      AccountStatus.blocked => 'Blocked user',
      AccountStatus.deactivated => 'Deactivated user',
    };
    ref.read(auditLogProvider.notifier).log(verb, 'User', u.email);
  }
}

final adminUsersProvider = NotifierProvider<AdminUsers, List<AdminUserRecord>>(
  AdminUsers.new,
);

class AdminCompanies extends Notifier<List<CompanyRecord>> {
  @override
  List<CompanyRecord> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : [
          CompanyRecord(
            id: 'c1',
            name: 'Indus Ledger',
            owner: 'Bilal Ahmed',
            joinedAt: _ago(days: 30),
            industry: 'Fintech',
            website: 'indusledger.example',
            verification: Verification.verified,
            jobCount: 6,
          ),
          CompanyRecord(
            id: 'c2',
            name: 'Harbor & Co.',
            owner: 'Nadia Hussain',
            joinedAt: _ago(days: 18),
            industry: 'Software',
            website: 'harborco.example',
            jobCount: 2,
          ),
          CompanyRecord(
            id: 'c3',
            name: 'Kestrel Systems',
            owner: 'Faisal Noor',
            joinedAt: _ago(days: 25),
            industry: 'IT services',
            verification: Verification.verified,
            jobCount: 4,
          ),
          CompanyRecord(
            id: 'c4',
            name: 'Bluefin Media',
            owner: 'Mehwish Ali',
            joinedAt: _ago(days: 2),
            industry: 'Media',
            jobCount: 0,
          ),
        ];

  void verify(String id, Verification v) {
    final c = state.firstWhere((x) => x.id == id);
    state = [for (final x in state) x.id == id ? x.withVerification(v) : x];
    ref
        .read(auditLogProvider.notifier)
        .log(
          v == Verification.verified
              ? 'Verified employer'
              : 'Rejected employer verification',
          'Company',
          c.name,
        );
  }
}

final adminCompaniesProvider =
    NotifierProvider<AdminCompanies, List<CompanyRecord>>(AdminCompanies.new);

final adminApplicationsProvider = Provider<List<ApplicationRecord>>(
  (ref) => [
    ApplicationRecord(
      id: 'a1',
      candidate: 'Ali Raza',
      job: 'Senior Flutter Developer',
      company: 'Indus Ledger',
      status: ApplicationStatus.submitted,
      submittedAt: _ago(hours: 3),
    ),
    ApplicationRecord(
      id: 'a2',
      candidate: 'Sara Khan',
      job: 'Senior Flutter Developer',
      company: 'Indus Ledger',
      status: ApplicationStatus.underReview,
      submittedAt: _ago(days: 1),
    ),
    ApplicationRecord(
      id: 'a3',
      candidate: 'Hamza Ahmed',
      job: 'UI Designer',
      company: 'Indus Ledger',
      status: ApplicationStatus.shortlisted,
      submittedAt: _ago(days: 3),
    ),
    ApplicationRecord(
      id: 'a4',
      candidate: 'Ayesha Khan',
      job: 'QA Engineer',
      company: 'Harbor & Co.',
      status: ApplicationStatus.interview,
      submittedAt: _ago(days: 14),
    ),
    ApplicationRecord(
      id: 'a5',
      candidate: 'Ayesha Khan',
      job: 'Growth Marketing Intern',
      company: 'Bluefin Media',
      status: ApplicationStatus.rejected,
      submittedAt: _ago(days: 18),
    ),
    ApplicationRecord(
      id: 'a6',
      candidate: 'Usman Tariq',
      job: 'Senior Flutter Developer',
      company: 'Indus Ledger',
      status: ApplicationStatus.withdrawn,
      submittedAt: _ago(days: 8),
    ),
  ],
);

final externalListingsProvider = Provider<List<ExternalListing>>(
  (ref) => [
    ExternalListing(
      providerJobId: 'js-8812',
      title: 'Python Backend Developer',
      company: 'Kestrel Systems',
      country: 'PK',
      publisher: 'Company careers site',
      fetchedAt: _ago(hours: 2),
      expiresAt: DateTime.now().add(const Duration(days: 12)),
    ),
    ExternalListing(
      providerJobId: 'js-8813',
      title: 'AI / ML Engineer',
      company: 'Datawave Labs',
      country: 'Remote',
      publisher: 'Job board',
      fetchedAt: _ago(hours: 2),
      expiresAt: DateTime.now().add(const Duration(days: 12)),
    ),
    ExternalListing(
      providerJobId: 'js-8790',
      title: 'Product Designer, AI Experiences',
      company: 'Northwind Studio',
      country: 'AE',
      publisher: 'Job board',
      fetchedAt: _ago(days: 5),
      expiresAt: DateTime.now().add(const Duration(days: 9)),
    ),
    ExternalListing(
      providerJobId: 'js-8601',
      title: 'Cloud DevOps Engineer',
      company: 'Meridian Cloud',
      country: 'GB',
      publisher: 'Company careers site',
      fetchedAt: _ago(days: 16),
      expiresAt: _ago(days: 2),
    ),
  ],
);

final apiLogsProvider = Provider<List<ApiRequestLog>>(
  (ref) => [
    ApiRequestLog(
      at: _ago(hours: 1),
      endpoint: '/search-v2',
      query: 'Flutter developer jobs in Pakistan',
      statusCode: 200,
      latencyMs: 842,
      results: 10,
    ),
    ApiRequestLog(
      at: _ago(hours: 2),
      endpoint: '/search-v2',
      query: 'Remote AI engineer jobs worldwide',
      statusCode: 200,
      latencyMs: 1130,
      results: 10,
    ),
    ApiRequestLog(
      at: _ago(hours: 5),
      endpoint: '/job-details',
      query: 'js-8790',
      statusCode: 200,
      latencyMs: 410,
      results: 1,
    ),
    ApiRequestLog(
      at: _ago(hours: 9),
      endpoint: '/search-v2',
      query: 'Data analyst jobs in United Kingdom',
      statusCode: 429,
      latencyMs: 120,
      results: 0,
    ),
    ApiRequestLog(
      at: _ago(days: 1),
      endpoint: '/search-v2',
      query: 'Junior Python developer jobs in UAE',
      statusCode: 200,
      latencyMs: 960,
      results: 8,
    ),
  ],
);

/// Requests used this month against the JSearch plan limit (guide §3.9).
final jsearchUsageProvider = Provider<int>((ref) => 132);

class AdminCategories extends Notifier<List<CategoryRecord>> {
  @override
  List<CategoryRecord> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : const [
          CategoryRecord(
            name: 'Software',
            skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'React'],
          ),
          CategoryRecord(
            name: 'Data / AI',
            skills: ['SQL', 'Machine Learning', 'Pandas', 'Power BI'],
          ),
          CategoryRecord(
            name: 'Design',
            skills: ['Figma', 'Prototyping', 'User research'],
          ),
          CategoryRecord(
            name: 'Marketing',
            skills: ['SEO', 'Content', 'Paid social'],
          ),
          CategoryRecord(name: 'Finance', skills: ['Accounting', 'Excel']),
        ];

  void addCategory(String name) {
    state = [...state, CategoryRecord(name: name)];
    ref.read(auditLogProvider.notifier).log('Added category', 'Category', name);
  }

  void addSkill(String category, String skill) {
    state = [
      for (final c in state)
        c.name == category
            ? CategoryRecord(name: c.name, skills: [...c.skills, skill])
            : c,
    ];
    ref
        .read(auditLogProvider.notifier)
        .log('Added skill', 'Category', '$category · $skill');
  }
}

final adminCategoriesProvider =
    NotifierProvider<AdminCategories, List<CategoryRecord>>(
      AdminCategories.new,
    );

class Announcements extends Notifier<List<Announcement>> {
  @override
  List<Announcement> build() =>
      // Real API: no sample data until this screen is connected.
      ApiConfig.isConfigured
      ? const []
      : [
          Announcement(
            title: 'Welcome to SharkHire',
            message:
                'Upload your CV to get matched with jobs in Pakistan and abroad.',
            audience: Audience.jobSeekers,
            sentAt: _ago(days: 7),
          ),
        ];

  Future<void> send(String title, String message, Audience audience) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = [
      Announcement(
        title: title,
        message: message,
        audience: audience,
        sentAt: DateTime.now(),
      ),
      ...state,
    ];
    ref
        .read(auditLogProvider.notifier)
        .log(
          'Sent announcement',
          'Notification',
          title,
          details: audience.label,
        );
  }
}

final announcementsProvider =
    NotifierProvider<Announcements, List<Announcement>>(Announcements.new);

class AdminSettings extends Notifier<PlatformSettings> {
  @override
  PlatformSettings build() => const PlatformSettings();

  void save(PlatformSettings s) {
    state = s;
    ref
        .read(auditLogProvider.notifier)
        .log('Updated settings', 'Settings', 'Platform preferences');
  }
}

final platformSettingsProvider =
    NotifierProvider<AdminSettings, PlatformSettings>(AdminSettings.new);

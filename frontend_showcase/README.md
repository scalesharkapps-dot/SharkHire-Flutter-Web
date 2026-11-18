# SharkHire Frontend Showcase

Real screenshots of every implemented screen of the SharkHire Flutter mobile app
(Android and iOS), captured 14 November 2026.

- `index.html`: presentation page with the gallery, progress and audit summary (open it in a browser).
- `FRONTEND_AUDIT_REPORT.md`: full audit of the frontend.
- `screenshots/`: the PNG files, one folder per area.

## How the screenshots are made

They are real renders of the app's own widgets, not mock-ups. The script
`mobile_app/tool/showcase/capture_screens_test.dart` starts the real app in
Flutter's test engine on a 390 × 844 pt phone screen with a status bar and home
indicator, using the app's bundled fonts, logo and its built-in sample data.
They are not photos from a physical phone: no device build exists yet.

To regenerate after UI changes:

```bash
cd mobile_app
flutter test tool/showcase/capture_screens_test.dart
cd ../frontend_showcase
python -I tool/build_showcase.py
```

## Gallery (60 screens)

### Authentication

Sign up, sign in and first-time setup.

| Screen | Description |
|---|---|
| [Splash](screenshots/01_authentication/01_splash.png) | Animated Scale Shark logo while the app starts and restores the session. |
| [Welcome](screenshots/01_authentication/02_welcome.png) | First screen for new users: three reasons to use SharkHire, Create account, Log in, and a link for employers. |
| [Log in](screenshots/01_authentication/03_login.png) | Email and password with validation and Forgot password. Continue with Google shows a note until the account service is connected. Demo accounts appear in preview builds only. |
| [Register](screenshots/01_authentication/04_register.png) | Create an account as a Job seeker or an Employer, with a password-strength hint and the terms notice. |
| [Forgot password](screenshots/01_authentication/05_forgot_password.png) | Request a password-reset link by email. |
| [Verify email](screenshots/01_authentication/06_verify_email.png) | Shown after sign-up until the email is confirmed, with Resend email and Use a different email. |
| [Job preferences](screenshots/01_authentication/07_job_preferences.png) | One-time onboarding (step 1 of 2): preferred location, job categories and employment type. |

### Job Seeker

Home, profile and account screens for job seekers.

| Screen | Description |
|---|---|
| [Home](screenshots/02_job_seeker/01_home.png) | Greeting, search, match/saved/applied counts, a prompt to upload a CV, and recommended jobs. |
| [Profile](screenshots/02_job_seeker/02_profile.png) | Profile strength, the active CV with Review and Replace, and the Premium offer. |
| [Profile menu](screenshots/02_job_seeker/03_profile_menu.png) | Job activity (CV, applications, saved jobs, alerts, preferences) and account links. |
| [Notifications](screenshots/02_job_seeker/04_notifications.png) | New matches, application updates and reminders; swipe to dismiss with Undo. |
| [Job alerts](screenshots/02_job_seeker/05_job_alerts.png) | Saved searches with region and frequency; SharkHire checks for new jobs and notifies the user. |
| [Subscription](screenshots/02_job_seeker/06_subscription.png) | Premium plan: 3-day free trial, then $10/month, local price note, benefits, Restore purchases and terms. |
| [Settings](screenshots/02_job_seeker/07_settings.png) | Push-notification switches, weekly email digest, edit profile, change password and log out. |
| [Privacy and security](screenshots/02_job_seeker/08_privacy_security.png) | How the CV is kept private, consent for AI-assisted CV reading, request a copy of data, delete account. |
| [Help and support](screenshots/02_job_seeker/09_help_support.png) | Common questions and how to email the SharkHire team. |
| [Edit profile](screenshots/02_job_seeker/10_edit_profile.png) | Change name, headline, location and phone. |
| [Edit job preferences](screenshots/02_job_seeker/11_edit_job_preferences.png) | Update location, categories, employment type and work mode at any time. |

### Job Search

Finding Pakistan and international jobs.

| Screen | Description |
|---|---|
| [Explore](screenshots/03_job_search/01_explore.png) | Keyword search, quick filters, sort and result count across internal and external jobs. |
| [Filter sheet](screenshots/03_job_search/02_filters.png) | Bottom sheet with sort, region, employment type, work mode and how to apply. |
| [Job details (in-app)](screenshots/03_job_search/03_job_details_internal.png) | An employer job posted on SharkHire: verified badge, match score with reasons, Apply now. |
| [Job information](screenshots/03_job_search/04_job_details_info.png) | Salary, posted date, required skills (skills on the user's CV shown in green) and the role description. |
| [Job details (external)](screenshots/03_job_search/05_job_details_external.png) | A job from an external source: source badge, a note that only the click is recorded, and Apply on employer site. |
| [Saved jobs](screenshots/03_job_search/06_saved_jobs.png) | Bookmarked jobs, most recently saved first. |

### Job Recommendations

AI matching results after the CV is processed.

| Screen | Description |
|---|---|
| [Home with CV](screenshots/04_recommendations/01_home_with_cv.png) | With a processed CV, Home leads with today's strong matches. |
| [Recommended jobs](screenshots/04_recommendations/02_recommended_jobs.png) | Job cards with match percentage, source and posted time. |
| [Categories and recent jobs](screenshots/04_recommendations/03_categories_and_recent.png) | Browse by category, an active job alert, and recently posted jobs. |
| [Match explanation](screenshots/04_recommendations/04_match_explanation.png) | Why a remote AI job matches: score ring, match level and plain-language reasons. |

### CV Management

Upload a CV and check what was read from it.

| Screen | Description |
|---|---|
| [Upload CV](screenshots/05_cv_management/01_upload_cv.png) | Pick a PDF or DOCX (max 5 MB) with a clear privacy note. |
| [File selected](screenshots/05_cv_management/02_file_selected.png) | Chosen file with name and size, ready to upload and analyse. |
| [Processing](screenshots/05_cv_management/03_processing.png) | Four visible steps: check the file, read the CV, build the candidate profile, find matching jobs. |
| [Review profile](screenshots/05_cv_management/04_review_profile.png) | Extracted name, location, experience and skills; remove or add skills before matching. |
| [Review experience](screenshots/05_cv_management/05_review_experience.png) | Edit extracted experience, education, and certifications and projects. |
| [Invalid file rejected](screenshots/05_cv_management/06_invalid_file_rejected.png) | A non-CV file type is refused with a clear message. |

### Applications

Applying in-app and tracking every application.

| Screen | Description |
|---|---|
| [Apply form](screenshots/06_applications/01_apply_form.png) | The active CV to send, an optional cover letter with character count, and a privacy note. |
| [Application sent](screenshots/06_applications/02_application_sent.png) | Confirmation, an offer to get alerts for similar jobs, and Track application. |
| [My applications](screenshots/06_applications/03_my_applications.png) | All, Active and Closed tabs with status chips and employer notes. |
| [Application timeline](screenshots/06_applications/04_application_timeline.png) | Progress stepper and dated history, including employer notes such as interview times. |
| [Withdraw](screenshots/06_applications/05_withdraw_option.png) | Active applications can be withdrawn from the details screen. |

### Employer

Employer app: post jobs and manage applicants.

| Screen | Description |
|---|---|
| [Overview](screenshots/07_employer/01_overview.png) | Counts for active, pending, applicants and shortlisted, Post a job, and jobs that need attention. |
| [Manage jobs](screenshots/07_employer/02_manage_jobs.png) | Jobs by Pending, Published, Rejected and Closed, with applicant and view counts, Close and Edit. |
| [Create job](screenshots/07_employer/03_create_job.png) | Title, skills, experience, education, location, work mode, employment type and more; Submit for approval. |
| [Fix rejected job](screenshots/07_employer/04_fix_rejected_job.png) | The admin's rejection reason is shown so the employer can fix and resubmit. |
| [Applicants](screenshots/07_employer/05_applicants.png) | Candidates by status (New, Under review, Shortlisted, Interview, Rejected). |
| [Candidate details](screenshots/07_employer/06_candidate_details.png) | Match score, skills, experience and education, CV by secure link, and Choose a new status. |
| [Company profile](screenshots/07_employer/07_company_profile.png) | Logo, verified-employer badge, and company details (website, industry, size, headquarters, about). |

### Admin

Admin panel inside the mobile app.

| Screen | Description |
|---|---|
| [Overview](screenshots/08_admin/01_overview.png) | Platform totals and jobs waiting for approval, with Approve and Reject. |
| [Job approvals](screenshots/08_admin/02_job_approvals.png) | Pending, Published and Rejected tabs; rejected jobs go back to the employer with the reason. |
| [Users](screenshots/08_admin/03_users.png) | Search users and filter by role, with account status. |
| [More modules](screenshots/08_admin/04_more_modules.png) | Entry point to every other admin tool. |
| [Employers](screenshots/08_admin/05_employers.png) | Verify or reject employer companies after checking their details. |
| [Applications](screenshots/08_admin/06_applications.png) | All in-app applications, filterable by each of the 7 statuses. |
| [External listings](screenshots/08_admin/07_external_listings.png) | Imported jobs with source, fetch time and expiry; expired listings are hidden from job seekers. |
| [CV reports](screenshots/08_admin/08_cv_reports.png) | Monthly upload, processed and failed counts, recent failures with reasons, and the retention policy. |
| [Categories and skills](screenshots/08_admin/09_categories.png) | Manage the categories and skills used in onboarding, search and matching. |
| [Announcements](screenshots/08_admin/10_announcements.png) | Write an announcement for everyone, job seekers or employers, and see sent ones. |
| [API monitoring](screenshots/08_admin/11_api_monitoring.png) | JSearch requests used against the monthly limit, error rate and recent requests. |
| [Analytics](screenshots/08_admin/12_analytics.png) | Active users, new CVs, jobs published, external apply clicks, and weekly charts (example data until the analytics API is connected). |
| [Audit logs](screenshots/08_admin/13_audit_logs.png) | Every admin action with who, what and when; entries can't be edited. |
| [Platform settings](screenshots/08_admin/14_platform_settings.png) | Job-approval switch, maintenance banner, listing lifetime, CV retention and JSearch monthly limit. |

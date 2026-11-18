"""Screen list for the SharkHire frontend showcase.

One source for README.md and index.html. Run `python -I tool/build_showcase.py`
from `frontend_showcase/` after re-capturing screenshots.
"""

CATEGORIES = [
    ("01_authentication", "Authentication", "Sign up, sign in and first-time setup.", [
        ("01_splash", "Splash", "Animated Scale Shark logo while the app starts and restores the session."),
        ("02_welcome", "Welcome", "First screen for new users: three reasons to use SharkHire, Create account, Log in, and a link for employers."),
        ("03_login", "Log in", "Email and password with validation and Forgot password. Continue with Google shows a note until the account service is connected. Demo accounts appear in preview builds only."),
        ("04_register", "Register", "Create an account as a Job seeker or an Employer, with a password-strength hint and the terms notice."),
        ("05_forgot_password", "Forgot password", "Request a password-reset link by email."),
        ("06_verify_email", "Verify email", "Shown after sign-up until the email is confirmed, with Resend email and Use a different email."),
        ("07_job_preferences", "Job preferences", "One-time onboarding (step 1 of 2): preferred location, job categories and employment type."),
    ]),
    ("02_job_seeker", "Job Seeker", "Home, profile and account screens for job seekers.", [
        ("01_home", "Home", "Greeting, search, match/saved/applied counts, a prompt to upload a CV, and recommended jobs."),
        ("02_profile", "Profile", "Profile strength, the active CV with Review and Replace, and the Premium offer."),
        ("03_profile_menu", "Profile menu", "Job activity (CV, applications, saved jobs, alerts, preferences) and account links."),
        ("04_notifications", "Notifications", "New matches, application updates and reminders; swipe to dismiss with Undo."),
        ("05_job_alerts", "Job alerts", "Saved searches with region and frequency; SharkHire checks for new jobs and notifies the user."),
        ("06_subscription", "Subscription", "Premium plan: 3-day free trial, then $10/month, local price note, benefits, Restore purchases and terms."),
        ("07_settings", "Settings", "Push-notification switches, weekly email digest, edit profile, change password and log out."),
        ("08_privacy_security", "Privacy and security", "How the CV is kept private, consent for AI-assisted CV reading, request a copy of data, delete account."),
        ("09_help_support", "Help and support", "Common questions and how to email the SharkHire team."),
        ("10_edit_profile", "Edit profile", "Change name, headline, location and phone."),
        ("11_edit_job_preferences", "Edit job preferences", "Update location, categories, employment type and work mode at any time."),
    ]),
    ("03_job_search", "Job Search", "Finding Pakistan and international jobs.", [
        ("01_explore", "Explore", "Keyword search, quick filters, sort and result count across internal and external jobs."),
        ("02_filters", "Filter sheet", "Bottom sheet with sort, region, employment type, work mode and how to apply."),
        ("03_job_details_internal", "Job details (in-app)", "An employer job posted on SharkHire: verified badge, match score with reasons, Apply now."),
        ("04_job_details_info", "Job information", "Salary, posted date, required skills (skills on the user's CV shown in green) and the role description."),
        ("05_job_details_external", "Job details (external)", "A job from an external source: source badge, a note that only the click is recorded, and Apply on employer site."),
        ("06_saved_jobs", "Saved jobs", "Bookmarked jobs, most recently saved first."),
    ]),
    ("04_recommendations", "Job Recommendations", "AI matching results after the CV is processed.", [
        ("01_home_with_cv", "Home with CV", "With a processed CV, Home leads with today's strong matches."),
        ("02_recommended_jobs", "Recommended jobs", "Job cards with match percentage, source and posted time."),
        ("03_categories_and_recent", "Categories and recent jobs", "Browse by category, an active job alert, and recently posted jobs."),
        ("04_match_explanation", "Match explanation", "Why a remote AI job matches: score ring, match level and plain-language reasons."),
    ]),
    ("05_cv_management", "CV Management", "Upload a CV and check what was read from it.", [
        ("01_upload_cv", "Upload CV", "Pick a PDF or DOCX (max 5 MB) with a clear privacy note."),
        ("02_file_selected", "File selected", "Chosen file with name and size, ready to upload and analyse."),
        ("03_processing", "Processing", "Four visible steps: check the file, read the CV, build the candidate profile, find matching jobs."),
        ("04_review_profile", "Review profile", "Extracted name, location, experience and skills; remove or add skills before matching."),
        ("05_review_experience", "Review experience", "Edit extracted experience, education, and certifications and projects."),
        ("06_invalid_file_rejected", "Invalid file rejected", "A non-CV file type is refused with a clear message."),
    ]),
    ("06_applications", "Applications", "Applying in-app and tracking every application.", [
        ("01_apply_form", "Apply form", "The active CV to send, an optional cover letter with character count, and a privacy note."),
        ("02_application_sent", "Application sent", "Confirmation, an offer to get alerts for similar jobs, and Track application."),
        ("03_my_applications", "My applications", "All, Active and Closed tabs with status chips and employer notes."),
        ("04_application_timeline", "Application timeline", "Progress stepper and dated history, including employer notes such as interview times."),
        ("05_withdraw_option", "Withdraw", "Active applications can be withdrawn from the details screen."),
    ]),
    ("07_employer", "Employer", "Employer app: post jobs and manage applicants.", [
        ("01_overview", "Overview", "Counts for active, pending, applicants and shortlisted, Post a job, and jobs that need attention."),
        ("02_manage_jobs", "Manage jobs", "Jobs by Pending, Published, Rejected and Closed, with applicant and view counts, Close and Edit."),
        ("03_create_job", "Create job", "Title, skills, experience, education, location, work mode, employment type and more; Submit for approval."),
        ("04_fix_rejected_job", "Fix rejected job", "The admin's rejection reason is shown so the employer can fix and resubmit."),
        ("05_applicants", "Applicants", "Candidates by status (New, Under review, Shortlisted, Interview, Rejected)."),
        ("06_candidate_details", "Candidate details", "Match score, skills, experience and education, CV by secure link, and Choose a new status."),
        ("07_company_profile", "Company profile", "Logo, verified-employer badge, and company details (website, industry, size, headquarters, about)."),
    ]),
    ("08_admin", "Admin", "Admin panel inside the mobile app.", [
        ("01_overview", "Overview", "Platform totals and jobs waiting for approval, with Approve and Reject."),
        ("02_job_approvals", "Job approvals", "Pending, Published and Rejected tabs; rejected jobs go back to the employer with the reason."),
        ("03_users", "Users", "Search users and filter by role, with account status."),
        ("04_more_modules", "More modules", "Entry point to every other admin tool."),
        ("05_employers", "Employers", "Verify or reject employer companies after checking their details."),
        ("06_applications", "Applications", "All in-app applications, filterable by each of the 7 statuses."),
        ("07_external_listings", "External listings", "Imported jobs with source, fetch time and expiry; expired listings are hidden from job seekers."),
        ("08_cv_reports", "CV reports", "Monthly upload, processed and failed counts, recent failures with reasons, and the retention policy."),
        ("09_categories", "Categories and skills", "Manage the categories and skills used in onboarding, search and matching."),
        ("10_announcements", "Announcements", "Write an announcement for everyone, job seekers or employers, and see sent ones."),
        ("11_api_monitoring", "API monitoring", "JSearch requests used against the monthly limit, error rate and recent requests."),
        ("12_analytics", "Analytics", "Active users, new CVs, jobs published, external apply clicks, and weekly charts (example data until the analytics API is connected)."),
        ("13_audit_logs", "Audit logs", "Every admin action with who, what and when; entries can't be edited."),
        ("14_platform_settings", "Platform settings", "Job-approval switch, maintenance banner, listing lifetime, CV retention and JSearch monthly limit."),
    ]),
]

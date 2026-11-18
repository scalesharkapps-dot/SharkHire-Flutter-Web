"""Builds README.md and index.html for the SharkHire frontend showcase.

Run from `frontend_showcase/`:  python -I tool/build_showcase.py
Screenshots come from `mobile_app/tool/showcase/capture_screens_test.dart`.
Update FACTS below when tests or milestones change.
"""
import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screens import CATEGORIES  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FACTS = {
    "date": "14 November 2026",
    "tests": 145,
    "test_files": 11,
    "screens": sum(len(c[3]) for c in CATEGORIES),
}

# (milestone, status, note) – status: done | partial | pending
PROGRESS = [
    ("M0 Foundation", "done", "Project, brand theme, routing, Home, Explore, Saved, Profile"),
    ("M1 Authentication and onboarding", "partial", "All screens and role-based routing tested; runs on a mock sign-in service"),
    ("M2 CV upload, processing and review", "done", "Mock and API repository both in place"),
    ("M3 Job details, match explanation, apply", "done", "Internal and external apply paths"),
    ("M4 Applications, notifications, account", "partial", "UI tested; subscription purchase simulated, push notifications not wired"),
    ("M5 Employer app", "partial", "UI tested; data kept in memory until the employer API exists"),
    ("M6 Admin panel in the mobile app", "partial", "UI tested; data kept in memory until the admin API exists"),
    ("QA: states, small and large phones, accessibility", "done", "320 px and 430 px layouts, tap targets, contrast"),
    ("M7 Backend-compatibility layer", "partial", "Done for jobs, job details and CV; other areas pending"),
    ("Android and iOS device builds", "pending", "Needs the Android SDK; iOS needs macOS or Codemagic"),
    ("Live backend integration", "pending", "Waits for the backend API and agreed JSON shapes"),
]
STATUS_LABEL = {"done": "Implemented and tested", "partial": "Partially implemented", "pending": "Pending"}

REMAINING = [
    ("Connect the backend", "API repositories for applications, saved jobs, notifications, profile, employer and admin; Supabase Auth; agree final JSON shapes with the backend team."),
    ("Build for devices", "Install the Android SDK and build the Android app; build iOS on macOS or Codemagic; test on real phones."),
    ("Store services", "Real in-app purchase for the subscription, push notifications, Google sign-in."),
    ("Legal texts", "Terms of Use and Privacy Policy from Scale Shark. The app shows a placeholder notice until then."),
    ("Polish", "Dark mode, Urdu localisation, and a designer review on physical phones."),
    ("Source control", "Move the project into the company GitHub repository."),
]

HERO_SHOTS = [
    ("02_job_seeker/01_home", "Job seeker home"),
    ("03_job_search/03_job_details_internal", "Job details with match reasons"),
    ("07_employer/01_overview", "Employer overview"),
]


def shot(cat, name):
    return f"screenshots/{cat}/{name}.png"


def build_readme():
    out = [
        "# SharkHire Frontend Showcase",
        "",
        "Real screenshots of every implemented screen of the SharkHire Flutter mobile app",
        f"(Android and iOS), captured {FACTS['date']}.",
        "",
        "- `index.html`: presentation page with the gallery, progress and audit summary (open it in a browser).",
        "- `FRONTEND_AUDIT_REPORT.md`: full audit of the frontend.",
        "- `screenshots/`: the PNG files, one folder per area.",
        "",
        "## How the screenshots are made",
        "",
        "They are real renders of the app's own widgets, not mock-ups. The script",
        "`mobile_app/tool/showcase/capture_screens_test.dart` starts the real app in",
        "Flutter's test engine on a 390 × 844 pt phone screen with a status bar and home",
        "indicator, using the app's bundled fonts, logo and its built-in sample data.",
        "They are not photos from a physical phone: no device build exists yet.",
        "",
        "To regenerate after UI changes:",
        "",
        "```bash",
        "cd mobile_app",
        "flutter test tool/showcase/capture_screens_test.dart",
        "cd ../frontend_showcase",
        "python -I tool/build_showcase.py",
        "```",
        "",
        f"## Gallery ({FACTS['screens']} screens)",
        "",
    ]
    for cat, title, blurb, items in CATEGORIES:
        out += [f"### {title}", "", blurb, "", "| Screen | Description |", "|---|---|"]
        for name, label, desc in items:
            out.append(f"| [{label}]({shot(cat, name)}) | {desc} |")
        out.append("")
    with open(os.path.join(ROOT, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(out))


def e(s):
    return html.escape(s, quote=True)


def build_html():
    nav = "".join(
        f'<a class="chip" href="#{cat}">{e(title)} <span>{len(items)}</span></a>'
        for cat, title, _, items in CATEGORIES
    )
    sections = []
    idx = 0
    for cat, title, blurb, items in CATEGORIES:
        figs = []
        for name, label, desc in items:
            figs.append(
                f'<figure class="shot"><button class="frame" type="button" data-i="{idx}" '
                f'aria-label="Enlarge {e(label)}"><img src="{shot(cat, name)}" alt="{e(title)}: {e(label)}" '
                f'loading="lazy" width="390" height="844"></button>'
                f'<figcaption><strong>{e(label)}</strong><span>{e(desc)}</span></figcaption></figure>'
            )
            idx += 1
        sections.append(
            f'<section class="cat" id="{cat}"><header class="cat-head"><h3>{e(title)}</h3>'
            f'<p>{e(blurb)} <span class="count">{len(items)} screens</span></p></header>'
            f'<div class="grid">{"".join(figs)}</div></section>'
        )
    progress = "".join(
        f'<tr><td>{e(m)}</td><td><span class="pill {s}">{STATUS_LABEL[s]}</span></td><td>{e(n)}</td></tr>'
        for m, s, n in PROGRESS
    )
    remaining = "".join(f"<li><strong>{e(t)}</strong><span>{e(d)}</span></li>" for t, d in REMAINING)
    hero = "".join(
        f'<img class="hero-phone p{i}" src="screenshots/{p}.png" alt="{e(a)}" width="390" height="844">'
        for i, (p, a) in enumerate(HERO_SHOTS)
    )
    data = ",".join(
        f'["{shot(cat, n)}","{e(t)} · {e(l)}"]'
        for cat, t, _, items in CATEGORIES for n, l, _ in items
    )
    page = TEMPLATE
    for k, v in {
        "{{NAV}}": nav, "{{SECTIONS}}": "".join(sections), "{{PROGRESS}}": progress,
        "{{REMAINING}}": remaining, "{{HERO}}": hero, "{{DATA}}": data,
        "{{DATE}}": FACTS["date"], "{{TESTS}}": str(FACTS["tests"]),
        "{{TEST_FILES}}": str(FACTS["test_files"]), "{{SCREENS}}": str(FACTS["screens"]),
    }.items():
        page = page.replace(k, v)
    with open(os.path.join(ROOT, "index.html"), "w", encoding="utf-8") as f:
        f.write(page)


with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "template.html"), encoding="utf-8") as f:
    TEMPLATE = f.read()

build_readme()
build_html()
print(f"Built README.md and index.html ({FACTS['screens']} screens)")

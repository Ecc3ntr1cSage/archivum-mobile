# Archivum Mobile

Archivum is a personal archive and daily-life companion built with Flutter. It brings notes, quotes, checklists, credentials, prayer tracking, personal finance, and AI-assisted search into one private, account-based app.

The app uses Supabase for authentication and persistent data, Riverpod for application state, and OpenRouter for the optional Archivum Agent experience.

## Features

- Email/password registration and sign-in.
- Optional Google OAuth registration flow.
- Notes and quotes with tags and color metadata.
- Indexes: checklist-style records with individual items and completion state.
- Account and credential records.
- Daily prayer completion tracking and history.
- Personal finance with financial accounts, income/expense tracking, transfers, recurring expense shortcuts, budgets, financial history, and insights.
- A home dashboard with recent activity and summaries.
- Archivum Agent, which can answer natural-language questions using the signed-in user's archived data.
- Light and dark themes.

## Tech Stack

| Area | Technology |
| --- | --- |
| Client | Flutter / Dart |
| State management | Riverpod |
| Backend | Supabase (Auth, Postgres, RPC) |
| AI integration | OpenRouter |
| HTTP | `http` |

## Requirements

- Flutter SDK compatible with Dart `^3.11.0`.
- A Supabase project with the project's database schema, Row Level Security policies, and RPC functions configured.
- Google OAuth configured in Supabase if the optional Google registration flow will be used.
- An OpenRouter API key if the Agent feature will be used.

## Getting Started

1. Install Flutter and confirm it is available:

   ```bash
   flutter doctor
   ```

2. Fetch dependencies:

   ```bash
   flutter pub get
   ```

3. Create a local `.env` file from the supplied template:

   ```bash
   Copy-Item .env.example .env
   ```

4. Set the required values in `.env`:

   ```dotenv
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-publishable-or-anon-key
   OPENROUTER_API_KEY=your-openrouter-key
   ```

5. Run the app on a connected device, emulator, or desktop target:

   ```bash
   flutter run
   ```

The app loads `.env` during startup before initializing Supabase. It will not run correctly with empty Supabase values.

## Backend Setup

Create and configure the Supabase project before using the app. The client expects authenticated, user-scoped access to the app's data tables and several RPC functions used by the dashboard, insights, and AI agent.

The exact schema, table relationships, column contracts, RPC names, and domain rules are maintained in [AGENTS.md](AGENTS.md). Keep that document aligned with the backend whenever the data model changes.

For a secure setup:

- Enable Row Level Security on every application table exposed through Supabase's Data API.
- Write policies that restrict each user's records to their own authenticated `user_id`.
- Configure the Google provider and redirect URLs in Supabase Auth before enabling Google-based registration in a distributed build.
- Use a Supabase publishable key (or legacy anon key) in the client. Never place a Supabase service-role or secret key in `.env` for this app.

## Environment Variables

| Variable | Purpose | Required |
| --- | --- | --- |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Client-safe Supabase publishable/anon key | Yes |
| `OPENROUTER_API_KEY` | Enables Archivum Agent requests | Only for Agent |

Do not commit `.env` or real keys. The `.env` file is bundled as a Flutter asset in the current app, which means `OPENROUTER_API_KEY` can be extracted from a distributed client build. For production, move Agent requests behind a trusted server or Supabase Edge Function and keep the OpenRouter key there.

## Common Commands

```bash
# Static analysis
flutter analyze

# Run automated tests
flutter test

# Run the app
flutter run

# Regenerate launcher icons after changing assets/icon/icon.png
dart run flutter_launcher_icons
```

## Project Layout

```text
lib/
  main.dart                 Application bootstrap and Supabase initialization
  src/
    app/                    App widget, auth gate, and main navigation shell
    core/                   Shared providers, theme, constants, errors, widgets
    features/               Feature-specific data, domain, and presentation code
assets/                     Application assets and launcher icon source
test/                       Flutter tests
```

Features are organized under `lib/src/features/`. Most keep data access in `data/`, models/contracts in `domain/`, and UI in `presentation/`. Shared services and repositories are accessed through Riverpod providers.

## Development Notes

- Keep user data isolated by the authenticated user in both client queries and Supabase RLS policies.
- Financial amounts are persisted as integer cents; convert only at the UI boundary.
- Finance uses `accounts` for financial accounts and `credentials` for saved login/account credentials.
- Finance tag breakdowns are stored in `transaction_splits`; recurring expense rows are templates and are excluded from normal totals.
- Prayer tracking uses a 05:00 local-time boundary for its active day.
- The Agent is intended to issue read-only database queries through the `run_agent_query` RPC.
- The current widget test covers the standardized login screen. Expand it as auth and onboarding flows evolve.

## Contributor Guidance

Use [AGENTS.md](AGENTS.md) as the repository-specific engineering reference when making changes or reviewing a diff. It records the authoritative database contract, project rules, validation expectations, and review checklist for Codex and other contributors.

After each completed task, review `README.md` and `AGENTS.md` and update any project context that changed. The docs are part of the deliverable.

This README intentionally stays focused on product context, setup, and operation. Put detailed implementation contracts in `AGENTS.md` rather than duplicating them here.

# AGENTS.md

## Project Overview

Archivum Mobile is a Flutter application backed by Supabase. It is organized by feature, uses Riverpod for state management and dependency injection, and stores most user data in Supabase tables scoped by `user_id`.

This file is the source of truth for future Codex sessions working in this repository.

## Context Maintenance Rule

- Treat repository context markdown updates as part of every task, not optional cleanup.
- After each completed task, review `AGENTS.md` and `README.md` and update whichever file is affected by the change.
- Update these files whenever a task changes product behavior, auth flows, setup steps, contributor workflow, schema expectations, file structure, or development rules.
- Keep responsibilities separate:
  - `AGENTS.md` is the implementation and contributor source of truth for Codex.
  - `README.md` is the human-facing product, setup, and development guide.
- If one file does not need changes for the task, leave it untouched only after confirming it still matches the codebase.

## Repository Structure

- `lib/main.dart`
  App bootstrap. Loads `.env`, initializes Supabase, and starts the Riverpod `ProviderScope`.

- `lib/src/app/`
  App-level widgets and navigation.
  - `app.dart`: top-level `MaterialApp`, theme selection, auth gate.
  - `shell.dart`: main signed-in shell with bottom navigation and add menu.

- `lib/src/core/`
  Shared infrastructure.
  - `constants/env.dart`: environment variable accessors.
  - `providers/`: shared Riverpod providers for Supabase and repositories.
  - `theme/`: app theming.
  - `widgets/`: shared UI components.
  - `errors/`: shared error types.

- `lib/src/features/`
  Feature-first organization. Most features follow `data/`, `domain/`, and `presentation/`.
  - `auth/`: sign-in, sign-up, auth state.
  - `accounts/`: credential/account storage.
  - `agent/`: AI chat backed by OpenRouter and Supabase RPC.
  - `finance/`: transaction entry and history.
  - `home/`: signed-in landing page.
  - `indexes/`: checklist/index records and child items.
  - `insights/`: analytics and derived summaries.
  - `notes/`: note CRUD.
  - `prayers/`: daily prayer tracking.
  - `quotes/`: quote CRUD.
  - `snippets/`: aggregated view over notes, quotes, and indexes.

- `assets/`
  Static assets, including app icon assets.

- `test/`
  Flutter widget tests. Current coverage is minimal and the default test appears stale relative to the current app.

- Platform folders: `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`
  Standard Flutter platform scaffolding. Avoid changes here unless the task is platform-specific.

## Architecture Notes

- State management uses `flutter_riverpod`.
- Supabase is the primary backend and source of persistent state.
- Repositories live under `lib/src/features/*/data/` and are usually exposed through providers in `lib/src/core/providers/`.
- The UI is feature-oriented, with domain models kept close to their features.
- `snippets` is not its own storage model; it aggregates multiple content types.

## Environment And Setup

Required environment variables are loaded from `.env`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OPENROUTER_API_KEY`

Reference file: `.env.example`

Common commands:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

If launcher icons are updated:

```bash
dart run flutter_launcher_icons
```

## Verified Data Model

These tables and RPCs are referenced directly in the current codebase and should be treated as the working schema unless the backend is intentionally changed.

### Tables

- `notes`
  - Columns used: `id`, `user_id`, `title`, `content`, `tag`, `color`, `created_at`
  - Behavior: ordered by `created_at DESC`

- `quotes`
  - Columns used: `id`, `user_id`, `content`, `author`, `tag`, `color`, `created_at`
  - Behavior: ordered by `created_at DESC`

- `credentials`
  - Columns used: `id`, `user_id`, `title`, `method`, `email`, `username`, `password`, `provider`, `tags`, `created_at`
  - Used by the Accounts feature

- `accounts`
  - Columns used: `id`, `user_id`, `name`, `type`, `institution`, `currency`, `opening_balance`, `created_at`
  - Used by the finance feature for bank, e-wallet, cash, and trading accounts
  - `current_balance` is derived in the app from `opening_balance` plus non-recurring transactions

- `indexes`
  - Columns used: `id`, `user_id`, `title`, `created_at`

- `index_items`
  - Columns used: `id`, `index_id`, `item`, `status`, `created_at`
  - Relationship: many `index_items` belong to one `indexes` row through `index_id`
  - Deletion behavior assumes FK cascade from `indexes` to `index_items`

- `prayers`
  - Columns used: `id`, `user_id`, `date`, `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`
  - One row represents a day of prayer completion flags

- `transactions`
  - Columns used: `id`, `user_id`, `account_id`, `status`, `amount`, `merchant`, `details`, `date`, `recurring`, `recurring_source_id`, `transfer_id`, `transfer_side`, `created_at`
  - Important: `amount` is stored as integer cents in the database and converted to `double` in the app
  - Important: `status` maps enum index values where `0 = income`, `1 = expense`, and `2 = transfer`
  - Important: `recurring = true` marks an expense template and should be excluded from balances, normal history, budgets, and insights
  - Transfers are linked by `transfer_id`; `transfer_side` is `out` or `in` because all amounts are stored positive

- `transaction_splits`
  - Columns used: `id`, `transaction_id`, `tag_id`, `amount`, `created_at`
  - Stores purchase breakdowns by tag as exact integer cents
  - Income and expense transactions should have one or more split rows, even when only one tag is used
  - Budget and financial insight tag totals are calculated from these rows, not from a `transactions.tag` column

- `budgets`
  - Columns used: `id`, `user_id`, `tag_id`, `currency`, `limit_amount`, `period`, `start_date`, `end_date`, `is_active`, `created_at`
  - Budget usage is derived from non-recurring expense split rows within the budget date range


- `tags`
  - Columns used: `id`, `user_id`, `text`, `feature`, `created_at`
  - Shared tag storage for multiple features

- `activity_logs`
  - Columns used in code: `activity_type`
  - Written to after many create/update/delete actions

### RPC Functions

- `get_insights`
  - Returns summary insight data for the insights feature

- `get_activity_last_7_days`
  - Returns recent activity counts for the home/dashboard experience

- `run_agent_query`
  - Used by the AI agent to execute generated SQL
  - Treat this as read-only from the app side

## Domain Rules And Project-Specific Behavior

- Always scope user-owned queries to the authenticated user.
  Most repositories already do this via `user_id`.

- Transactions:
  - Store money as integer cents in Supabase.
  - Convert to/from user-facing decimal amounts in Dart.
  - Preserve the `status` enum contract: `income = 0`, `expense = 1`, `transfer = 2`.
  - Store tag breakdowns in `transaction_splits`; percentage splits are UI input only and must be saved as exact cents.
  - Exclude `recurring = true` templates from posted ledger calculations.
  - Transfers should not affect income or expense totals; derive account impact from `transfer_side`.

- Prayers:
  - The app uses a custom "active day" boundary at 05:00 local time.
  - Before 05:00, actions still belong to the previous calendar day.

- Indexes:
  - Parent records live in `indexes`.
  - Child checklist items live in `index_items`.
  - Updating an index may require syncing created, updated, and deleted child rows.

- Agent feature:
  - Uses OpenRouter, not OpenAI directly.
  - The system prompt in `lib/src/features/agent/data/openrouter_service.dart` contains a mini schema contract for agent-generated SQL.
  - Agent queries should remain `SELECT`-only.

- Activity logging:
  - Many mutations also write an `activity_logs` row.
  - Preserve this side effect when changing repository write behavior.

## Coding Conventions

- Follow existing Flutter and Dart conventions already present in the repo.
- Prefer feature-local changes over cross-cutting rewrites.
- Keep repository logic in `data/`, data models/contracts in `domain/`, and UI in `presentation/`.
- Use Riverpod providers for dependency access instead of constructing shared services deep in widgets.
- Prefer small targeted edits over broad refactors unless the task explicitly asks for restructuring.
- Preserve existing naming unless there is a strong reason to change it.
- Avoid changing generated Flutter platform files unless required.

## Testing And Validation

Before finishing meaningful code changes, prefer:

```bash
flutter analyze
flutter test
```

Notes:

- `test/widget_test.dart` currently validates the standardized login screen and should be kept aligned with auth UI changes.
- If adding logic in repositories or domain models, consider adding focused tests instead of relying only on widget coverage.
- For Supabase-related changes, validate both data shape and authenticated-user filtering.

## Review Checklist For Codex

When using `/review`, pay special attention to:

- Does every user-owned query remain properly scoped by `user_id`?
- Are transaction amounts still handled as cents in storage?
- Are `activity_logs` writes preserved after mutations?
- Are index parent/child updates consistent between `indexes` and `index_items`?
- Are prayer-day calculations respecting the 05:00 reset rule?
- Are Riverpod providers still the main dependency access path?
- Did a change accidentally break the agent SQL assumptions or RPC contracts?

## Known Repository Notes

- The working tree may contain in-progress user changes; do not overwrite unrelated edits.

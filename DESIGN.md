# Archivum Mobile — UI Design Brief

## Product Identity

**Archivum** is a personal archive and daily-life companion — a private, all-in-one mobile app for managing notes, checklists, credentials, prayer tracking, and personal finance. The product occupies a distinctive space: part digital notebook, part vault, part daily ritual tracker. It serves a single user per account, with all data private and scoped to the authenticated user.

**Tone**: Quiet, capable, trustworthy. Not playful. Not corporate. Think *Field Notes notebook meets a well-organized safe*. The app should feel like a personal tool, not a social platform.

**Target audience**: Privacy-conscious individuals who want one app for personal knowledge, daily tracking, and financial awareness — people who value consistency, clarity, and a sense of order.

---

## 1. Design Problems to Solve

### 1.1 Inconsistent Visual Language Across Screens

The app has an existing `ArchivumTheme` token system (shadcn/ui-inspired) with ~25 semantic color tokens, but several screens bypass it:

- **Register page** uses hardcoded purple `#8A2CE2` as primary, ignores the theme entirely.
- **Add Credential page** uses `#8A2CE2` purple and `#F97316` orange directly, different from the warm orange/teal of the rest of the app.
- **Insights page** uses a dark purple background (`#191121`) with purple primary, inconsistent with the main app's `#121113` dark background.
- **Financial Insights** uses a green accent (`#10B981`) and dark teal gradients, again diverging.
- **Add Index page** uses a purple-ish dark theme (`#120D17`), different from the main app.

**Required fix**: Every screen must use the same `ArchivumTheme` token system. No hardcoded color values. The app should read as a single consistent product, not a collection of feature pages designed independently.

### 1.2 Visual Hierarchy and Information Density

Some pages are dense with form fields and controls:
- **Finance entry form** (Expense/Income/Transfer tabs) has many fields stacked vertically — amount, merchant, details, date picker, tag selection, split mode toggle, split rows, save buttons. This needs better spatial organization, perhaps grouped sections with visual breathing room.
- **Almanac page** tabs work well but the card list items could benefit from more visual distinction between content types (notes vs accounts vs indexes).
- **Insights page** is a dense scroll of stats. Numbers need better visual hierarchy — the most important KPIs should be immediately scannable, secondary details should recede.

### 1.3 Missing Micro-Interactions and Feedback

The app uses `AnimatedContainer` and `AnimatedOpacity` in places, but:
- Tab transitions are basic (no shared element transitions, no page-level animation).
- The activity chart on the home page is a static `CustomPaint` — no animation on load.
- Prayer rows have subtle animation, but the progress ring could animate on value change.
- No haptic feedback on key interactions (toggles, completions, saves).
- Navigation transitions are all default `MaterialPageRoute` — consider custom transitions for detail pages.

### 1.4 Empty States and Onboarding

Empty states exist but are minimal:
- Empty Almanac tabs show an icon and message.
- Empty prayer history shows a loading spinner.
- No guided onboarding for new users.
- First-time use of Finance shows "Create a finance account" text — but no visual cue to help users understand the flow.

### 1.5 Dark Mode Parity

The dark theme is well-defined but some screens (Register, AddCredential, Insights) use their own dark backgrounds and colors instead of the shared `_darkTokens`. This means dark mode is inconsistent across the app.

---

## 2. Design System — Tokens, Not Hardcoded Values

### 2.1 Color Palette (Existing `ArchivumTheme` — Must Be Used Consistently)

| Token | Light | Dark | Purpose |
|-------|-------|------|---------|
| `background` | `#FFFFFF` | `#121113` | Main canvas |
| `foreground` | `#111827` | `#C1C1C1` | Body text |
| `card` | `#FFFFFF` | `#121212` | Card surfaces |
| `cardForeground` | `#111827` | `#C1C1C1` | Card text |
| `primary` | `#D87943` | `#E78A53` | Primary actions, active states |
| `primaryForeground` | `#FFFFFF` | `#121113` | Text on primary |
| `secondary` | `#527575` | `#5F8787` | Secondary elements, alternative accent |
| `secondaryForeground` | `#FFFFFF` | `#121113` | Text on secondary |
| `muted` | `#F3F4F6` | `#222222` | Subtle backgrounds |
| `mutedForeground` | `#6B7280` | `#888888` | Secondary text, labels |
| `accent` | `#EEEEEE` | `#333333` | Accent backgrounds |
| `destructive` | `#EF4444` | `#5F8787` | Destructive actions |
| `border` | `#E5E7EB` | `#222222` | Borders, dividers |
| `input` | `#E5E7EB` | `#222222` | Input field backgrounds |
| `ring` | `#D87943` | `#E78A53` | Focus ring |

**Design rule**: Do not introduce new accent colors. If a feature needs a secondary color, use `secondary`. If it needs an accent for a specific purpose (like financial insights), use a semantic color from the chart palette (`chart1` through `chart5`).

### 2.2 Typography

**Current**: Uses `Typography.material2021()` with `w800`/`w900` for headings, `w700` for subheadings, `w500`/`w600` for body.

**Target**: 
- **Headings**: `w800`, tight letter-spacing (-0.3 to -0.6), sizes 28/24/21/17/15
- **Body**: `w500`/`w600`, 15px with 1.7 line height for readability
- **Labels/eyebrows**: Uppercase, `w800`, 11px, 0.9 letter-spacing, accent color
- **Monospace**: For passwords, secret values, codes
- No more than 3 font weights in a single view

### 2.3 Corner Radii

| Token | Value | Use |
|-------|-------|-----|
| `radius-sm` | 8px | Inputs, buttons |
| `radius-md` | 12px | Small cards, dialogs |
| `radius-lg` | 16-18px | Bottom nav, cards, panels |
| `radius-xl` | 20-22px | Hero cards, section cards |
| `radius-full` | 999px | Chips, tags, progress bars |

### 2.4 Shadows

- **Card shadow**: `y: 8, blur: 20, alpha: 0.06` (accent color tinted)
- **Elevated shadow**: `y: 8, blur: 18, alpha: 0.18` (black)
- **Bottom nav shadow**: `y: 8, blur: 28, spread: 2, alpha: 0.24` (black)
- **Glow effect**: `y: 0, blur: 40, spread: -4, alpha: 0.08` (primary color)

---

## 3. Screen-by-Screen Design Direction

### 3.1 Login / Register

**Current state**: Card-based layout, constrained width, icon + title + form fields. Register page has a desktop split layout that may be unnecessary for mobile.

**Design direction**:
- Keep the card-based centered layout for mobile simplicity.
- Remove the desktop split layout from Register — it's a mobile app first.
- Use the consistent `ArchivumTheme` tokens everywhere (no more `#8A2CE2` purple).
- The login card should feel like a welcome mat — warm, inviting, minimal.
- Add subtle animation: logo icon pulse, form field entrance stagger.
- Primary CTA should use the warm orange primary.
- Remove the Google OAuth SVG from Register and use a simple outlined button with a Google-colored icon.
- Add a "forgot password" link (currently missing).

### 3.2 Home (Dashboard)

**Current state**: Sliver-based scroll with sticky header, date banner, bento grid (Insights card + 3 quick-add squares + daily.dev card), activity tracker with custom chart.

**Design direction**:
- This is the app's most important screen. It should feel like a command center.
- **Sticky header**: Keep the avatar + greeting. Add a subtle glassmorphism effect on scroll (backdrop blur on the header).
- **Date banner**: The large date text works well. The "Everything looks good for today" subtitle is too generic — make it dynamic based on actual data (e.g., "3 prayers remaining, 2 notes today").
- **Bento grid**: The current layout is functional but plain. Consider:
  - Making the Insights card wider with a subtle gradient background.
  - Quick-add squares should be slightly taller (current 1.25 aspect ratio is a bit squat).
  - Add micro-icons or brief stat labels (e.g., "12 notes" badge on the Add Note card).
  - The daily.dev card feels out of place — consider moving it to a settings menu or removing it in favor of a native RSS/web feed feature.
- **Activity chart**: The custom painter is good. Add a **mount animation** on first load (chart slides up / draws in). The data dots should be slightly larger.
- **Overall spacing**: The current 100px bottom padding is generous. Maintain good whitespace but ensure the bento cards don't feel lost.

### 3.3 Almanac (Notes, Accounts, Indexes)

**Current state**: Tabbed view with search, card-based list items with consistent `_SurfaceCard` pattern.

**Design direction**:
- The tab bar pill design is good — keep it but make the active tab more distinct (increased contrast, maybe a subtle shadow).
- **Search field**: Current TextField is functional. Consider adding a debounced search with a clear button that appears only when text is entered.
- **Card list items**: 
  - Notes: The icon + title + preview + tag + metadata pattern works well.
  - Accounts: Add a visual indicator for SSO vs email-password (a small icon badge).
  - Indexes: Show completion progress as a thin bar at the bottom of each card, not just a chip.
- **Empty states**: Add a small illustration or icon animation. Currently just a static icon + text.
- **Pull-to-refresh**: Keep it, add a subtle haptic feedback.

### 3.4 Prayer Tracking

**Current state**: Simple daily page with progress ring, 5 prayer rows, history page with monthly heatmap.

**Design direction**:
- **Progress ring**: Animate the ring fill on toggle. The percentage text is good but small — make it more prominent.
- **Prayer rows**: The current design is clean. Add a subtle shimmer or pulse when toggling (loading state feedback). The "completed, tap to undo" / "pending, tap to mark" labels are helpful.
- **Next prayer**: The "Dhuhr is next" suggestion is good. Make it more visually prominent — maybe a highlighted row or a small banner.
- **Heatmap (history)**: This is a standout feature. Keep it, but:
  - Make the grid cells slightly larger for tap targets.
  - Add a brief month summary at the top (e.g., "82% completion rate this month").
  - The color intensity scale could use a cleaner legend.

### 3.5 Finance

**Current state**: Tabbed entry form (Expense/Income/Transfer) with account strip, budget strip, history page.

**Design direction**:
- **Account strip**: The horizontal scroll of `ChoiceChip` widgets is functional but cramped. Redesign as a horizontal scroll of small cards with account name, balance, and a colored dot for the selected account.
- **Entry form**: This is the most complex form in the app. Improve it:
  - Group fields into visual sections with section headers (e.g., "Transaction", "Details", "Tags & Splits").
  - The amount field should be the hero — larger font, prominent.
  - Date picker should be an inline date field with a calendar icon, not a full-width button.
  - Split rows (Exact/Percent) need better UX — the segmented button is fine, but the split rows themselves are visually dense. Use a card-per-split approach with clear visual boundaries.
  - The "Add tag" and "Split" buttons should be in a toolbar row below the splits.
  - Save button should be sticky at the bottom, not inline in the scroll.
- **Budget strip**: Currently a thin horizontal scroll at the bottom. This is important — make it more prominent. A small section with a "Create budget" button and budget cards showing progress bars.
- **History page**: The search + filter + list is functional. Add:
  - A summary bar at the top showing total income/expense for the filtered period.
  - Swipe-to-delete on transaction rows.
  - A "no transactions" illustration for empty state.

### 3.6 Insights / Analytics

**Current state**: Two pages — General Insights (Notes, Indexes, Faith, Accounts) and Financial Insights (Balance, Income/Expense, Trends, Tag breakdowns).

**Design direction**:
- **Consolidate**: These two pages are currently separate navigations. Consider merging them into one Insights page with sections, or keeping them separate but visually consistent.
- **General Insights**: 
  - The card-based layout is good but the purple color scheme (`#191121`) must be replaced with the standard `ArchivumTheme` colors.
  - The Faith Statistics section with the gradient background is visually interesting — keep the gradient approach but use the theme's primary/secondary colors instead of hardcoded purple.
  - The "Financial Insights" redirect card at the bottom is a good call-to-action. Keep it.
- **Financial Insights**:
  - The dark teal/green gradient hero card with the balance is the strongest visual element in the app. Keep it, but ensure it reads as part of the same app.
  - The bar chart is functional but basic. Consider a more polished chart using `fl_chart` or custom painter with better aesthetics.
  - Tag breakdowns with progress bars are good. Add a "View all" option for long lists.
- **Add animation**: Numbers should count up on first load. Charts should animate in.

### 3.7 Detail Pages (Note, Credential, Index)

**Current state**: Hero card at top + section card with content + edit mode with form fields + delete button.

**Design direction**:
- **Hero card**: The gradient + icon + title + chips pattern is one of the app's best visual elements. Keep it. Standardize it across all three detail pages.
- **View/edit toggle**: The current approach (AppBar actions to enter edit mode, then save/cancel) works well. Add a subtle animation when switching between view and edit modes.
- **Content section**: The `_SectionCard` with the dot + uppercase label is clean. Keep it.
- **Delete button**: Currently a full-width outlined button at the bottom. Consider moving it to a more discreet location (e.g., a menu) to prevent accidental taps.

---

## 4. Navigation and Shell

### 4.1 Bottom Navigation

**Current**: Floating pill-style bottom nav with 5 items — Home, Almanac, Add (center action), Prayer, Finance. The Add button opens a floating overlay menu.

**Design direction**:
- The pill design is distinctive and good. Keep it.
- The Add menu overlay (`_FloatingAddMenu`) is functional but the animation is basic (slide + fade). Add a spring animation with staggered item entrance.
- Consider adding a subtle icon animation when switching tabs (e.g., the selected icon scales up slightly or a dot appears with a spring animation).
- The active tab indicator (a dot below the icon) is subtle. Make it slightly larger or use a short underline bar for better visibility.

### 4.2 Page Transitions

**Current**: Default `MaterialPageRoute` sliding transitions.

**Design direction**:
- **List → Detail**: Use a shared element transition for the hero card (e.g., the card visually expands from the list item into the detail page).
- **Modal sheets**: Add a bottom sheet transition for split details, tag breakdowns, etc.
- **Tab switching**: Add a subtle slide animation when switching tabs in the Almanac and Finance pages.

---

## 5. Micro-Interactions and Animation

### 5.1 Required Animations

| Element | Animation | Trigger |
|---------|-----------|---------|
| Activity chart | Draw-in path + data dots appear sequentially | Page load |
| Prayer progress ring | Ring fill + percentage number count-up | On toggle |
| Prayer rows | Background color transition + icon swap | On toggle |
| Quick-add floating menu | Staggered spring entrance (each item delays 30ms) | On add button tap |
| Tab bar indicator | Spring slide to active tab | On tab switch |
| Bottom nav icons | Scale bounce on selection | On tap |
| Insight numbers | Count-up from 0 | On page load |
| Bar chart bars | Grow from bottom | On page load |
| Form validation | Shake animation on invalid field | On submit error |
| Save button | Loading spinner → checkmark → revert | On save complete |

### 5.2 Haptic Feedback

Add `HapticFeedback.lightImpact()` on:
- Prayer row toggle
- Checklist item toggle
- Tab switch
- Action button tap (save, delete confirm)
- Bottom nav item tap

### 5.3 Loading States

- Shimmer loading for card lists (currently uses plain `CircularProgressIndicator`).
- Skeleton screens for the home dashboard bento grid.
- Pulse animation on the prayer progress ring while waiting for data.

---

## 6. Layout and Responsiveness

### 6.1 Mobile-First

- The app is designed for phone screens (360-430dp width).
- All pages should work comfortably at 360dp width.
- No desktop-specific layouts (remove the Register page desktop split).

### 6.2 Spacing System

| Token | Value | Use |
|-------|-------|-----|
| `space-xs` | 4px | Between icons and text in buttons |
| `space-sm` | 8px | Between related elements |
| `space-md` | 12-14px | Between cards, sections |
| `space-lg` | 16-18px | Card padding, section padding |
| `space-xl` | 20-24px | Page margins, large gaps |
| `space-2xl` | 28-32px | Section spacing |

### 6.3 Safe Areas

- Respect `SafeArea` on all pages (currently done well).
- Bottom padding should account for the floating bottom nav (currently ~100px bottom padding in scroll views — this is good).

---

## 7. Accessibility

- All interactive elements should have a minimum 44x44 tap target.
- Color contrast ratios should meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text).
- The current `secondary` color on dark theme (`#5F8787` on `#121113`) may not meet contrast requirements for small text — verify and adjust.
- All icons should have semantic labels or tooltips.
- Animated elements should respect `Material`'s `animationDuration` scale and `disableAnimations` accessibility settings.

---

## 8. Implementation Priorities

### High Priority (Design Integrity)

1. **Eliminate all hardcoded colors** — every screen must use `ArchivumTheme` tokens.
2. **Standardize the hero card pattern** across all three detail pages.
3. **Fix the Register page** to use the app theme and remove the desktop layout.
4. **Fix the Insights theme** — replace purple colors with the app's primary/secondary.
5. **Fix the Add Credential page** — replace purple with app theme.
6. **Fix the Add Index page** — replace purple with app theme.

### Medium Priority (UX Polish)

7. **Add mount animations** to the home activity chart, prayer progress ring, and insight numbers.
8. **Improve the Finance entry form** — section grouping, larger amount field, sticky save button.
9. **Add haptic feedback** to key interactions.
10. **Improve empty states** with illustrations or animations.
11. **Add shimmer/skeleton loading** states.
12. **Improve the Add menu animation** — spring with staggered items.

### Low Priority (Enhancement)

13. **Custom page transitions** for detail pages (shared element).
14. **Tab bar slide animation**.
15. **Swipe-to-delete** on transaction history.
16. **Budget strip redesign** — more prominent placement.
17. **Forgot password flow** on login page.
18. **Dynamic dashboard subtitle** instead of static text.

---

## 9. Before and After

### 9.1 Consistency Audit

| Screen | Current Primary Color | Required Primary | Violation? |
|--------|----------------------|------------------|------------|
| Login | Orange (theme) | `primary` token | ✅ OK |
| Register | `#8A2CE2` purple | `primary` token | ❌ Violation |
| Home | Orange (theme) | `primary` token | ✅ OK |
| Almanac | Orange (theme) | `primary` token | ✅ OK |
| Add Note | Orange (theme) | `primary` token | ✅ OK |
| Note Detail | Orange (theme) | `primary` token | ✅ OK |
| Add Credential | `#8A2CE2` purple | `primary` token | ❌ Violation |
| Credential Detail | Teal `secondary` | `secondary` token | ⚠️ Acceptable (uses theme) |
| Add Index | `#8A2CE2` purple | `primary` token | ❌ Violation |
| Index Detail | Teal `secondary` | `secondary` token | ⚠️ Acceptable |
| Prayer | Orange (theme) | `primary` token | ✅ OK |
| Prayer History | Orange (theme) | `primary` token | ✅ OK |
| Finance | Orange/Teal | `primary`/`secondary` | ✅ OK |
| Finance History | Green/Red hardcoded | `chart1`/`chart5` | ⚠️ Partially — green needs mapping |
| Insights | Purple (`#191121`) | `background` token | ❌ Violation |
| Financial Insights | Green (`#10B981`) | `chart1`/`chart2` | ⚠️ Partially — needs mapping |

### 9.2 Visual Mood Board Direction

**Vibes**: Warm, tactile, analog-digital blend. Think:

- **Muji notebook** — minimal, functional, warm whites and earth tones
- **Field Notes** — utilitarian charm, subtle texture, strong typography
- **Things 3** — crisp hierarchy, satisfying micro-interactions
- **Daily (prayer app)** — quiet, respectful, uncluttered

**What to avoid**:
- No glassmorphism for the sake of it
- No heavy gradients or neon accents
- No "tech startup" aesthetic — this is not a fintech or social app
- No skeuomorphism — but do use tactile surfaces (soft shadows, warm card fills)

---

## 10. Deliverables

The design AI should produce:

1. **A comprehensive visual design system** — color swatches, typography scale, spacing tokens, component library (cards, buttons, inputs, chips, tabs, bottom nav, progress indicators, charts, modals, sheets).
2. **Screen-by-screen mockups** for all 16+ screens at 390dp (iPhone 14/15 size), both light and dark mode.
3. **Animation micro-specs** — duration, curve, stagger timing for each key interaction.
4. **A color mapping guide** — showing how current hardcoded colors map to the standardized `ArchivumTheme` tokens.
5. **Flow diagrams** for key multi-step processes (creating a transaction with splits, adding a new credential, the prayer tracking flow).
6. **A component inventory** — a flat list of every UI component in the app with its current state and proposed redesign.

---

*This brief was generated from a full codebase audit of Archivum Mobile (Flutter/Dart, Riverpod, Supabase). The app has strong bones — a consistent token system, good component patterns, and distinctive features. The task is to unify the visual language, eliminate the color inconsistencies, and elevate the polish through intentional micro-interactions and spatial hierarchy.*
# BluePOS Mobile — 92-Screen Design Handoff & Implementation Sequence

> **Status:** DESIGN HANDOFF / NOT A CLAIM OF 92 APPROVED UNIQUE SCREENS  
> **Updated:** 2026-11-13  
> **Application repo:** `9o9ame/BluePOSApp`; **working branch:** `feature/daily-entries`  
> **Backend/web source of truth:** `9o9ame/bluepos` (`main`) — read-only unless separately authorized.  
> **Related existing plan:** `docs/BLUEPOS_MOBILE_COMPLETE_APP_PLAN.md`. This handoff supplements, **does not replace**, that document.
>
> User's goal: preserve the approved premium BluePOS **light** mobile visual direction, retain individually generated mockups in development sequence, and implement the actual supported BluePOS mobile workflows. Continue consistently across new ChatGPT sessions.

## 1. Current verified repository facts

- This mobile repository contains a **Flutter/Dart** application, NOT a React Native app. Entry point: `lib/main.dart`, navigation: `lib/screens/shell.dart`.
- On 2026-11-13, `feature/daily-entries` existed and compared to `main` as **122 commits ahead, 0 behind**. It is not necessary or permitted to switch/merge branches for this design handoff.
- Existing source includes authentication/session handling, appearance, POS sales, reports, definitions, vendors/parties, purchases, returns, vouchers, inventory documents, users/roles and security screens. **Presence of a Dart file is not evidence that every underlying API write or scenario is production-ready.**
- The current `README.md` describes mobile 0.2.1 as a partial preview. It states purchase/customer/supplier/accounting workflows are read-only where write contracts are not supported, and warns that the configured API origin can cause **real live financial/stock writes**.
- Prior plan already records physical Android scanner issue (Redmi Note 10), biometric/MFA/device approval requirements, and an explicit restriction against unauthorized APK publishing.
- The web's `PROJECT_UI_DESIGN_SYSTEM.md`, master/current-state files and actual source/backend routes take priority over mockups or old conversation claims. For **every actual UI edit**, read the design system first and report conflicts before changing code.

## 2. Design source and pack integrity

The standalone user-download archive is named **`BluePOS_Mobile_92_Screen_Reference_Pack.zip`**. The numbered images are in `BluePOS_Mobile_Design_Approval_Pack/screens/`, with `SCREEN_MANIFEST.csv` carrying originals, image dimensions, and SHA256.

**Crucial limitations:**

1. The 92-slot archive contains **89 distinct images**. Screen **79** repeats an earlier Sales Summary concept, and **91/92** reuse More/Main Menu as **provisional references**. Do not claim the missing two final Settings/Administration designs were completed or approved.
2. The older `BluePOS_92_Screen_Mockups/` generic mockup directory was explicitly rejected by the user; it MUST NOT be used as the approved baseline.
3. The premium generated images are **visual references**; their figures, dates, branch locations, currencies, sample account names, displayed statuses and functional claims are illustrative. Treat them as non-authoritative.
4. Some images refer to Backup/Sync, Data Cleanup, Import, Export, Delivery Challans, offline sync, and other **proposed** workflows. Never implement or advertise them until supported by verified backend contracts, authorization and product approval.
5. The actual PNG/ZIP files have **not yet been uploaded to this GitHub branch** by the current session; local binary assets cannot be transferred through the available GitHub text-file connector. This document alone is NOT proof of a repository-hosted image pack. After upload, record path and commit SHA in the checkpoint table below.
6. Do **not** include mockup PNGs in runtime Flutter assets or bundle size. Use versioned design references under `docs/design/mobile-92/screens/` and a matching manifest, separate from the shipped app.

### Visual acceptance criteria

- One premium phone mockup per image — no collages/posters as individual-screen replacements.
- Restrained BluePOS logo/blue accents, **white/light surfaces**, deep navy text, soft shadows, responsive rounded cards, meaningful green/amber/red/purple accents; not “everything blue.”
- Consistent search, filters, forms, controls, lists, charts, bottom navigation, safe areas and touch target dimensions.
- Screens should use one shared theme/component system rather than unique per-page hardcoded UI.
- Always respect the actual server appearance contract and existing approved/frozen web layouts. The mobile adaptation must not edit web Sales Invoice geometry.
- No decorative dead buttons, invented metrics, silent financial rounding or phantom success states.

## 3. Screen-by-screen implementation order (design IDs)

The pack is curated into this order to establish foundation before high-risk transactional flows. Numbers are **design review IDs**, NOT backend implementation-completion statuses.

| Range | Topic | Concrete implementation sequence |
|---|---|---|
| 01–05 | Startup and auth | Splash; login; tenant code/account selection; verification; recovery. Verify actual MFA, biometric/device and session flows. |
| 06–10 | Home and navigation | Dashboard; premium Home variant; main menu; More; notifications. Confirm permission-filtered modules and accurate server KPIs. |
| 11–25 | Definition: products | Definition directory; products/details; category, subcategory, brand, unit, price-list, scheme lists/editors. Only supported CRUD and price contracts. |
| 26–31 | Parties | Customers (list/add/detail), Suppliers (list/detail/editor); server-side tenant/branch ownership and permissions. |
| 32–50 | Daily Entries | Module home; Sales invoice/detail; Purchase invoice/entry/detail; Sales Return list/entry; Purchase Return list/entry/detail; Expense & Journal Vouchers; Payments & Receipts. |
| 51–53 | Delivery Challans | **PROPOSED; contract check required**. No UI action should imply a supported stock-posting flow until verified. |
| 54–60 | Inventory | Opening stock, stock-taking, stock transfers and details; branch/warehouse context, append-only stock movements and immutable posted docs. |
| 61–70 | Reports I | Reports hub, sales, customers, suppliers, stock valuation, account statements and general ledger. |
| 71–80 | Reports II | Financial reports, P&L, Trial Balance, Balance Sheet, AR aging, AP aging, Cash Flow, Account Ledger, Sales Summary variant, Inventory Valuation. Screen 79 is duplicate/provisional. |
| 81–85 | Tools | Utilities, Import, Export, Backup/Sync, Barcode Printing. Unverified functions remain gated/proposed. |
| 86–90 | Administration | Users, Roles, Branches, Warehouses, Device & Security. Enforce server authZ/entitlements. |
| 91–92 | **Design gaps** | Settings/Profile and Administration Overview: **new final standalone mockups required**; current reference images are reused proxies only. |

### Prerequisite-aligned work packages

**Phase 0 — Baseline and approval (no implementation side effects).** Read the smallest relevant Flutter files, active API docs and `PROJECT_UI_DESIGN_SYSTEM.md`. Verify current branch is clean, fast-forward-compatible and not diverged. Verify all 92 numbered files, their SHA256 and duplicates, then obtain user approval on design corrections (especially 79/91/92). Track mockup-to-actual-screen mapping and supported/unsupported interactions.

**Phase 1 — Shared design foundation and navigation.** Build/reuse appearance tokens, spacing/typography, reusable cards, inputs, module tiles, empty/error/skeleton states, navigation and dialog patterns. Reconcile the *existing* `Home / POS / Products / Reports / Modules` tabs against the visual reference's scan-centered bottom navigation. **Do not silently change navigation**: record options and ask for design decision where frozen behavior conflicts.

**Phase 2 — Auth, dashboard and stable read-only surfaces.** Splash/login/biometrics/device approval, Home, lists/product detail, customer/supplier read pages, reports. Load only permitted server data, no fake numbers; test session expiration, branch switch, 401/403, device revoke, keyboard and safe-area overflow.

**Phase 3 — Sales/POS Daily Entries.** Real barcode scanner remediation on target Android device; product lookup, cart, server-authoritative prices/taxes, payment accounts, review/post and idempotent recovery. Sales invoice history/detail/print only after verified endpoints and permission gates. Sales Return workflows only with verified server contracts.

**Phase 4 — Purchases/parties/inventory.** Read-only first where required; implement writes only after confirming actual backend endpoints, request shapes, permissions, stock posting invariants, warehouse scope, retries and transactional behavior. Do not invent a local accounting or inventory engine.

**Phase 5 — Accounting and financial reports.** Server-backed vouchers, statements, balances and reports. No client-authored financial values. Respect money NUMERIC(20,4), quantity NUMERIC(20,6), factor/percent NUMERIC(12,8), with decimal-safe UI.

**Phase 6 — Tools, Admin, Settings and completion.** Implement *verified* import/export/printing/support only. For high-risk tools, require backend permissions, explicit confirmation and auditability. Complete custom Settings and Administration mockups before their UI acceptance.

**Phase 7 — QA and handoff.** Focused Flutter analyze/tests after each coherent change. For money/auth/tenancy posting run focused security/idempotency/precision tests, and only authorized test tenant/database (BluePOS backend test DB `bluepos_test`). Perform real-device scanner, biometrics, printing and release checks. Never hit live financial APIs with fabricated tests. **Do not build/publish APK or manage production signing without explicit separate approval.**

## 4. Strict engineering and release constraints

- Backend: Laravel 13 / PHP 8.3+ / PostgreSQL; mobile client: Flutter/Dart / Sanctum SPA-compatible session as actually implemented.
- External IDs: ULID only. Do not trust client tenant/branch/warehouse context, authorizations, ownership, currency, tax, prices, totals or balances.
- Server recomputes all financial values; posted records immutable; stock movements append-only.
- Reuse existing BluePOS accounting/inventory workflows; do not create parallel posting or duplicate sync engines.
- Enforce RBAC, tenant/branch/warehouse isolation, IDOR prevention, lock/race/idempotency/double-post checks, decimal precision and PII-safe logs.
- Existing module branch policy remains authoritative. Continue mobile changes on the *existing* `feature/daily-entries`; do not develop on `main`, create new branches, force-push, rebase or merge without approval.
- User asked to **start development after retaining assets and flow**, but did not authorize a release or production APK build in this request. Default: documentation/design checkpoint first, then localized implementation phases with review.
- If initial edit estimate ≤5 files grows past 7, stop and report before expanding scope.
- Every frontend/UI task: read `PROJECT_UI_DESIGN_SYSTEM.md` beforehand.

## 5. Definition of done per screen

- [ ] Correct design reference ID and approval status recorded.
- [ ] Actual server API contract and permission checked; unsupported interactions absent or visibly unavailable.
- [ ] Responsive on target phone/keyboard; correct bottom tabs and navigation/back/drafts.
- [ ] Error/loading/empty/offline/401/403/device and branch states tested.
- [ ] No hardcoded financial metrics, sample entity data or fake transaction results.
- [ ] Relevant Flutter widget/unit tests and security/tenancy/financial tests pass.
- [ ] Visual side-by-side comparison accepted by user.
- [ ] Complete changed-files, tests, risks and pending checks journal entry.

## 6. Permanent new-chat restart instruction

> Continue **BluePOS Mobile** in `9o9ame/BluePOSApp` on **`feature/daily-entries`**. First read `docs/MOBILE_92_MOCKUP_IMPLEMENTATION_HANDOFF.md`, `docs/BLUEPOS_MOBILE_COMPLETE_APP_PLAN.md`, and the minimum relevant current Flutter files. Before **any** UI edits, read `PROJECT_UI_DESIGN_SYSTEM.md` from `9o9ame/bluepos` and verify actual APIs. Design reference is the premium numbered image pack; older generic 92-screen mockups are rejected. Do not claim the missing 91/92 designs or the 79 duplicate are approved. Check actual branch diff/clean state, then resume from the latest journal checkpoint. Never invent features or financial data. Do not change the web repo, merge branches or publish APK without explicit instruction.

## 7. Progress journal / future checkpoint

| Date | Change | Verification | State |
|---|---|---|---|
| 2026-11-13 | Verified Flutter repo and `feature/daily-entries` compared with main (122 ahead / 0 behind) | GitHub branch compare | Done |
| 2026-11-13 | Curated 92 numbered screenshot slots; 89 unique images, 3 duplicate/provisional | Local files checked and SHA256 manifest generated | Local pack prepared |
| 2026-11-13 | Wrote persistent implementation handoff to existing branch | GitHub commit | This document |
| Pending | Upload actual PNG design archive + manifest under `docs/design/mobile-92/` to GitHub branch | Verify file count and SHA256 after upload | **NOT DONE** |
| Pending | Replace or approve designs 79, 91, 92 | User visual approval | **NOT DONE** |
| Pending | First implementation phase from verified baseline | Focused tests and review | **NOT STARTED under this handoff** |

**Resume rule:** Update this journal only after verifiable changes. Distinguish proposed designs, code-implemented features, tested features, and released features. Do not overwrite earlier known defects or silently claim completion.

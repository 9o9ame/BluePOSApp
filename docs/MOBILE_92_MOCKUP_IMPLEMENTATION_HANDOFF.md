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


### 2026-11-13 — Phase 0 implemented checkpoint (design pack integrity)

- Added `tool/verify_mobile_mockups.py` as a **read-only** 92-slot ZIP/extracted-folder validator: ordered screen IDs, safe PNG paths, PNG dimensions, SHA256, duplicate and provisional warnings. Optional `--require-unique` fails until all 92 unique designs are approved.
- Added `test/test_mobile_mockup_manifest.py` with four focused Python unittest cases covering valid inventory, missing image, hash tampering and strict duplicate rejection.
- Local `python -m unittest discover -s test -p 'test_mobile_mockup_manifest.py' -v`: **4/4 passed**.
- Local check against `BluePOS_Mobile_92_Screen_Reference_Pack.zip`: **PASS, 0 integrity errors, 6 warnings**. Duplicates: screen 79 == 63, 91 == 09, 92 == 08; all three flagged provisional. With `--require-unique`, the real archive fails as expected.
- Repo files are committed on **`feature/daily-entries`**; no edits to Flutter UI, web/backend, database or CI. Python checker tests were run locally; **Flutter analyze/tests and Android device validation were not run**. PNG binary upload remains **pending**.
- Next resume step: land the manifest + PNGs on the branch with SHA256 verification, replace/approve 79/91/92, reconcile actual navigation with mockups, then start smallest shared Flutter UI change. Do not silently change the existing navigation or ship preview-only functions.

Usage:

```bash
python3 tool/verify_mobile_mockups.py BluePOS_Mobile_92_Screen_Reference_Pack.zip
python3 tool/verify_mobile_mockups.py --require-unique BluePOS_Mobile_92_Screen_Reference_Pack.zip
python3 -m unittest discover -s test -p 'test_mobile_mockup_manifest.py' -v
```



### 2026-11-13 — Phase 1 localized dashboard authorization checkpoint

- **Changed:** `lib/screens/dashboard.dart`. Home now avoids calling sales/products API endpoints when missing the corresponding session permission and product/sales entitlement. The New Sale button requires `sales.create`, sales invoice history requires `sales.view`, and product shortcuts require `products.view` or `products.manage`. Unauthorized tiles and empty summary sections are hidden. The server remains authoritative: these checks are only presentation/request gating.
- **Added:** `test/dashboard_permissions_widget_test.dart` with widget regressions for no permissions and a create-only sales user.
- **Committed on:** `feature/daily-entries`; no branch change, no web/backend/DB modifications and no APK builds.
- **Validation:** GitHub file contents fetched back and manually inspected; **Flutter/Dart SDK is not available in the current execution environment**, so `flutter analyze` and focused widget tests **have not run**. These must pass before approval or merge. No production server calls were made.
- **Known remaining limitation:** Bottom tab navigation and report landing behavior still need **separate** entitlement/RBAC reconciliation with approved mockups; this change deliberately did not silently redesign the navigation.
- **Pending primary design blocker:** The binary PNG pack and actual `SCREEN_MANIFEST.csv` are not yet committed in GitHub. Design 79 duplicates 63; design 91 duplicates 09; design 92 duplicates 08. Do not mark 92 final-approved screens or visual parity complete.
- **Next work:** Run `flutter analyze --no-fatal-infos` and `flutter test test/dashboard_permissions_widget_test.dart` with Flutter installed, inspect and fix findings if any, then reconcile shell tab routing with session grants and the visual handoff. Do not alter frozen UI or ship APK without approval.



### 2026-11-13 — Pre-UI checkpoint / complete screen sequence index

- Added `docs/design/mobile-92/SCREEN_IMPLEMENTATION_INDEX.md` with the **full 01–92 numbered design sequence** and implementation readiness indicators. It reflects the actual ZIP manifest, not a fabricated approved-screen count.
- Verified current local archive exists at `BluePOS_Mobile_92_Screen_Reference_Pack.zip` (~125 MB), with 92 PNG images, a README and `SCREEN_MANIFEST.csv`. Local manifest statuses: 89 `reference`, 3 `DUPLICATE / PROVISIONAL`.
- GitHub PNG upload remains blocked by the current tool connection (no supported local file to binary GitHub action). The ZIP **is not present** on the remote branch; repository contains text docs/checker only. Do not claim design assets are stored there.
- A further image generation attempt produced an unrelated overview infographic, **not** screen 91/92; that output is rejected and was **not** added to the numbered reference pack.
- Flutter/Dart CLI unavailable on the execution host; the `dashboard_permissions_widget_test.dart` and dashboard code edits from the previous checkpoint remain **unverified by Flutter analyze/test**. GitHub status API did not establish an analyzer pass. Treat previous tests as written, not executed.
- No route layout change was made in this step: current `AppShell` has Home, POS, Products, Reports and Modules, while the premium reference proposes a central scan control and More tab. Resolve this explicitly before implementing shell geometry.
- **Next approved work:** implement actual Flutter UI in a focused first batch of 1–5 screens, based on the numbered screen index and verified source/API/appearance contracts. Do not add placeholders pretending to be real features. Remain on `feature/daily-entries`; do not build/publish APK without explicit direction.


### 2026-11-14 — User decision: freeze pre-login, begin actual post-login implementation

- **Explicit user decision:** No standalone tenant selection / Connect Business screen. Tenant/Mart Code already belongs to existing login. **Do not change existing Splash, Login, OTP/MFA, Password Recovery or other pre-login screens**; user is satisfied with them. Earlier plan suggesting building these before dashboard is superseded.
- Verified the actual premium image files from the reference ZIP: `06_Dashboard.png` is the Home/dashboard; `07_Premium_Home_Dashboard.png` actually shows a **POS Sales/product catalog** (previous index label was misleading). The numbered index now documents that mismatch.
- **Implemented first post-login UI pass** in `lib/screens/dashboard.dart`: responsive tenant greeting/location, theme-aware storefront icon plate, premium accent-to-emerald *invoice-count* hero, reduced duplication, narrow-screen responsive quick-action grid. Uses actual `/api/sales` invoice counts and `/api/products` catalog count only with appropriate session permissions and entitlements. **Does not** display the illustrative/mock revenue, expense, collections, percentage change or made-up charts.
- **Focused test updated:** `test/dashboard_permissions_widget_test.dart` checks no-permission dashboard retains real session tenant/branch/warehouse context while hiding denied widgets.
- **Design scope index updated:** `docs/design/mobile-92/SCREEN_IMPLEMENTATION_INDEX.md`. Screen 03 marked archival/NOT REQUIRED, screen 07 corrected to POS Sales. Pre-login code files **were not edited**.
- **Validation:** GitHub commits confirmed; Flutter analyzer/widget execution and side-by-side Android visual QA are **pending** because no Flutter/Dart executable is installed in the current environment. No APK build, release, web/backend/DB changes or branch merge.
- **Next:** validate Dashboard using `flutter analyze --no-fatal-infos` and `flutter test test/dashboard_permissions_widget_test.dart` in a Flutter environment; then compare rendered Dashboard to image 06, iterate on approved typography/spacing, and proceed with POS (design 07). Do not add a tenant selection route or redesign pre-login.


### 2026-11-14 — Mobile live domain change (connectivity fix)

- User confirmed production BluePOS domain is now **`https://bluepos.pk`**. Previous mobile URL `https://bluepos.bluemarketing.com.pk` in `lib/core/api.dart` was stale, causing the generic `SocketException` => `Internet connection is unavailable.` message.
- Updated the single central API origin for all API requests, CSRF, images, Origin/Referer to `https://bluepos.pk`.
- Updated secure session cookie key to `bluepos_pk_mobile_auth_cookies_v1` so expired/retired-host cookies will not be sent to the new domain; next sign-in obtains a fresh authorized session, preserving MFA and device approval.
- Updated `README.md` and added `test/api_origin_test.dart` to check canonical HTTPS origin and auth/CSRF path resolution.
- No changes to pre-login screen designs, web/backend, financial posting, Git branches or APK publishing.
- **Validation still pending:** the public connectivity probe could not reach `bluepos.pk` from this tool environment; user should run a safe unauthenticated `Invoke-WebRequest` GET and `flutter test test/api_origin_test.dart` plus `flutter run -d d2b1f972` on their Windows machine. Distinguish domain connectivity failures from backend/API auth responses. Never ask for passwords, cookies or tokens in logs.


### 2026-11-14 — First POS post-login screen batch

- **User feedback:** Android debug app now opens and login succeeds against `https://bluepos.pk`. Pre-login screens remain frozen and unchanged.
- **Implemented:** `lib/screens/sale.dart` premium POS entry layout: distinct search/scan buttons, styled POS title, authorized price-mode segmented control and customer selection card. `PosProductEntry` is a reusable presentation widget; search and scanner still call the existing server-backed product workflows.
- **Added focused test:** `test/pos_product_entry_widget_test.dart` verifies search/scan callback routing and both disabled during a pending unconfirmed sale.
- **Added per-batch mobile QA handbook:** `docs/MOBILE_LIVE_SCREEN_QA.md`, with Windows path `C:\Projects\BluePOSApp`, Git safety checks, focused Flutter commands, Dashboard/POS tap-by-tap acceptance and explicit **DO NOT SAVE** live financial warning.
- **No payment/stock calculation or posting code changed**, no backend/web/DB edits, no APK release. The real/mockup inline POS product grid and richer product cards are still **not implemented**; existing picker is used. Mark this as **first UI pass**, not final approved screen.
- **Validation:** GitHub changes verified through fetching source. Flutter analyzer, new POS focused widget tests, on-device screenshots and final acceptance **pending user execution**. Prior logs provided by user show 2/2 Dashboard widget tests passed and analyzer had informational lints only; do not extrapolate to unrun POS tests.
- **Next chat:** start by reading `docs/MOBILE_LIVE_SCREEN_QA.md`, then this handoff. Ask user for the POS screen screenshot/results, resolve any compile/runtime error from actual Flutter log, then proceed to inline product grid as a separate scoped batch without changing server-authoritative pricing or financial posting. Continue on existing `feature/daily-entries`.


### 2026-11-14 — User POS checks 6/6 passed; scoped product picker grid implemented

- User reported **PASS** for all six checks: POS Sales header, Product Search, separate Scanner, Price Mode, Customer card, and Cart/estimated total. This is user-reported interaction confirmation; screen 07 is **not yet visual-accepted** against the premium mockup; no payment/posting acceptance inferred.
- Read `lib/screens/products.dart` plus mobile UI rules; this already calls the authenticated, scoped `GET /api/products` with `sales_lookup=1`, `active_only=1`, category filtering, pagination, and product image support.
- **Modified:** `lib/screens/products.dart`: only when `onAdd != null` (POS add-product picker) use responsive product-card grid instead of full-width list, with server product name, authenticated image/fallback, retail reference price, and stock label only if supplied; no fake monetary/stock values. Standalone Products tab remains unchanged.
- **Added:** `test/pos_catalog_card_widget_test.dart`: selected product is the exact server item and missing price/stock remain explicitly unavailable.
- **Updated live QA document:** `docs/MOBILE_LIVE_SCREEN_QA.md`, including user 6/6 result, step-by-step product grid check, full Windows commands, and live transaction warning.
- **Validation:** GitHub source commits confirmed. New Flutter analyzer and widget tests not runnable within this assistant environment; user must execute on `C:\Projects\BluePOSApp`. No APK, web/backend/DB modification or merge. Screen 07 main-page *inline* product grid still pending; this batch changes the product selection bottom sheet only.
- **Next chat restart:** read this checkpoint and `docs/MOBILE_LIVE_SCREEN_QA.md`, ask for device results and sanitized screenshot of the **POS Search picker grid**, fix any observed layout/test failure, then consider inline main POS grid and cart organization without duplicating backend or touching financial posting.


### 2026-11-14 — Screen 07 source-image fidelity: main POS inline grid batch

- User confirmed **all five** previous product-picker grid checks PASS and reiterated **match the approved individual images, never invent another design**. Previous six POS first-pass checks also PASS. These are user-reported tests, not visual signoff.
- Opened actual `/mnt/data/preview_dash/07.png` extracted from `BluePOS_Mobile_92_Screen_Reference_Pack.zip`; it shows **POS (Sales)** with search/scan, category chips, two-column image-led product cards and docked bottom cart. The old picker-only grid did **not** match the reference composition; corrected this.
- `lib/screens/products.dart`: added optional `inlineCatalog` using existing authorized `GET /api/products` with `sales_lookup=1` / `active_only=1`, server category data, pagination, images and existing onAdd callback; inline mode shows 2 columns with larger image-first cards. No new API or parallel catalog logic.
- `lib/screens/sale.dart`: main POS now hosts inline catalog above price mode/customer/cart and has a bottom docked cart estimate with original Proceed to Payment navigation; pending unconfirmed sales block new catalog selection. No server-side financial/stock code altered.
- `test/pos_catalog_card_widget_test.dart`: added 155px narrow card with long product-name regression; existing missing-price/stock tests retained.
- Important distinction: **screen structure closer to image**, not full pixel fidelity or final approval. Current shell bottom nav remains Home/POS/Products/Reports/Modules instead of mock Home/POS/Scan/Reports/More; favorite icons and illustrative branded product imagery remain unsupported, and real server data replaces mock samples. See `docs/MOBILE_LIVE_SCREEN_QA.md` for explicit phone checks and gaps.
- **Validation pending:** no local Flutter CLI in assistant runtime. User should pull in second PowerShell at `C:\Projects\BluePOSApp`, run analyzer + focused tests, then press `r` in still-running Flutter terminal (or `R` if initState is stale) and send sanitized screen 07 screenshot. No APK or branch merge.
- **Next chat:** read `docs/MOBILE_LIVE_SCREEN_QA.md` and this handoff first; address actual device/test errors, compare screenshot with approved image 07, then handle navigation refactor only with careful route/RBAC mapping and developer approval scope. Preserve pre-login screens and live `bluepos.pk` URL.


### 2026-11-14 — Hot Reload crash recovery checkpoint

- User said Home renders but all other tabs blank after updating inline POS layout. PC output reported `flutter analyze --no-fatal-infos` with **125 info** lints, and catalog card widget tests **3/3 PASS** for previous commit.
- First actual runtime exception: `ProductsScreen.inlineCatalog` returns null for newly added non-nullable bool field from previously mounted `AppShell` IndexedStack on Hot Reload. Subsequent `BoxConstraints forces an infinite width` and RenderBox errors were also logged; cannot assert they are fully resolved until a fresh restart.
- Patched `lib/screens/products.dart`: nullable `inlineCatalog` and `imageFirst` field declarations with `== true` default-safe checks for hot reload. Added one legacy-null card regression test in `test/pos_catalog_card_widget_test.dart`.
- **Immediate recovery:** latest Git pull from `C:\Projects\BluePOSApp`, run analyzer + focused test, then **capital R** Hot Restart in existing Flutter terminal. This is not a full APK rebuild; Flutter Hot Reload may not initialize newly added instance fields.
- Device confirmation **pending** for POS/Products/Reports/Modules and POS inline grid. No pre-login changes, API changes, DB writes, release, or branch switching. Handoff next chat: inspect first exception if any remains and fix only confirmed layout source; continue screen 07 approved-image fidelity after all tabs render.


### 2026-11-14 — IndexedStack layout failure follow-up

- Latest user logs: fast-forward pull to `776f009`; Flutter analyzer 125 info only, product-card tests 4/4 passed; Android still displays `!_debugDoingThisLayout` at `IndexedStack` in shell.dart, selected index 1 (POS), after prior hot-reload-driven null-field error.
- Inspected shell, POS, Products and shared `Surface` code. New POS is a `Column + Expanded(ListView) + bottom footer`; shell retained five tabs via default loose-sized `IndexedStack`.
- Applied focused `lib/screens/shell.dart` change: bounded viewport from LayoutBuilder + SizedBox, `IndexedStack(sizing: StackFit.expand)`; preserved all five tabs and actual POS design. New test `test/shell_layout_constraints_widget_test.dart`.
- **Do not claim resolution:** code and test committed, but no local Flutter execution or fresh-device validation in this assistant environment. User should pull, run analyze/focused test, then **fully stop** existing Flutter process with `q` and start a fresh `flutter run -d d2b1f972` (because repeated render object assertion may persist across hot reload/hot restart).
- If clean launch still throws, inspect **first exception** and stack, consider simplifying POS nested ListViews/footer, not changing shared UI globally. No sales posting/API/login/backend or branch changes.


### 2026-11-14 — Confirmed infinite-width theme-button root cause (Home blank)

- Actual full fresh-launch log confirms the **primary** exception at `FilledButton:file:///C:/Projects/BluePOSApp/lib/screens/sale.dart:536`: `BoxConstraints forces an infinite width`. This is the POS docked cart footer button in a `Row`; `AppShell` eagerly lays out POS due to `IndexedStack`, causing even Home to blank.
- Root CSS-equivalent Flutter theme flaw verified: `AppAppearance.data` sets `filledButtonTheme.minimumSize = Size.fromHeight(48)` (infinite min width), and `elevatedButtonTheme.minimumSize = Size.fromHeight(52)`. Fixed both in `lib/core/appearance.dart` to `Size(0, 48)`/`Size(0, 52)` while preserving height and parent-controlled full width.
- Fixed `const ListView` compile errors in `test/shell_layout_constraints_widget_test.dart`, and added `test/appearance_button_constraints_widget_test.dart` to reproduce Row-based button layouts under the actual app ThemeData.
- **Validation pending on user Windows Flutter installation.** User should pull safely, analyze, run both focused tests, then full `flutter run -d d2b1f972` after `q`. No backend, auth, finance posting, mockup changes, APK release or branch switching.
- Handoff rule: first confirm all tabs restored before further screen-image work. The approved Screen 07 POS inline grid stays present, but user/device approval and detailed visual parity remain pending.


### 2026-11-14 — Device smoke tests PASS following layout crash correction

- User confirmed **six of six** device checks PASS: Home, POS, Products, Reports, Modules all visible; navigating tabs causes no blank screen. Mark **rendering incident functionally resolved** after button minimum-width fix.
- Do not confuse user device confirmation with Flutter analyzer or post-fix widget-test execution: the latter results were not provided. Last known pre-fix shell-layout test had a `const ListView` compilation problem, now corrected in GitHub; new appearance-button regression was added but run outcome unverified.
- **Maintain strict design requirement:** implement screens per approved individual 92-screen reference images, especially Screen 07 POS layout. Preserve accepted Splash/Login/OTP/MFA/Recovery unchanged; real authenticated product data only, not mock samples.
- **Next chat:** inspect latest source, approved `07_Premium_Home_Dashboard.png`, and `docs/MOBILE_LIVE_SCREEN_QA.md`; request sanitized current POS screenshot or user feedback as needed to identify specific parity gaps. Existing image-level gaps include bottom navigation Home/POS/central Scan/Reports/More vs Home/POS/Products/Reports/Modules; avoid changing routes without deliberate mapping and tests. Do not change payment/posting or make live invoices for UI testing.


### 2026-11-14 — Critical design-source correction (user clarification)

- **User correction:** The earlier generic 92-screen ZIP / Approval PDF were rejected. The actual intended mobile design references were generated **afterward in batches of approximately ten individual screens**. Earlier statements calling the old ZIP approved were incorrect. Do not use rejected generic images for any new UI decision.
- The current working environment contains `/mnt/data/BluePOS_Mobile_Design_Approval_Pack/README.md` and `SCREEN_MANIFEST.csv`; its README expressly says the previous rejected generic set was **not** used and references individually generated premium mobile PNGs. The manifest identifies original filenames such as `bluepos_dashboard_overview.png` (06) and `bluepos_premium_sales_dashboard.png` (07). A spot-check confirmed SHA256 of those and other listed originals. 87/92 manifest original filenames were present in the current working directory; not all are independently available. This container path is **not** a GitHub repository path or guaranteed persistent across chats.
- **Required before future UI implementation:** Locate and visually inspect the actual individual newer screen PNG and verify against the manifest/hash; distinguish source-image provenance, user's current approval, and provisional/duplicate entries. Never infer approval from an old PDF, ZIP or an index label. The user has said these later batches are the relevant designs, but do not assert every individual image is finally approved.
- **Existing UI risk:** prior mobile POS work was discussed against an old/rejected "Screen 07" source description, although newer original image is present as `bluepos_premium_sales_dashboard.png`. Reassess POS layout against this actual image before any further design changes. Preserve stable working app and do not change code on speculation.
- The user-confirmed all-tabs 6/6 rendering recovery remains valid; this note changes only design-source status. No UI code, tests or database altered by this correction.


### 2026-11-14 — Newer batch image development resumed: 08 Main Menu / 09 More

- User explicitly directed implementation **only** from later individually generated screen images (10-at-a-time batches), not old rejected 92 ZIP/PDF. On assistant host the current newer premium images are present at `/mnt/data/bluepos_main_menu_dashboard.png` (08) and `/mnt/data/bluepos_more_menu_dashboard.png` (09), mapped by `/mnt/data/BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`. Both inspected visually.
- `lib/screens/modules.dart`: default visible More menu with real tenant/branch banner and reference-based vertical menu rows; top-right Main Menu toggle with extra authorized Products/Customers/Purchases/Sales shortcuts. Group rows reuse existing permission-gated ModuleActions and existing screens; old generic searchable directory still accessible for functionality parity. Uses the user's selected ColorScheme; no mock tenant or app business figures hardcoded.
- `test/approved_navigation_menus_widget_test.dart`: widget test created for tenant display, restricted module visibility and Products shortcut. **Tests/analyzer not executed on assistant environment**, user phone check pending.
- Intentional design gaps: existing bottom nav still Modules/Products instead of More/center Scanner; no unsupported fake Help or Logout actions; app bar unchanged, so not a pixel-perfect claim. Further edits depend on source-image comparison and route/permission review, not guessed mockups.
- User instructions: `cd "C:\Projects\BluePOSApp"`, `git status --short`, `git pull --ff-only origin feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"`; hot restart `R` in running Flutter terminal; check More/Main Menu, authorized rows, directory, Settings, all tabs. Do not invoke live financial posting.
- Remain on `feature/daily-entries`, no main merge, no release/APK, no backend/API/DB work, and preserve accepted pre-login screens.

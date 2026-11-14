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

### 2026-11-14 — User-approved functional QA for newer image Screens 08 and 09

- User replied **6/6 PASS** to latest physical-device checklist: More shows actual tenant; Main Menu toggle; permission-aware rows; Definition directory; Settings and complete module browse; all five tabs remain visible/no blank pages.
- This is device-confirmed *functional* acceptance, not evidence of exact screenshot pixel parity. Test/analysis results for `test/approved_navigation_menus_widget_test.dart` were not provided, so mark automated QA unverified.
- Design source correction remains binding: use later individual 10-at-a-time PNG images, NOT rejected earlier generic 92 ZIP/PDF. Preserve frozen pre-login and stable tabs.
- Next: inspect newer Screen 10 `bluepos_notifications_dashboard.png`, existing Flutter routes and actual server notification contract, then only implement a scoped UI if supported; update QA/handoff and ask user for device check. Avoid mock notification content or permission bypass.


### 2026-11-14 — Screen 10 Notifications: newer individual PNG implementation batch

- **Trigger:** User said do not stop at a previous batch's PASS report — proactively complete the **next development batch**. Prior Screens 08–09 user device QA 6/6 PASS documented.
- **Correct visual source:** actual newer individual `bluepos_notifications_dashboard.png` inspected, not old rejected 92 ZIP/PDF.
- Verified live backend source `backend/routes/api.php` and `backend/app/Http/Controllers/Api/DeviceController.php`: owner-only `GET /api/devices/access-notifications` and `POST /api/devices/access-notifications/{notificationUlid}/read`. Alert fields include ULID, kind, created_at, read_at, device_name, username, request_ulid; response includes unread_count. Tenant/membership and policy enforcement is server-side. No verified global notifications endpoint for sales/purchase/stock/backup example content.
- NEW `lib/screens/notifications.dart`: reference-style All/Alerts/Activity filters, server-supplied cards, unread badge, explicit mark read, error/empty/403 states, refresh; Activity explicitly unavailable rather than invented. Owner-only response controls visibility, no client-authoritative tenant or fake alerts.
- UPDATED `lib/screens/shell.dart`: Header bell opens Notifications using existing Navigator. No change to functioning main tab order/navigation or posting.
- NEW `test/notifications_screen_widget_test.dart`: four targeted widget tests, not yet run on user host.
- **Device verification pending:** safe FF pull on `feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\notifications_screen_widget_test.dart"`; `R` Hot Restart; check bell, filters, owner-only/device alerts, unread read callback, errors, and all-tab stability.
- **Known parity gaps:** Image's purchase/low-stock/sales/backup cards are illustrative and lack verified notification backend; bottom navigation center Scanner and global art not yet matched; do not fake.
- **Next batch on PASS:** Inspect actual newer Screen 11 Definition Home image, current permission-scoped module directory and API routes; implement smallest matching UI diff, tests, QA and updated handoff in same response without asking for a separate go-ahead. Preserve frozen login, stable tabs, live data and authorization.


### 2026-11-14 — Screen 10 confirmed PASS; newer Screen 11 Definition Home implemented

- User reported **all six** Screen 10 Notifications device checks PASS: bell, opening, filter tabs, real/empty/owner-only data state, refresh/back, and five-tab stability. Do not confuse with automated widget tests or screenshot parity.
- User workflow requirement: **immediately complete next batch on previous batch PASS**, and update QA/handoff, not merely acknowledge.
- Inspected actual newer `/mnt/data/bluepos_definition_modules_dashboard.png` reference, mapping Screen 11. Ordered vertical white rounded rows: Products, Customers, Suppliers, Categories, Subcategories, Brands, Units, Price Lists, Barcode Printing, Sale Schemes, Opening Stock, Stock Taking. Not the rejected generic 92-pack.
- UPDATED `lib/screens/modules.dart`: dedicated `_definitionHome` list accessed via More/Main Menu Definition; uses existing `groups` and `ModuleAction.visible` permission/entitlement checks plus existing action.open callbacks. Image-order supported rows, Back to More and browse old directory. No fake business data or parallel authorization.
- **Current known gap:** Price Lists and Barcode Printing do not have verified direct `ModuleAction` in existing groups, so no fabricated route has been added. Nav bar artwork and center scanner still differ from reference; do not claim full pixel parity.
- NEW `test/definition_home_widget_test.dart`: visibility/order, unauthorized omission, navigation and back. **Testing pending user Flutter CLI**; tests not run in assistant environment.
- USER QA: safely pull branch `feature/daily-entries`; run `flutter analyze --no-fatal-infos` and `flutter test "C:\Projects\BluePOSApp\test\definition_home_widget_test.dart"`; press `R` in still-running Flutter terminal; device test Definition, authorized rows/routes, back/browse, all-tab stability. Do not issue Save/Post on production.
- NEXT on pass: inspect newer Screen 12 `bluepos_products_catalog.png` and existing Flutter Products data contracts and image; smallest visual alignment, focused tests and handoff. No branch merge, no release/APK, no frozen auth changes.


### 2026-11-14 — Screen 11 PASS; Screen 12 Products Catalog implemented

- User marked **all six** Definition Home phone checks PASS. Record functional acceptance only; cannot infer exact pixel parity nor that user ran `test/definition_home_widget_test.dart`.
- Inspected actual newer individual `/mnt/data/bluepos_products_catalog.png` (Screen 12, after rejected pack). Layout: search + funnel, image-first wide rows with SKU, stock pill, right price and floating Add Product. Example brands/prices/stock are illustration only.
- UPDATED `lib/screens/products.dart` with `CatalogProductRow` from server fields, explicit missing data labels, standalone search/filter UI and authorized Create Product FAB. `catalogHome` mode intentionally separates bottom Products tab from `onAdd` POS picker: product tap shows product details, POS grid remains add-to-cart. Existing API, pagination, category filter, details/editor, tenant context and RBAC reused.
- UPDATED `lib/screens/shell.dart` to wire `catalogHome: true` on both initial Products tab and refresh constructor.
- NEW `test/products_catalog_reference_widget_test.dart`: row data/tap and missing-value tests. Not executed in assistant host; user runs analyzer and focused test with `C:\Projects\BluePOSApp` working directory. Hot restart capital `R` recommended due new widget fields. No native rebuild, API/database edits, sales posting changes or branch switches.
- User QA: verify Products tab horizontal rows and real values, filter categories, row details, permitted Add Product only, POS still 2-column add-to-cart, no blank tabs. Do not issue live product Save or Sale Post for UI QA.
- Next user PASS → inspect actual newer Screen 13 Product Details reference plus existing Flutter details view and contracts, implement next focused batch, tests and permanent handoff in same turn. Frozen pre-login remains untouched.


### 2026-11-14 — Screen 12 6/6 PASS; newer Screen 13 Product Detail batch

- User confirmed **6/6** Products Catalog checks PASS: standalone horizontal item rows; real data; item tap opens details, not cart; search/filter; authorized Add Product/editor; other tabs and POS grid stable. This is live device functional acceptance only, separate analyzer/test logs not provided.
- Inspected actual newer individual `/mnt/data/bluepos_coca_cola_product_details.png` Screen 13 (manifest SHA256 `a63ed25eb751741048d60d9fb527926fd0d9a9516cd289a9ff1e2b9c79b423d9`). Rejected old 92-pack must not be used.
- Confirmed backend `GET /api/products/{productUlid}` from ProductController::show with policy authorization and exact ProductResource fields; no guessed schema/stock.
- NEW `lib/screens/product_details.dart`: full-page read-only details fetched by public ULID, server-driven image/name/SKU/active/price/stock, category/brand/unit/barcode/description, and Price & Stock including optional reorder level. Purchase Price and Edit gated to `products.edit`, Edit opens existing ProductEditor and refreshes after successful save.
- UPDATED `lib/screens/products.dart`: standalone Product Catalog tap/scan opens details page, POS onAdd behavior unchanged. No sale/stock posting, auth or session changes.
- NEW `test/product_details_widget_test.dart`: four focused widget tests for product values, permissions, missing-data states and edit callback.
- Intentional gap: reference Print Barcode footer has no verified mobile route; no dummy control. Example 168 stock or branded images were never hardcoded.
- **Validation** code committed to `feature/daily-entries`, but Flutter analyzer/tests and device Screen 13 review pending. Commands: `cd "C:\Projects\BluePOSApp"`, `git status --short`, `git pull --ff-only origin feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\product_details_widget_test.dart"`; capital R in running Flutter debug terminal. Keep local Android/generated files intact and don't switch branches.
- Next on user PASS: inspect actual newer Screen 14 Categories image plus current `CatalogMasterScreen` categories implementation; implement small reference-based UI batch, focused tests and docs in the same response. Frozen pre-login UI and existing working navigation untouched.


### 2026-11-14 — Build-breaking Screen 13 syntax/ULID fix and new batch-size rule

- User explicitly wants **five screens in each future implementation batch**, not one. Implement them together only after current build/tests/device are stable. Newer individually generated reference PNGs are authoritative; old rejected generic ZIP/PDF are not.
- User's pasted `flutter analyze --no-fatal-infos` showed 2 **compile errors** (plus 127 informational and 1 unused-element warning): `product_details.dart:182` extra closing bracket and `products.dart:260` undefined `validPublicUlid`. Both focused Screen 13/12 widget-test files failed at compile, so Screen 13 acceptance is **BLOCKED**.
- Fixed `lib/screens/product_details.dart` (remove extra delimiter in product hero Row) and `lib/screens/products.dart` (use same strict 26-character ULID regex as ProductDetailsScreen; remove now-unused `_price` helper). Source commits `28c65d1c6d77cbcc7bfc7253d31e0e3b715c5261` and `ac3d203ebb9de796012dbd0addd1d8ad5f5baa9b`.
- **Not tested on assistant host**; user must safe pull, analyzer and both focused widget tests, then Hot Restart in their running Flutter terminal and verify Products/Details navigation. No UI redesign, posting, auth, backend or branch change.
- Next on PASS: **screens 14–18 as one batch** (Categories, Add Category, Subcategories, Add Subcategory, Brands) after checking real newer individual PNGs and current `CatalogMasterScreen`, its permission logic and supported API contracts. Five-screen plan is **pending**, not implemented.


### 2026-11-14 — Second build failure corrected: broken Products file + lazy Edit test

- Latest user-provided Windows log: `flutter analyze --no-fatal-infos` produced extensive cascade (309 findings), caused by **unterminated raw RegExp at products.dart:260 and accidentally duplicated showDetails/build tail after line 373**. It also showed 3/4 Product Details tests passed, with only authorized Edit callback test failing because `ensureVisible` targeted an unbuilt lazy ListView child. Products Catalog tests could not compile.
- GitHub repairs: `f6ca0cdf7468e92c8ce4ad02ec8b53bdaf56cbff` cleaned `lib/screens/products.dart` (strict full ULID regex; remove duplicate entire tail); `c2fd7f2d83b185617a80a5535fec4c0ce7b4e139` updated `test/product_details_widget_test.dart` to `scrollUntilVisible`. Read-back verified 373-line Products file, one showDetails, and no duplicated build.
- **Validation status:** Static GitHub source inspection completed. Latest Flutter analyzer/tests and real phone smoke tests **not yet executed/confirmed**. User should pull latest FF, analyzer, tests for `product_details_widget_test.dart`, `products_catalog_reference_widget_test.dart`, and `pos_catalog_card_widget_test.dart`; Hot Restart capital R only once those pass.
- **Batch size:** User requires next implementation cycle to cover **five newer individual PNG screens (14–18)** in one delivered batch. None are implemented by this repair; do not code while broken build and don't use old rejected pack. Preserve frozen login/pre-login designs, current branch `feature/daily-entries`, tenant/RBAC and sale posting.


### 2026-11-14 — PC gate 10/10 PASS; five-screen batch 14–18 implemented (device deferred)

- User is temporarily without physical Android phone and requested **implement five screens at a time** and keep GitHub docs/handoff synchronized so a new chat can resume without restating flow.
- Their Windows log after repairing the Screen 13 broken Products file confirms FF pull succeeded, `flutter analyze --no-fatal-infos` had **127 info-only lints (0 errors/0 warnings)**, and three focused Flutter test runs **4/4, 2/2 and 4/4 PASS (10/10 total)**. Screen 13 build gate is cleared; physical device approval for it still pending.
- Read `PROJECT_UI_DESIGN_SYSTEM.md`, current Flutter `lib/screens/catalog_master.dart`, module routes and backend `CategoryController`, `SubcategoryController`, `BrandController` plus Resources. Five **later individual** PNGs 14–18 were opened visually and their SHA256 matched `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`. Never use the old rejected generic PDF/ZIP.
- UPDATED `lib/screens/catalog_master.dart`: approved-reference list composition for **14 Categories**, **16 Subcategories**, **18 Brands** (search, filter, actual API name/code/parent category, icon-first cards, permission-scoped Add). Replaced prior bottom-sheet Add/Edit UI with **full-page screens for 15 Add Category, 17 Add Subcategory** (same authorized endpoints, category parent selection, name/description, active status, Cancel and Save). Existing brand editor uses the same shared full-page form; no new backend layer. Read-only `Automatically generated` code: backend creates category/subcategory/brand codes server-side. No fake counts, client-made codes, icon/color persistence or sample brand data.
- NEW `test/catalog_master_reference_batch_widget_test.dart`: 5 widget checks for screens 14–18 and payload contract (no client `code`). Reuses fake in-memory GET results only (no live API writes). No backend/DB modifications, no financial posting, no frozen pre-login change, no branch switch, no APK/release.
- **Assistant unable to run Flutter CLI**. New tests and compilation of this batch unverified. Must ask user to run focused analyzer and `test/catalog_master_reference_batch_widget_test.dart` on Windows now if PC available; mobile checks can wait. If test fails, repair before additional feature work. Keep local `analysis_options.yaml`, `android/`, `.idea/`, `.metadata` unchanged.
- **One-time PC command block / future phone acceptance checklist** in `docs/MOBILE_LIVE_SCREEN_QA.md`. All five screens and the Product Detail screen need later device visual acceptance. Explicitly preserve API-only ULIDs, tenant permissions, and no live Save/Post test operations.
- **Next batch on green PC validation + later device feedback**: inspect newer individual Screen 19–23 PNGs and backend contracts, then implement together, add focused tests, update this handoff, QA and plan. Do not stop at reporting PASS; user prefers actual next implementation batch when unblocked. If user opens new chat, this section is the resume marker.


### 2026-11-14 — Screens 14–18 user device PASS; Screens 19–23 next batch committed

- User explicitly reported previous five screens **14 Categories, 15 Add Category, 16 Subcategories, 17 Add Subcategory, 18 Brands all PASS on mobile**. Record as functional user device confirmation only, not automated CLI pass or pixel-perfect visual approval. User requires next **five-screen batch completed on each PASS**, with documentation and permanent handoff every time.
- Original newer individual reference images 19–23 visually inspected, filenames `bluepos_add_brand_form.png`, `bluepos_units_management_screen.png`, `bluepos_add_unit_form.png`, `bluepos_price_lists_dashboard.png`, `bluepos_add_price_list_form.png`. Their original bytes matched `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv` SHA256 values. Old rejected generic ZIP/PDF must **never** be used for implementation.
- Verified backend `backend/routes/api.php`, `StoreBrandRequest`, `StoreUnitRequest`, `BrandController`, `UnitResource`. Existing secured `/api/brands` and `/api/units` support the core 19–21 flows. Brand code is server-generated. Unit factor in image is not supported by verified `StoreUnitRequest`. No Price Lists endpoint/controller found in inspected backend API, so never invent its persisted fields/permissions or prices.
- Changed `lib/screens/catalog_master.dart`: Add Brand form has read-only generated code; Unit list displays actual symbol; Add Unit labels short-name/symbol and explanatory conversion-factor limitation. Existing authenticated API + permission checks, create/edit and Theme & Appearance preserved. No live writes were run.
- Added `lib/screens/price_lists.dart`: **22 Price Lists** and **23 Add Price List** are safe, visually oriented **UI-only reference screens** with explicit pending-backend banner, no fake records/amounts and disabled price-list Save. Added Definition route in `lib/screens/modules.dart` guarded by products.view/manage + catalog entitlement, but this is navigation to a **design reference**, not proof of a dedicated Price Lists permission.
- Added `test/catalog_reference_19_23_widget_test.dart`: five widget tests and unit payload test for Units contract. New tests and analyzer **NOT run in assistant host**; no Flutter binary available. Existing 14–18 on-device PASS does not mean these new tests passed.
- **Known partial completion:** Three (19–21) are existing backend-supported functional workflows; two (22–23) are reference-only awaiting backend spec, permissions, API and tests. Do not call five functional screens complete. No auth/pre-login, financial posting, local Android, database or branch changes. Remain on `feature/daily-entries`; never merge to main until review/approval.
- **Next user verification:** PC safe pull, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\catalog_reference_19_23_widget_test.dart"` plus previous catalog batch tests; phone QA from `docs/MOBILE_LIVE_SCREEN_QA.md`. If any errors, fix first. After PASS, inspect newer references 24–28 and relevant backend routes before beginning next five-screen batch. Keep user from re-explaining history by following this checkpoint.


### 2026-11-14 — Screen 19–23 focused test failure, fixed in source, retest pending

- User pasted PC log after pulling latest five-screen batch: analyzer 0 errors, **1 warning** (`catalog_master.dart:204` invalid null-aware operator) + 127 info lints; new `catalog_reference_19_23_widget_test.dart` **5/6 PASS, 1 FAIL**, failing Screen 23 disabled Save assertion because the footer was outside lazily built ListView viewport. Previous `catalog_master_reference_batch_widget_test.dart` **6/6 PASS**. Do **not** call all tests passed.
- Committed smallest fixes: unnecessary `item?['code']` changed to `item['code']` under edit branch; keyed existing disabled Price List Save `ValueKey('price-list-save-disabled')`; test now `scrollUntilVisible` to ensure lazy footer mounted before asserting Save is disabled.
- **Execution status:** GitHub commits done; Flutter analyzer/test rerun and device acceptance remain **PENDING**. No domain APIs changed; Screens 22/23 still explicitly UI-only, no price-list writes.
- User should run latest safe FF pull from `C:\Projects\BluePOSApp`, `flutter analyze --no-fatal-infos`, and focused `flutter test ...catalog_reference_19_23_widget_test.dart`. If an error persists fix before Screens 24–28. Preserve local generated Android files, approved individual design source and existing branch `feature/daily-entries`.


### 2026-11-14 — User says 19–23 all tests PASS; five-screen 24–28 batch delivered for PC QA

- **Flow contract:** On previous PASS, complete the next **five screens in the same turn** and update this handoff + live QA + app plan. User currently reports all last PC tests PASS. This is user-reported result, not a fresh artifact log. Keep working on `feature/daily-entries`; preserve local Windows `C:\Projects\BluePOSApp` generated Android files/modified `analysis_options.yaml`. Never use rejected generic 92-pack.
- **Design source:** opened later individual PNG files and SHA256-verified manifest mapping 24 Sale Schemes, 25 Add Sale Scheme, 26 Customers, 27 Add Customer, 28 Customer Detail.
- **Verified backend:** `GET/POST/PATCH /api/sale-schemes` exists but StoreSaleSchemeRequest requires reward product ULID/max reward qty/min sale amount and apply mode; mockup scheme fields differ. `GET /api/parties?type=customer`, `POST/PATCH /api/parties`, `GET /api/parties/{ulid}?type=customer`, `GET /api/coa/account-types`, and party ledger API exist with real RBAC/tenant authority. StorePartyRequest requires code, name, account_type_ulid; optional area/mobile/address; creates linked accounting records server-side. Do not fabricate opening balance/credit_limit updates or mock receivables.
- **Files changed/added:** NEW `lib/screens/sale_schemes.dart` (24 API-backed sale schemes list/search/filter and 25 read-only add form preview/disabled Save); UPDATED `lib/screens/modules.dart` (Sale Schemes opens new list instead of generic DataList); UPDATED `lib/screens/parties.dart` (26 customer card list/search/filter, 27 full-page add/edit, existing code/account-type + area backend contract, 28 details route); NEW `lib/screens/customer_detail.dart` (authorized ULID-based detail, actual fields and safe missing data); NEW `test/catalog_reference_24_28_widget_test.dart` (5 widgets + payload test).
- **Known partial scope:** Screen 25 is *NOT functional*, because mockup fields cannot validly form SaleSchemeRequest; Save disabled. Screen 27 does not mutate opening balances, financial credit limit or groups; Screen 28 does not invent receivable/ledger transactions. Screen 24 read-only list; no new financial flows.
- **Validation:** GitHub source committed; source-level bracket checks were clean after fixing one missing navigator closing paren. **Flutter analyzer/widget tests/physical-device check not yet run in assistant runtime**. Required user commands: `cd "C:\Projects\BluePOSApp"`, `git status --short`, `git pull --ff-only origin feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\catalog_reference_24_28_widget_test.dart"`. See full screen-by-screen checklist at `docs/MOBILE_LIVE_SCREEN_QA.md`.
- **Next on PASS:** Inspect newer originals **29–33** and relevant backend contracts. If new tests fail, fix precisely before next batch. Preserve frozen auth/pre-login screens and live `bluepos.pk` session; avoid Save/Post operations on production for design testing.


### 2026-11-14 — Screens 24–28 device 6/6 PASS; newer Screens 29–33 batch implemented

- **User report:** previous 24–28 mobile checklist fully PASS (6/6): real Sale Schemes, safe disabled add preview, Customers list, Add Customer navigation, Customer Detail authorized Edit, all other tabs stable. Functional acceptance only, not full PNG pixel fidelity nor proof of analyzer log.
- **Design source:** actual later individually generated 29 Suppliers / 30 Supplier Details / 31 Supplier Form / 32 Daily Entries Home / 33 Sales Invoice PNG files under `/mnt/data`. All five visually inspected with original SHA256 equal to `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`. Do NOT use old rejected generic 92 pack.
- **Source/contract inspection:** `PROJECT_UI_DESIGN_SYSTEM.md` read first. Existing `lib/screens/parties.dart`, `modules.dart`, `sale.dart`, and backend `PartyResource` / PartyController / party routes inspected. Supplier API is `/api/parties?type=vendor` + `/api/parties/{ulid}?type=vendor`; vendor form requires code/name/`account_type_ulid`. Money/ledger shown in mockup is NOT authorized by basic supplier details response. Sales Invoice Screen 33 must reuse existing `SaleScreen` + idempotent server invoice flow, no duplicate client posting.
- **UPDATED:** `lib/screens/parties.dart` (supplier search/filter/card attributes, navigate to full-page supplier details, supplier full-page Add form with City/Area and proper title; preserve customer/account behavior and legacy party API).
- **NEW:** `lib/screens/supplier_detail.dart` (authorized read-only supplier detail, safe missing data, permission-scoped edit callback; no invented payables/purchases).
- **UPDATED:** `lib/screens/modules.dart` (Daily Entries ordered approved image launcher using existing RBAC/entitlement-filtered action registry; add permission-checked Create Sales Invoice route).
- **NEW:** `lib/screens/sales_invoice_entry.dart` (safe existing SaleScreen in full-page Sales Invoice container, NO parallel money/posting calculations).
- **NEW:** `test/catalog_reference_29_33_widget_test.dart` five widget cases plus supplier payload test; **UPDATED** `test/catalog_reference_24_28_widget_test.dart` to match Add Customer title capitalization.
- **Intentional gaps:** Supplier payable balance/recent purchases and Supplier form opening balance are not populated from mock figures; Daily Entries unsupported Stock Transfer/Delivery Challan routes omitted; Screen 33 is not full visual clone of reference invoice-line form (it routes to validated existing POS invoice UI). Treat as five screens delivered in **scoped** form, not all pixel approved.
- **Tests pending:** source-level bracket scanner returned balanced for changed Dart files; assistant cannot run Flutter CLI. User should safe FF-pull `feature/daily-entries` at `C:\Projects\BluePOSApp`, run `flutter analyze --no-fatal-infos`, focused `test/catalog_reference_29_33_widget_test.dart` and prior `test/catalog_reference_24_28_widget_test.dart`. Run on Android after tests, do not Save Supplier or Post Invoice on live `bluepos.pk`.
- **Next chat start:** read this checkpoint and `docs/MOBILE_LIVE_SCREEN_QA.md`, check user's analyzer/phone results; if green immediately proceed to next five originals 34–38 with SHA/manifests, UI design system, existing code/backend inspection and same GitHub/docs/test workflow. Frozen login/MFA/Recovery, Sales Invoice web frozen Amounts, strict ULIDs, RBAC/tenant, append-only stock and server-authoritative totals remain rules. Never merge/release without approval.


### 2026-11-14 — Screens 29–33 device 6/6 PASS; Screens 34–38 implementation committed

- **User report:** full 6/6 mobile smoke PASS for 29 Supplier list, 30 Supplier Details, 31 Supplier form, 32 Daily Entries Home, 33 Create Sales Invoice routing, and all-tab stability. Do not confuse device smoke QA with approved pixel parity or analyzer/test logs.
- **Design source:** later individually generated reference PNGs `bluepos_sales_invoice_detail.png` (34), `bluepos_purchase_invoice_dashboard.png` (35), `bluepos_purchase_invoice_screen.png` (36), `bluepos_purchase_invoice_detail.png` (37), `bluepos_sales_return_dashboard.png` (38). These five originals were visually inspected and their bytes SHA256-checked against `/mnt/data/BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`; old rejected generic 92 screenshots are prohibited.
- **Core safety:** Sale/posted purchase/return amounts, stock and accounting are server-authoritative. No parallel posting engine, no amount formula modifications, no new financial endpoint. Reused original authenticated Sale Receipt, Purchase Invoice Editor/draft/post, ReturnDocumentEditor/source-linked posting, existing `TransactionDirectory`.
- **Changed Flutter source:** `lib/screens/receipt.dart` (34 real sale detail title/status); `lib/screens/transaction_widgets.dart` (opt-in `referenceStyle` card for Purchase/Sales Returns, with server-supplied supplier/customer, status, date and amount); `lib/screens/purchase_invoices.dart` (35 styled purchase list, 36 Create Purchase Invoice heading, 37 detail/status header); `lib/screens/returns.dart` (38 styled returns list).
- **Added offline tests:** `test/catalog_reference_34_38_widget_test.dart` (5 widget cases, fake GET only, no write tests). No new package, database migration, backend change, or branch switch.
- **Validation not finished:** code committed; changed source delimiter-balance checks passed. **Flutter analyzer/selected widget tests and on-device QA have NOT been run by assistant.** On Windows `C:\Projects\BluePOSApp`, inspect `git status --short`, safely `git pull --ff-only origin feature/daily-entries`, run `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\catalog_reference_34_38_widget_test.dart"` and previous 29–33 test. Then Hot Restart `R` in running Flutter debug terminal if green; phone acceptance checklist is in `docs/MOBILE_LIVE_SCREEN_QA.md`.
- **Known visual limitations:** the existing invoice-entry/posted accounting workflow is authoritative, so exact mockup geometry, illustrative amounts and fake stock, shipping or discount fields are NOT reproduced. Current mobile app bottom nav remains different from screenshot. Do not claim pixel-level acceptance until compared with device screenshots. No Save/Post for QA on production `bluepos.pk`.
- **Next user PASS → next five screens 39–43**, inspect manifest/original PNGs + current backend contracts, implement coordinated smallest changes, tests + docs/handoff; do not stop at status acknowledgment. Keep all frozen pre-login UI, original branch `feature/daily-entries`, ULID/RBAC/tenant isolation, strict server-calculated totals, immutable posted records, safe device authentication and local Android scaffold.

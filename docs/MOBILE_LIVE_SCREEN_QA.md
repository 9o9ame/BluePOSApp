# BluePOS Mobile — live screen QA and checkpoint

**Repository:** `9o9ame/BluePOSApp`  
**Branch:** `feature/daily-entries`  
**Reference:** `docs/design/mobile-92/SCREEN_IMPLEMENTATION_INDEX.md` + `docs/MOBILE_92_MOCKUP_IMPLEMENTATION_HANDOFF.md`  
**Latest stage:** 2026-11-14 — Post-login Dashboard and **POS Sales first presentation pass**

## Scope and hard rules

- **Do not redesign existing pre-login screens**: Splash, Login, Tenant/Mart Code field, MFA/OTP, password recovery and device approval are accepted. Separate tenant selection is NOT required.
- Do not fabricate a live KPI or client-computed financial posting total. POS cart estimates are *before tax*; final totals are server-authoritative.
- The configured API origin is `https://bluepos.pk`. User reported a successful login on the physical Android device after migration.
- **Never press Save Invoice during design-only QA on a live tenant**. That posts a real financial and stock transaction. The same caution applies to returns, payments, purchases and inventory posting.
- This checklist tracks **implementation versus validation versus acceptance** separately.

## Windows PowerShell — exact project location

Project: `C:\Projects\BluePOSApp`

First inspect the local working tree, since `flutter create` previously generated untracked Android files and `analysis_options.yaml` was modified. Do not reset, force-pull or delete anything:

```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git branch --show-current
git pull --ff-only origin feature/daily-entries
```

If Git reports a conflict, overwritten files, branch mismatch or divergence: **STOP** and share the output. Do not use hard reset, clean, rebase or force push.

If pull succeeds:

```powershell
Set-Location "C:\Projects\BluePOSApp"
flutter pub get
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\pos_product_entry_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\dashboard_permissions_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\api_origin_test.dart"
flutter devices
flutter run -d d2b1f972
```

The Android phone was previously reported as Redmi Note 10 `M2101K7AG`, device ID `d2b1f972`. Use the current `flutter devices` ID if it has changed. Keep the Flutter debug terminal open for Hot Reload (`r`) or Hot Restart (`R`).

If `flutter create` is ever rerun, it may re-create `test/widget_test.dart`, a generic `MyApp` starter test. Do not let it obscure the real test suite; inspect generated changes before deciding how to handle them. Existing native Android configuration should not be regenerated simply for a normal UI pull.

## Post-login screen QA

### A. Screen 06 — Dashboard/Home (previous implementation)

1. Log in normally with the existing accepted login screen.
2. Check that actual tenant, branch and warehouse names appear and fit on Redmi Note 10 width; no invented brand/mart names.
3. Check the premium summary is labeled **Today's invoices**, not fabricated Today's Sales money. Compare the value with an authorized server invoice count.
4. Open Quick Actions: New Sale, Products, Invoices and Reports must appear only when permitted. For a lower-permission test user, prohibited tiles and API requests should be hidden.
5. Pull to refresh. Check loading, empty and server-error states, including intermittent connectivity.
6. Test Light/Dark/System and another approved Primary Theme via Settings; UI must remain readable and fit.

**Current state:** Flutter UI code committed; user confirmed login success. Dashboard visual acceptance on device **not yet recorded**.

### B. Screen 07 — POS Sales (this batch)

1. Bottom navigation → **POS**. Confirm the top heading **POS (Sales)**.
2. Confirm `Search products or barcode` button and scan icon are separate, large enough to tap, with no overflow on phone.
3. Tap search: existing authorized Products picker opens. Search a real test product; tap to add. No fake product rows should appear.
4. Tap scan icon: camera view opens. Scan a real test barcode or use manual barcode input. If camera fails, record only the error text and device details, not credentials.
5. Toggle price modes **Default / Retail / Wholesale**; verify the displayed price follows the existing authorized product pricing response. If a mode has no valid price, do not attempt posting.
6. Tap **Walk-in customer** to choose a real authorized customer, then return to Walk-in. Confirm app respects existing branch and permitted customer list.
7. Add a product to the cart; adjust quantity using +/- and edit quantity/discount. The client shows **Estimated item net / Before tax** only, never an invented final tax or stock balance.
8. Open **Proceed to Payment** only to inspect the next screen (without saving). Back returns with cart preserved.
9. Do **not** press **Save Invoice**, **Retry original save**, or any posting action against the live tenant. If an unconfirmed pending sale exists, stop testing and report its safe recovery status instead of adding or retrying blindly.
10. Check landscape/portrait if practical, text scaling, dark mode and long product/customer names.

**Current state:** First catalog-entry layout pass committed in `lib/screens/sale.dart`; `PosProductEntry` widget and two focused tests added. **Not** yet a full inline POS product grid; existing Products bottom-sheet search flow remains intentionally reused. Tests and on-device visual approval are pending.

## Findings / reproducible issue template

Record: screen ID, device/Android version, Light/Dark theme, screen width, steps, observed behavior, expected result, safe error text and screenshot. **Never upload passwords, OTP, customer PII, secure cookies, authorization headers or full production financial data.**

## QA status journal

| Date | Area | Status | Evidence |
|---|---|---|---|
| 2026-11-14 | Login against `bluepos.pk` | User-reported working | Reported in chat; not independently device-verified |
| 2026-11-14 | Dashboard permission tests | Previously reported 2/2 passed by user | User's Flutter terminal logs |
| 2026-11-14 | POS entry search/scan presentation | Code committed; tests written, **not yet executed in this session** | `lib/screens/sale.dart`, `test/pos_product_entry_widget_test.dart` |
| 2026-11-14 | POS first-pass interaction checklist | **6/6 user-reported PASS**: heading, search, separate scanner, price mode, customer card, cart & estimate | User chat results; screenshot/comprehensive acceptance not yet provided |
| Pending | POS product-picker card grid | **New implementation / not yet device-tested** | `lib/screens/products.dart`, `test/pos_catalog_card_widget_test.dart` |
| Pending | POS visual comparison to approved reference | **Not approved** | User screenshot and detailed visual check pending |
| Pending | Final 92 mockups / binary pack upload | **Not complete** | 79,91,92 provisional; PNGs not in repository |

## Next development step

After the user reports POS results and sends a safe screenshot, inspect actual `ProductsScreen` and its product API schema, then consider a **read-only inline POS catalog grid** with search/category chips that reuses existing product permissions and selection. That change must be bounded and cannot modify payment/posting services. If it requires more than seven files, stop and report scope before proceeding. Keep the handoff and this QA document updated at every batch.

## 2026-11-14 — Next POS batch: actual product-card grid in picker

**Previous batch:** User explicitly marked all six POS first-pass checks **PASS** (heading, Product Search, separate Scanner, Price Mode, Customer card, Cart/estimated total). This is interaction-level confirmation, **not** mockup-perfect visual sign-off or authorization/posting acceptance.

**New work:** When user taps POS → `Search products or barcode`, the existing authorized Products picker now shows a responsive two-/three-column product-card grid with actual product image fallback, product name, server-supplied *retail reference price*, and `sales_lookup.in_stock` when supplied. Missing prices/stock display `Price unavailable` and `Stock not shown` respectively; no invented values. The original search, barcode scan, category chips, 25-item pagination and Add callbacks remain. Normal standalone Products tab still uses the original detailed list, not the POS grid.

**Phone check after Git pull / hot reload:** 
1. Open POS → `Search products or barcode`. See product cards arranged in columns (not previous full-width list).
2. Check image/fallback, product name, retail price or unavailable label; stock label only if server supplied.
3. Type search query, switch category chips, tap `Load more products` where available. Check only authorized items.
4. Tap one real test item: picker closes; cart includes same product, quantity 1. Change price mode: **card price is retail reference; cart estimate follows selected mode**.
5. Repeat in light/dark and narrow phone orientation. Do not Save Invoice or post financial records.
6. Share sanitized screenshot and any visible overflow or mismatch.

**Focused tests to run locally:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\pos_catalog_card_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\pos_product_entry_widget_test.dart"
```
If pulling updates while `flutter run` is active, first check `git status --short` and use `git pull --ff-only origin feature/daily-entries` in a second PowerShell terminal; then press `r` in the running Flutter terminal. Restart only if necessary. Native build/config unchanged.

**Validation status:** New grid and test code committed via GitHub; Flutter tests/analyzer and device visual checks for this batch **not executed in assistant environment**. Main POS page inline grid remains future work, not yet implemented.


## 2026-11-14 — Approved image 07 compared; main POS inline catalog batch

**Verified design source:** actual `BluePOS_Mobile_92_Screen_Reference_Pack.zip` image `07_Premium_Home_Dashboard.png`. Despite the filename, that image depicts **POS (Sales)**: top branded header, integrated barcode/search field, horizontal category chips, two-column image-led product cards, item prices/stock, docked cart estimate/checkout, and Home/POS/central Scan/Reports/More navigation. The image is a *reference*, not an API or source of fake Coca-Cola/Lays/Nestlé data.

**User feedback:** Previous POS popup/grid tests were all reported PASS. The earlier POS entry six checks were also 6/6 PASS. Both are **user-reported functional checks**, not screenshot-based pixel parity acceptance.

**This batch implemented:**
- `lib/screens/products.dart`: `ProductsScreen.inlineCatalog` reuses the *same existing* authorized product search, category chips, server-side paging and actual image fetch directly within the main POS; inline catalog has a two-column, larger image-first card layout. Normal Products tab retains its original list; modal selection grid remains accessible where previously used. No duplicate endpoint/service.
- `lib/screens/sale.dart`: main POS now embeds that catalog with live search, scan and categories, then price-mode/customer controls and existing cart lines. A docked estimate/cart footer holds `Proceed to Payment`, without touching payment posting. The amount is explicitly **estimate before tax**, not final payable.
- `test/pos_catalog_card_widget_test.dart`: additional image-first narrow-width card regression.
- **No** mock product names/prices/stock, no new finance/API/inventory logic, no web/backend/DB edits and no APK release.

**Exact Windows commands (two PowerShell windows, Flutter already running in Terminal 1):**

```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\pos_catalog_card_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\pos_product_entry_widget_test.dart"
```

After a safe, successful fast-forward pull: in Terminal 1 with `flutter run` still active press `r` for hot reload; if new widget initialization or nesting is stale press `R` for hot restart. Do not rerun `flutter create` or delete local Android files for this UI-only batch. Pull errors require stopping for review; no forced actions.

**Phone checklist (image 07):**
1. **POS** bottom tab: POS (Sales) heading, and **search field plus scan icon on the main POS page**, not only a popup.
2. Search by authorized product name/sku/barcode: results load inside the POS page. Horizontal category chips filter results; tapping product card adds that server product to cart.
3. Product cards should display **two columns**, actual image/fallback, product name, retail reference price (or `Price unavailable`), and real stock when returned (`Stock not shown` otherwise). Mockup examples are never hardcoded.
4. Scroll catalog independently and POS page; ensure no unresponsive nested scroll, clipping, overflow, stuck keyboard, scanner problem or stale category results.
5. Cart footer stays at the bottom with `Estimated item net` and `Proceed to Payment`. Change quantity and price mode, verify the estimate uses current cart, and navigate back from Payment without posting.
6. Test portrait on Redmi Note 10, a long product name, light/dark and empty/loading/network error. If a prior save is unconfirmed, **stop** (do not initiate another invoice).

**Known design gaps — do not claim pixel parity:**
- The reference bottom navigation is **Home / POS / central Scanner / Reports / More**. Current app still uses **Home / POS / Products / Reports / Modules**; changing navigation/routing needs a separate focused review to preserve existing routes and RBAC.
- The reference includes favorites/heart and colored merchandising/product illustrations; no favorites server contract verified, so no fake favorites control has been implemented.
- It depicts `Proceed to Invoice` with a sample final cart total. App intentionally retains real `Proceed to Payment` workflow and **estimated pre-tax** amounts.
- User/device review and Flutter analysis/tests for this new batch remain **pending**; send a safe screenshot of main POS and the test output to record acceptance.



## 2026-11-14 — Incident: other tabs blank after hot reload

- User reports Home works but other tabs appear blank after pulling the approved image 07 main POS layout.
- User's `flutter analyze --no-fatal-infos`: 125 **info** lint findings, no analyzer errors; `flutter test test/pos_catalog_card_widget_test.dart`: **3/3 passed** BEFORE this fix.
- Actual device log: `type 'Null' is not a subtype of type 'bool'` at `ProductsScreen.inlineCatalog` (called from persistent `AppShell` IndexedStack), followed by secondary layout exceptions `BoxConstraints forces an infinite width`, RenderBox not laid out. This points to newly added non-nullable widget fields not initialized in old instances retained across Hot Reload; do not misdiagnose as network/API failure. Layout warnings should be reassessed after fresh restart; separate cause not proven.
- **Fix:** `lib/screens/products.dart`: optional inlineCatalog/imageFirst flags are nullable, and all conditions use `== true`; old hot-reload instances with null fields now take non-inline default paths safely. `test/pos_catalog_card_widget_test.dart` adds an explicit legacy-null imageFirst regression. Existing route ordering/API/posting untouched.
- **Validation pending**: Flutter not executed by assistant. On PC, pull latest on `feature/daily-entries` after `git status --short`, run `flutter analyze --no-fatal-infos` and `flutter test test/pos_catalog_card_widget_test.dart`; then press **capital R** in the active Flutter run terminal (Hot Restart) after successful pull. No need to rerun flutter create or clear session storage.
- **Acceptance check:** Home → POS → Products → Reports → Modules, visit each; ensure no red framework exception or blank page, then inspect POS inline 2-column grid and footer. If any blank page remains after Hot Restart, collect the **first** Flutter exception after restarting and relevant stack; don't rely on repeated RenderBox follow-on lines.
- If `git pull --ff-only` fails due to uncommitted generated files, stop and share output; never reset/clean/force.


## 2026-11-14 — Follow-up incident: IndexedStack layout assertion

- User ran `git pull --ff-only origin feature/daily-entries` successfully through commit `776f009`. `flutter analyze --no-fatal-infos` had 125 info-only issues and no analyzer errors. `flutter test test/pos_catalog_card_widget_test.dart` completed **4/4 passed**.
- Their newer device log shows `!_debugDoingThisLayout` during `RenderIndexedStack.performLayout`, pinpointed at `lib/screens/shell.dart:71` (`IndexedStack`, active index 1/POS); prior trace had also shown `BoxConstraints forces an infinite width`. Logs still show Hot Reload calls; they do not establish a fully fresh app process.
- **Focused attempted layout correction:** `lib/screens/shell.dart` now wraps `IndexedStack` in bounded `LayoutBuilder/SizedBox` with `sizing: StackFit.expand`, to give all preserved pages the exact finite viewport while POS uses a `Column`, `Expanded ListView`, and docked footer. This is a plausible structural fix, **not validated as root-cause resolution**.
- **Added:** `test/shell_layout_constraints_widget_test.dart` covering tight IndexedStack page switching with an Expanded POS catalog/footer and alternative tabs.
- Tests have **not been run for this new patch** in assistant environment. User must run focused test and verify on device after **full app stop and new `flutter run`**, not just Hot Reload. The full restart is specifically warranted by persistent rendering error after multiple hot reloads.
- Windows sequence: `Set-Location "C:\Projects\BluePOSApp"`, `git status --short`, `git pull --ff-only origin feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\shell_layout_constraints_widget_test.dart"`. If successful press `q` in running terminal and rerun `flutter run -d d2b1f972` from that project directory. Don't rerun `flutter create`, reset Git, delete Android folder, or sign out unnecessarily.
- Retest Home/POS/Products/Reports/Modules, then POS search/grid/cart. **Do not Save Invoice** on live tenant. If failure persists, capture first exception after this clean launch (not trailing repeated render assertions) plus which tab first breaks.


## 2026-11-14 — Confirmed first-error root cause and recovery (Home also blank)

- User reports even Home blank after clean `flutter run`. Uploaded log gives **first root exception**, not merely follow-on: `BoxConstraints forces an infinite width`; failing `FilledButton` at `lib/screens/sale.dart:536`, parent `Row` of the docked POS cart footer. `IndexedStack` prelays out inactive POS pages, explaining why Home also went blank. Repeated `RenderBox was not laid out` and `!_debugDoingThisLayout` are downstream symptoms.
- Root source confirmed in `lib/core/appearance.dart`: global themed `FilledButton` uses `minimumSize: Size.fromHeight(48)`, equivalent to infinite width minimum and incompatible with finite Row main-axis layout. `ElevatedButton` has equivalent `Size.fromHeight(52)` risk.
- **Fix:** replace both with finite minimum width `Size(0, 48)` and `Size(0, 52)`. This changes only min-width constraint; enclosing full-width buttons still obtain width from their parents. Do not change frozen screen placement or payment posting behavior.
- **Previous test typo also fixed:** `test/shell_layout_constraints_widget_test.dart` erroneously used `const ListView` constructors and failed compilation. Corrected.
- **Added actual-theme regression** `test/appearance_button_constraints_widget_test.dart` for Row-based POS footer FilledButton and mixed Elevated/ Filled buttons. Note: no Flutter CLI in assistant environment; these newly committed tests **must be run on Windows** before claiming validation.
- **Next steps:** `cd "C:\Projects\BluePOSApp"`, `git status --short`, `git pull --ff-only origin feature/daily-entries`, `flutter analyze --no-fatal-infos`, `flutter test "C:\Projects\BluePOSApp\test\appearance_button_constraints_widget_test.dart"`, `flutter test "C:\Projects\BluePOSApp\test\shell_layout_constraints_widget_test.dart"`. After success, stop running Flutter with `q` and launch `flutter run -d d2b1f972`. Check Home and every bottom tab; avoid any Save Invoice on live tenant.
- **Status:** targeted source correction committed; analyzer/test/device validation **pending**. If another crash, collect the first exception block after a fresh launch.


## 2026-11-14 — Device confirmation: infinite-width recovery PASS

- User explicitly reported **6/6 PASS** after the finite-width button-theme fix: Home visible, POS visible, Products visible, Reports visible, Modules visible, and no blank screen while switching tabs.
- Device-level **visual/render/navigation smoke test confirmed by user**; prior blank-screen incident can be marked **functionally resolved**. This does not assert pixel-perfect Screen 07 fidelity, complete POS workflow, authorization coverage, or invoice-posting validation.
- Root correction in `lib/core/appearance.dart` replaced infinite-width button theme minimumSize with finite `Size(0, 48)` and `Size(0, 52)`. The accompanying app shell layout change remains in place.
- **Focused test status:** Prior user logs showed the first added shell-layout test failed to compile due to `const ListView`; that was corrected. User has not supplied the final analyzer or new theme/shell test outputs, so do **not** claim those specific tests passed.
- **Next:** capture sanitized screenshot of Screen 07 and compare against approved `07_Premium_Home_Dashboard.png` (actually POS Sales). Continue design fidelity with minimal UI changes; never modify frozen pre-login screens or run financial posting on live tenant for design QA.


## 2026-11-14 — Newer individual-image batch: Screen 08 Main Menu + 09 More

**Design source is the newer 10-at-a-time premium image collection**, NOT the rejected generic mockups. Locally verified `/mnt/data/BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv` mapping to:
- **08 Main Menu:** `bluepos_main_menu_dashboard.png`
- **09 More Menu:** `bluepos_more_menu_dashboard.png`
Both PNGs visually inspected. Their illustration assets and mock tenant names are references, not data.

**Implemented:** `lib/screens/modules.dart` now defaults to **More**, with a real authenticated tenant/branch banner, large icon-backed vertical menu rows, and a top-right **Open Main Menu** toggle. **Main Menu** has the five top-level modules plus authorized shortcut rows for Products/Customers/Purchases/Sales. Uses the existing `groups` / `ModuleAction.visible` permission/entitlement checks and existing route callbacks. An available-module row opens that group's existing search/list; “Browse all available modules” retains prior generic directory access. Theme colors derive from `Theme.of(context).colorScheme`, not static mockup colors. Unverified Help & Support and Logout interactions are intentionally not faked.

**Added:** `test/approved_navigation_menus_widget_test.dart` — tenant label, no forbidden Daily Entries with only products.view, Main Menu switch and Products route. **Validation pending**; cannot claim Flutter analyzer/phone test passed.

**Local Windows commands:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"
```
If successful, press `R` in existing Flutter debug terminal for fresh menu state (or `r` first; adding new State fields may require `R`). No native rebuild required.

**Phone QA:**
1. Tap bottom **Modules** tab; verify **More** title, real logged-in tenant and branch, authorized Definition/Daily Entries/Reports/Tools/Administration entries, Settings.
2. Tap **Open Main Menu** (top-right apps icon): verify **Main Menu** title and card rows; only authorized shortcuts appear.
3. Tap Definition: authorized categories/products/etc available via existing grid. Use back arrow to return.
4. Tap Browse all available modules: prior searchable directory still works; back returns to menu.
5. Tap Settings: existing settings opens; back returns. Test Light/Dark, scrolling, long real tenant name and Redmi Note 10 narrow width.
6. Home/POS/Products/Reports tabs remain functional; no blank screens or Flutter layout errors. Do not Save Invoice as part of design QA.

**Known non-parity items:** global bottom nav still Home/POS/Products/Reports/Modules rather than image Home/POS/central Scanner/Reports/More; global app bar unchanged to avoid unrelated navigation/security refactor; Help/Logout in image not wired because not scoped/verified; individual icon artwork differs from generated illustration. Do not describe this as pixel-perfect approved yet.

## 2026-11-14 — User device result: newer Screens 08–09 PASS

User explicitly confirmed **6/6 live checks PASS** for the new Main Menu and More screen batch: (1) Modules tab shows More and real tenant, (2) Open Main Menu works, (3) authorized module rows/shortcuts only, (4) Definition opens existing directory, (5) Settings and Browse all available modules work, and (6) Home/POS/Products/Reports/Modules all stay visible with no blank tabs.

**Scope of acceptance:** physical device functional/navigation smoke check only. Exact pixel parity with newer individual `bluepos_main_menu_dashboard.png` / `bluepos_more_menu_dashboard.png` still needs separate visual signoff. New `test/approved_navigation_menus_widget_test.dart` analyzer/test run logs not supplied; do not claim automated test passed. No financial posting performed or requested. Next candidate reference in numbered pack is 10 Notifications; inspect the exact newer PNG and verify real notification API/permissions before implementing, no invented alert data.


## 2026-11-14 — Newer Screen 10: Notifications batch

**Previous batch:** User confirmed 6/6 on-device checks PASS for newer Screens 08–09 (More, Main Menu, permission-scoped groups, Definition directory, settings, and stable tabs). This is user-reported functional QA; screenshot parity and automated tests remain distinct.

**Verified design source:** actual newer generated individual image `bluepos_notifications_dashboard.png` (Screen 10), visually inspected. It shows title Notifications, All / Alerts / Activity segmented tabs, icon-backed notification cards, unread indicators, and a bell icon in the common app header.

**Verified backend contract:** `GET /api/devices/access-notifications` returns `notifications`, `unread_count`, pagination and per-alert ULID, kind, timestamps, device_name and username. **Backend strictly limits this endpoint to tenant owner authority** and Device view policy. `POST /api/devices/access-notifications/{notificationUlid}/read` is owner-scoped, scoped to tenant/recipient, and marks read idempotently. Existing `lib/screens/device_admin.dart` already uses this response. No unified API exists in inspected API routes for mock purchase-posted, stock alerts, daily-sales summaries or backups.

**Implemented:**
- NEW `lib/screens/notifications.dart`: NotificationsScreen fetches real owner-scoped device access notices; responsive NotificationsView uses actual theme, icons and card layout, All/Alerts/Activity UI, unread count, explicit mark-read action, refresh, loading, non-owner (403), error and no-data states. Activity displays explicit not-available notice instead of fake activity feed. Neither server-supplied PII nor device identifiers are logged.
- UPDATED `lib/screens/shell.dart`: bell icon in app header opens Notifications screen via existing Navigator; no change to five working tabs, product/financial routes or frozen login.
- NEW `test/notifications_screen_widget_test.dart`: four widget regressions for server-provided card/read callback, Activity unsupported state, restricted owner state, and tab callback.

**Phone QA — after successful Git pull and tests:**
1. Home app header: bell icon should appear; tap to open Notifications.
2. Owner account: real device access notification cards appear only if such alerts exist; unread indicator and Mark notification read call the existing endpoint. If no notices, see "No notifications". Do not create device approvals just to populate data.
3. Non-owner account: "Device notifications are available to tenant owners only." with no private details.
4. All/Alerts/Activity tabs tap; Activity says the general feed is not provided. Pull-to-refresh should be safe.
5. Back to Home; POS, Products, Reports, Modules remain visible with no blank screens. Check both light/dark mode and narrow Redmi Note 10 width.
6. Screenshot compare to actual newer Screen 10 image: structure/layout is implemented; mock alert data, top-bar artwork and central Scanner bottom nav intentionally differ pending feature/route support. Not pixel approved.

**Windows commands:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\notifications_screen_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\appearance_button_constraints_widget_test.dart"
```
If safe pull succeeds and focused tests pass, press `R` in running Flutter terminal for hot restart when required by new navigation/widgets. Do not destroy local Android scaffolding. No Save Invoice on live tenant for visual QA.

**Validation:** GitHub code commits confirmed; analyzer/test execution and physical-device acceptance for Screen 10 **pending**. No backend/API/DB changes, extra branches, production posting or APK publishing.


## 2026-11-14 — Screen 10 device PASS and newer Screen 11 Definition Home

**User-confirmed Screen 10 Notifications:** all **6/6** phone checks passed: Home header bell, Notifications page opening, All/Alerts/Activity filters, actual device alerts or appropriate empty/owner-only state, refresh/back, and stability of all Home/POS/Products/Reports/Modules tabs. This is functional device confirmation; separate widget test execution and pixel-perfect design parity are not implied.

**Design source for this batch:** original newer individual premium PNG `bluepos_definition_modules_dashboard.png` (Screen 11, Definition Home), visually inspected. It shows the Definition title and a vertical sequence: Products, Customers, Suppliers, Categories, Subcategories, Brands, Units, Price Lists, Barcode Printing, Sale Schemes, Opening Stock, Stock Taking.

**Implementation:** `lib/screens/modules.dart` now opens a dedicated `Definition` list from More/Main Menu using existing permission-gated module actions. Image-order rows are offered only when a matching `ModuleAction` is visible: Products, Customers, Suppliers, Categories, Subcategories, Brands, Units, Sale Schemes, Opening Stock, Stock Taking. Existing routes and permission/entitlement checks are reused; no new endpoint, data, financial or stock writes. Back to More and Browse definition modules preserve prior directory behavior. Color and spacing use existing appearance/theme. **Price Lists and Barcode Printing** have no verified direct `ModuleAction` routing in this existing directory and are **not faked**; further implementation needs actual feature/route verification.

**NEW focused tests:** `test/definition_home_widget_test.dart` covers UI order, authorization-based omission, product routing and back navigation. Assistant cannot run Flutter on user's Windows device; analyzer/test output and device visual check pending.

**Run on PC (after checking status):**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\definition_home_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\notifications_screen_widget_test.dart"
```

After successful pull and tests, press `R` in existing Flutter-run terminal for fresh widget state.

**Phone checks:**
1. Modules → More → Definition. Dedicated **Definition** title and vertical rounded rows appear.
2. Check authorized rows/order; compare to newer PNG. Missing unauthorized items are expected; do not infer every mockup row is available.
3. Products opens same existing Products tab, Customers/Suppliers/Categories/etc their existing authorized destinations.
4. Opening Stock/Stock Taking only appear if permitted and entitlement is present; opening their directories does not post any stock movement.
5. Back to More works; Browse definition modules opens the old searchable definition directory; check light/dark and narrow screen.
6. Verify Home/POS/Products/Reports/Modules and Notifications remain stable without blanks/errors. **Never Save/Post** test transactions on live tenant for UI QA.

**Status:** Code/tests/doc commits confirmed; new Screen 11 on-device acceptance and Flutter analyzer/test execution **pending**. No backend/database edit, no APK publishing, no branch switch/merge. Bottom navigation and image artwork are not yet pixel-identical.


## 2026-11-14 — Screen 11 6/6 device PASS; newer Screen 12 Products Catalog batch

**Previous batch confirmed:** User reported all six Screen 11 Definition Home checks PASS: More → Definition, ordered authorized vertical rows, correct existing route navigation, unauthorized hidden, Back/Browse works, and Home/POS/Products/Reports/Modules/Notifications remain stable. Functional device verification, not yet exact pixel visual approval or final widget-test output.

**Newer source image:** inspected `/mnt/data/bluepos_products_catalog.png` (individual post-rejection Screen 12). Reference shows Products title, search + funnel button, large horizontal image-led rows with product name, SKU, stock pill and right-aligned rupee price, and floating Add Product action. Coca-Cola/Lays/etc are *illustrative*, not to be hardcoded.

**Implementation in GitHub:**
- UPDATED `lib/screens/products.dart`: `CatalogProductRow` displays actual authorized product name/image, SKU, server `sales_lookup.in_stock` and active retail price, or explicit unavailable labels. Standalone catalog layout adds separate filter button which toggles existing API-backed category chips; existing name/SKU/barcode search, pagination and refresh remain. Floating Add Product action only appears for `products.create`; edit only through previously authorized edit route. All sizes/themes use current Flutter appearance.
- UPDATED `lib/screens/shell.dart`: pass explicit `catalogHome: true` for bottom Products tab and refresh path. Prior shell Products supplied `onAdd`; catalogHome prevents it from being mistaken for POS picker. Product tapping now opens details in Products tab; POS picker/inline grid still adds to sale via existing callback. No payment/stock posting behavior changed.
- NEW `test/products_catalog_reference_widget_test.dart`: horizontal row values/callback and missing stock/price no-fake regressions. **Not yet run** on Flutter user's PC.

**Commands:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\products_catalog_reference_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\pos_catalog_card_widget_test.dart"
```
On successful pull + tests, in active `flutter run` terminal press capital `R` for new catalog state fields; preserve local Android files and `analysis_options.yaml`.

**Phone QA:**
1. Bottom **Products** tab: Products heading, search box and filter icon visible. Real product list appears as horizontal image/SKU/stock/price rows.
2. Tap product row → authorized details open (not silently add to POS). Check missing price/stock show unavailable labels.
3. Filter icon reveals API-backed categories; switching categories/search updates rows. Pull-to-refresh and Load more (if available) work.
4. Authorized `products.create` users see Add Product floating action → existing ProductEditor opens; unauthorized users must **not** see this action. Do not submit test product changes against real tenant just for design review.
5. POS tab still has its 2-column product-add catalog; tapping there still adds to cart; do not Save Invoice.
6. Check long item names, portrait, light/dark theme, home/other tabs/Notifications stable, and no Flutter layout errors.

**Known gaps:** Screenshot shows bespoke splash-style branding/wave decoration; shared shell branding/nav and Theme & Appearance remain authoritative until a separately scoped navigation/artwork alignment. Screenshot product photo, SKU, stock and rupee prices are mock examples; actual data may differ. Screen 12 not claimed pixel-perfect yet.

**Status:** commits verified; targeted analyzer, widget tests, physical-device acceptance pending.


## 2026-11-14 — Screen 12 PASS; newer Screen 13 Product Detail implementation

**Previous batch result:** user confirmed **all six Screen 12 Products Catalog on-device checks PASS**: horizontal rows, actual image/SKU/stock/price, row opens details (not POS cart), search and filter, permission-scoped Add Product/editor, and POS/Home/Reports/Modules/Notifications stability. This is *device functional* validation, not automated test execution or final pixel-perfect approval.

**Newer actual design:** Screen 13 from `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`: `bluepos_coca_cola_product_details.png`, verified SHA256 `a63ed25eb751741048d60d9fb527926fd0d9a9516cd289a9ff1e2b9c79b423d9`; image visually inspected, **not** rejected generic pack. Layout has Product Detail header, product image/name/SKU/active/stock/sale price hero, item attribute rows (category/brand/unit/prices/barcode/description), Price & Stock summary and Edit / Print Barcode footer. Sample brand, figures and artwork are illustrative; never hardcode.

**Backend verification:** `GET /api/products/{productUlid}` uses `ProductController::show`, product policy `authorize('view', $product)`, and ProductResource. Supported fields include ULID, name, SKU, is_active, image_url, category, brand, base_unit, primary_barcode, purchase_rate, reorder_level, description and active retail price. Stock appears only if server includes `sales_lookup.in_stock`; no fake quantity or reorder. Existing ProductEditor handles authorized product edits. Do not make barcode printing button until a verified mobile route and permissions exist.

**This batch:**
- NEW `lib/screens/product_details.dart`: `ProductDetailsScreen` fetches fresh authorized detail via public ULID only and handles loading/failure/refresh, uses `ProductDetailsView` for responsive image-first hero, attributes and Price & Stock summary, with server-available fields or explicit unavailable labels. Purchase rate displayed only for users with `products.edit`, and Edit button also requires permission, calling existing editor with reload on save.
- UPDATED `lib/screens/products.dart`: Products tab product tap (or barcode lookup in catalog-home) pushes ProductDetailsScreen instead of the old small modal; POS picker continues adding to cart via `onAdd`, no financial flow changes.
- NEW `test/product_details_widget_test.dart`: four regression tests for actual supplied values, permission-limited purchase/edit, unavailable fields and authorized edit callback.

**Phone QA:**
1. Bottom Products → select an authorized product. A full **Product Detail** screen opens, not old small sheet; product name, image, SKU, status/stock and price are populated from API.
2. Scroll to Category, Brand, Unit, Sale Price, Barcode, Stock in Hand, Description (where supplied). Missing fields explicitly display 'Not available' or 'Stock not shown'.
3. Check Price & Stock section; Reorder Level shows only if returned. Do not compare reference mockup's 168/50 or Coca-Cola branding to live products.
4. With `products.edit` permission, **Edit Product** opens existing ProductEditor. Without permission, Edit and Purchase Price are not shown. For UI QA, do not Save any real product mutation.
5. Back to Products preserves catalog. POS product tap must still add to cart, never open this read-only details screen.
6. Light/dark, long names, narrow physical Redmi Note 10, Home/POS/Reports/Modules/Notifications remain stable. Do not Save Invoice or Post Stock movements on production just for testing.

**Windows commands:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\product_details_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\products_catalog_reference_widget_test.dart"
```
After a safe successful pull and tests, press capital `R` in already-running Flutter debug terminal to initialize the new route/widgets.

**Known visual gap:** New details page approximates reference hierarchy with app Theme & Appearance, rather than embedded mockup gradients or exact product artwork; Print Barcode button is not faked pending verified mobile workflow. Full screenshot-level design acceptance and user Flutter tests for Screen 13 **pending**. No backend/db changes, APK release or branch switch.


## 2026-11-14 — Screen 13 compilation blocker corrected (user build evidence)

- User requested future **5 screens per development batch** instead of one; preserve exact newer individual design PNGs, permission/tenant contracts, QA and handoff every batch. **First resolve current build errors before advancing.**
- User's actual `C:\Projects\BluePOSApp` console: successful `git pull --ff-only` through previous Screen 13 checkpoint; `flutter analyze --no-fatal-infos` reported 130 findings including **two blocking errors**, and BOTH `product_details_widget_test.dart` and `products_catalog_reference_widget_test.dart` failed to compile.
- Blocking errors: `lib/screens/product_details.dart:182:14 Expected to find ']'` caused by an extra `)),` in product hero Row; `lib/screens/products.dart:260:10 validPublicUlid undefined` caused by calling a helper not imported in that screen. The Products file also had an unused `_price` warning.
- Fix commits: `28c65d1c6d77cbcc7bfc7253d31e0e3b715c5261` removes extra closing bracket; `ac3d203ebb9de796012dbd0addd1d8ad5f5baa9b` uses 26-character Crockford ULID regex already used in ProductDetailsScreen and removes unused `_price`. Minimal 2-source-file changes, **no visual redesign, financial/server changes, or persistent DB edits**.
- Test run remains **PENDING** on user's Windows Flutter environment; assistant cannot claim fix passes. On second PowerShell terminal:
```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\product_details_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\products_catalog_reference_widget_test.dart"
```
- Existing modified `analysis_options.yaml` and untracked `android/`, `.idea/`, `.metadata`, `bluepos_app.iml`, `widget_test.generated.bak` are local user work: **do not reset/clean/delete**. Pull was previously FF-safe with these files.
- After green analyzer (no `error` or `warning`) and focused widget tests, use `R` Hot Restart in running Flutter terminal; verify Product Details and all five tabs. **Do not Save product/transaction** on production just for UI QA.
- New development batches should target **five consecutive scoped screens** (next numbered 14–18 after Screen 13 acceptance) with source-image verification, safe reuse of backend APIs/RBAC, focused tests, QA and handoff. Do not claim five completed if blocked by actual design/API dependencies.


## 2026-11-14 — Second user build log: duplicated Products source + lazy Edit test fix

- User supplied a new Windows log after pulling the previous fixes. `flutter analyze --no-fatal-infos` still failed (309 findings; many follow-on errors); `products_catalog_reference_widget_test.dart` could not compile; `product_details_widget_test.dart` reached **3/4 tests passed**, with `Authorized edit action invokes existing editor callback` failing from `StateError: Bad state: No element` on `ensureVisible`.
- **Confirmed actual source:** `lib/screens/products.dart` had an unterminated raw-regex string at line 260, followed by a **duplicated** end-of-file `showDetails/_price/build` section beginning after the proper class closing brace. This arose from the prior edit, not from Flutter environment or user code. The many `Navigator` ambiguous imports, `widget` undefined, and duplicate build errors were cascading parsing errors.
- FIX commit `f6ca0cdf7468e92c8ce4ad02ec8b53bdaf56cbff`: repaired `RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')`, removed the accidental duplicate tail (495 → 373 source lines); now exactly one `showDetails`, two card widgets plus one ProductsState `build`, no unused `_price`. GitHub read-back verified file ending and regex.
- TEST FIX commit `c2fd7f2d83b185617a80a5535fec4c0ce7b4e139`: changed Edit widget regression to `tester.scrollUntilVisible(...)` instead of `ensureVisible` on a button not yet built by lazy `ListView`. No app runtime UI changes from the test fix.
- **Still pending:** No Flutter installation on assistant runtime; user must rerun analyzer and the same focused tests. Never claim PASS until Windows CLI output confirms. Keep `analysis_options.yaml`, `android/`, `.idea/` and other generated local files untouched.
- Windows:
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\product_details_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\products_catalog_reference_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\pos_catalog_card_widget_test.dart"
```
- On green focused tests, press **capital R** in running Flutter terminal and check Products → details → Edit (do not save), POS add-to-cart, other tabs and no blank screen. If errors persist, send only first error and failing test block.
- Future development batch size agreed: **five screens per batch**. Screens 14–18 are **planned only**, not implemented; do not expand before this build is stable.


## 2026-11-14 — Five-screen implementation batch 14–18 (PC validation/device pending)

**Gate cleared from user-provided Windows build:** `git pull --ff-only` successful to previous checkpoint; `flutter analyze --no-fatal-infos` reported **127 informational lints, zero errors or warnings**, and focused tests reported **Product Detail 4/4 PASS, Products Catalog 2/2 PASS, POS Catalog Card 4/4 PASS**. Total 10/10 passed. Physical device is temporarily unavailable: user will test these five new screens **together later**.

**Newer design sources, visually inspected and SHA256 matched to SCREEN_MANIFEST.csv (not old rejected pack):**
- 14 Categories — `bluepos_category_management_screen.png`
- 15 Add Category — `bluepos_add_category_form.png`
- 16 Subcategories — `clean_bluepos_subcategories_screen.png`
- 17 Add Subcategory — `bluepos_add_subcategory_form.png`
- 18 Brands — `premium_bluepos_brands_directory.png`

**Implemented on `feature/daily-entries`:** `lib/screens/catalog_master.dart` now renders three themed, search/filter-driven vertical master lists (Categories, Subcategories with real parent category label, Brands) and separate full-screen Add/Edit Category and Add/Edit Subcategory forms instead of the old bottom sheet. Forms preserve existing permission-based create/edit APIs, server category selection, name, description and active state; any edit still uses the public ULID and existing PATCH endpoint. All changes reuse the same catalog master implementation, with no parallel service or backend/DB edits. The code-generator fields in the original images are represented by **read-only 'Automatically generated'** because backend controllers call `GenerateCategoryCodeAction`/`GenerateCatalogMasterCodeAction`; client must not submit code. The design image's icon/color chips are present as theme-based decoration only and are **not persisted** (no verified image/icon contract); branded example product counts are **not fabricated**.

**Focused test added:** `test/catalog_master_reference_batch_widget_test.dart` includes tests for each of five screens, RBAC visibility, API-derived category/brand/subcategory fields, form code read-only and parent selection, and payload omitting server-generated code. **New tests NOT EXECUTED by assistant**; local Flutter CLI is unavailable. Do not report batch as tested or phone-approved.

**Windows PC validation while phone is unavailable:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_master_reference_batch_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\definition_home_widget_test.dart"
```
If a command fails, **STOP before continuing new batches** and paste the first meaningful error; don't reset/clean local `analysis_options.yaml` or generated Android files.

**Combined future phone checklist — do not save to real tenant:**
1. More → Definition → **Categories**: branded heading, search, funnel filter, rounded category rows from real tenant data, permitted **Add Category** action.
2. **Add Category** opens a dedicated full-page form: name, read-only generated code, optional description, Active/Inactive, Cancel and Save Category. Inspect only; don't submit.
3. **Subcategories** shows real subcategory names, actual server parent category labels, search/filter; **Add Subcategory** opens dedicated page with required parent Category dropdown fetched from server. Inspect only.
4. **Brands** displays actual name and generated code, search/filter, permitted Add Brand action (pre-existing form workflow). No fake product totals; do not create test records on production.
5. Verify unauthorized users cannot see Add/Edit controls; empty/loading/error states, long names, dark/light, narrow Redmi Note 10 layout; back navigation works across all five screens.
6. Home, POS grid, Products Catalog, Product Detail, Reports, Modules, Notifications remain stable; no blank tabs. Never Save Invoice, Post Stock or submit live category changes merely for visual QA.

**Visual gaps tracked:** exact illustration artwork/gradient footer waves and selectable persisted icon/color palettes from the PNGs are not reproduced because shared Theme & Appearance and actual backend contract take precedence. Final pixel-level comparison awaits phone screenshots. This is an implementation batch, **not full visual acceptance**.

**Next handoff:** after PC tests and later device QA PASS, proceed with next five newer images **19–23** as one batch; inspect actual manifest/images and live API contract first, never reuse rejected generic set.


## 2026-11-14 — User PASS for Screens 14–18; next 5-screen batch 19–23

**Previous batch accepted by user:** User explicitly confirmed **all five Screens 14–18 PASS on their mobile device**. This is physical-device functional confirmation; latest CLI analyzer and Screen 14–18 dedicated widget-test output were not provided, and exact screenshot pixel parity was not separately established.

**Verified newer reference images (SHA256 equals manifest; rejected old pack excluded):**
- 19 **Add Brand**: `bluepos_add_brand_form.png`.
- 20 **Units**: `bluepos_units_management_screen.png`.
- 21 **Add Unit**: `bluepos_add_unit_form.png`.
- 22 **Price Lists**: `bluepos_price_lists_dashboard.png`.
- 23 **Add Price List**: `bluepos_add_price_list_form.png`.

**API contract inspection:** `GET/POST/PATCH /api/brands` and `GET/POST/PATCH /api/units` exist in verified backend routes, guarded by existing policies. `StoreBrandRequest` supports `name`, optional `description`, `is_active` and server-generated `code`. `StoreUnitRequest` supports `name`, `symbol`, `allows_decimal`, `is_active`; the design's `base conversion factor` is NOT a verified Units API field. Neither `/api/price-lists` nor a corresponding controller/resource was found in inspected backend routes and expected paths. **DO NOT claim Price Lists is functional.** Do not invent names, prices, price-list types, effective dates, defaults, API endpoints or persistence.

**Implementation in GitHub branch `feature/daily-entries`:**
- **19 Add Brand — working authorized flow**: existing `CatalogMasterScreen` full-page Add Brand now includes server-generated **read-only code** and existing name/description/active controls. Mockup's brand icon/color and country-of-origin are not persisted because no contract was verified; icon uses Theme & Appearance.
- **20 Units — working authorized list**: existing `CatalogMasterScreen(config: units)` now displays actual unit name and server-returned short symbol, search and active filter, authorized Add.
- **21 Add Unit — working authorized flow**: full-page name, unit short-name/symbol, optional decimal quantities toggle, active state and backend POST; conversion-factor field is not fabricated, with a clearly worded limitation note.
- **22 Price Lists — UI reference only**: new `lib/screens/price_lists.dart` page with actual reference heading/search/filter composition, an explicit **API integration pending** state and **no mock records/prices**. Navigation via permission-aware Definition → Price Lists (products.view/manage, catalog entitlement).
- **23 Add Price List — UI reference only**: reachable preview with name, code, description, type, applies-to, effective date reference fields, all **read-only**, and **Save Price List disabled**. No client-side posting or invented backend writes.
- `lib/screens/modules.dart`: safe Definition navigation entry for Price Lists; no navigation tab or permission architecture changes.
- `test/catalog_reference_19_23_widget_test.dart`: five focused widget tests and one payload unit test. Assistant runtime cannot execute Flutter, so the new batch is **NOT analyzer/test verified**.

**Exact PC checks:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_19_23_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_master_reference_batch_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\definition_home_widget_test.dart"
```
If tests or analyzer show errors, stop and share the FIRST meaningful error before device testing; do not reset/clean local generated Android files. Use capital `R` in the running Flutter terminal after a successful pull if state updates are stale.

**Phone QA checklist for this five-screen batch:**
1. More → Definition → Brands → Add Brand: full page, name/description, read-only generated code, Active/Inactive and Cancel; no Submit on production merely to review.
2. Definition → Units: actual authorized unit names/symbols in list, search and filter; no invented prices/conversion counts.
3. Units → Add Unit: full form name, unit short name/symbol, decimal toggle, Active/Inactive; no fake conversion factor; Cancel returns.
4. Definition → Price Lists: explicit API unavailable state, no fake Retail/Wholesale/VIP rows. Preview opens Add Price List reference.
5. Add Price List reference: visible form structure and **disabled Save**, Cancel/back work. No remote writes possible from this preview.
6. Check correct RBAC for Brands/Units, no blank tabs, stable POS/Products/Notifications and light/dark/Redmi Note 10 scrolling.

**Known parity/API blockers:** Screen 19 brand icon/color/country-of-origin persistence; Screen 21 conversion factors; Screens 22–23 entire domain API and authorization/persistence. The latter 2 screens are **NOT functional**. Design parity and real device QA remain pending. Once green, next batch 24–28 only after inspecting newer PNGs and backend contracts.

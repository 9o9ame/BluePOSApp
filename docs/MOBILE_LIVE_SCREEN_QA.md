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


## 2026-11-14 — Screens 19–23 PC regression result and focused correction

User provided actual Windows output after fast-forward pull through `c2c5d917`: `flutter analyze --no-fatal-infos` completed with **128 findings: one warning** (`lib/screens/catalog_master.dart:204`, unnecessary `?[]`) and 127 informational lints. `test/catalog_reference_19_23_widget_test.dart` completed **5/6 PASS, 1 FAIL** at Screen 23: `Save Price List` text not found at test line 99 because the footer is below the initially built part of a lazy `ListView`. Prior `test/catalog_master_reference_batch_widget_test.dart` completed **6/6 PASS**. Thus **NOT all tests passed**.

Focused corrections committed:
- `lib/screens/catalog_master.dart`: `field(item['code'], ...)` instead of redundant null-aware access under `isEdit`.
- `lib/screens/price_lists.dart`: key `price-list-save-disabled` added to the existing disabled Save button; no enabling action/API write.
- `test/catalog_reference_19_23_widget_test.dart`: `tester.scrollUntilVisible` on keyed disabled button before testing its text and null `onPressed`.

New tests **not rerun in assistant environment**. PC commands:
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_19_23_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_master_reference_batch_widget_test.dart"
```
Do not mark PASS until these logs confirm it. Price Lists 22–23 remain UI reference only with no verified backend endpoint; Save remains disabled. No branch switch, DB, live catalog Save or stock/financial posting.


## 2026-11-14 — Prior 19–23 tests user PASS; new five-screen batch 24–28

**User confirmation:** Prior Screen 19–23 corrections have **all tests PASS** per user. No raw new test log was supplied in this turn; treat this as user-reported automated validation, not mobile design approval. Previous 22–23 Price Lists screens remain UI-only with disabled Save and no backend contract.

**Correct design sources:** Later individually generated premium PNGs, SHA256 confirmed against `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`; **not** rejected older generic pack:
24 `bluepos_sale_schemes_dashboard.png` — Sale Schemes.
25 `bluepos_add_sale_scheme_form.png` — Add Sale Scheme.
26 `bluepos_customer_directory.png` — Customers.
27 `bluepos_add_customer_form.png` — Add Customer.
28 `bluepos_customer_detail_dashboard.png` — Customer Detail.
All five were visually inspected and show a shared image-first card/search/form style, with illustrative names, financial figures and product promotions. Such mock business data is never inserted.

**Implementation and verified contracts:**
- **24 Sale Schemes — read-only authenticated API-connected:** NEW `lib/screens/sale_schemes.dart` uses `GET /api/sale-schemes` with real `name`, `scheme_type`, `apply_mode`, `starts_on`, `ends_on`, `is_active`; search and Active filter, loading/error/empty. `lib/screens/modules.dart` Definition Sale Schemes action now opens this screen, preserving `sale_schemes.view/manage` + catalog entitlement.
- **25 Add Sale Scheme — UI-only non-submittable reference:** The screenshot's Scheme Code/Discount Value/Applies To does NOT match existing `StoreSaleSchemeRequest` contract: backend requires `name`, `apply_mode`, `min_sale_amount`, `reward_product_ulid`, `max_reward_qty`, etc. The reference form has read-only fields and disabled Save; never invent server promotion calculations or send incomplete requests.
- **26 Customers — real tenant-scoped directory:** UPDATED `lib/screens/parties.dart` for customer row cards, search, active filter, actual code, area/mobile, RBAC-aware Add. Uses existing `GET /api/parties?type=customer`; no fabricated receivable balance or dummy rows. Other vendor/account directory flows preserved.
- **27 Add Customer — full-page authorized existing form:** same `partyPayload`, real `GET /api/coa/account-types`, existing authorized create/edit POST/PATCH; required **Code**, Name, Account Type plus optional Mobile, Contact Person, City/Area and Address; Active status, Cancel. Unlike screenshot, Code and Account Type are required by `StorePartyRequest`; don't omit them. Mockup's Opening Balance/Customer Group/Price Type are not persisted, and Credit Limit editing is deferred to verified financial workflow. **Never submit live customer create for design QA.**
- **28 Customer Detail — new authenticated fetch:** NEW `lib/screens/customer_detail.dart` loads `GET /api/parties/{ulid}?type=customer` with a strict public ULID, renders actual name/code/mobile/area/address/contact/email and server-supplied credit limit, no estimated receivables or fabricated recent invoices. Authorized Edit uses existing Party editor, Other tabs untouched. The backend `/api/parties/{ulid}/ledger` exists but is not yet wired as an unverified generalized transaction list. Safe refresh/error/empty states.
- NEW `test/catalog_reference_24_28_widget_test.dart` includes five widget tests and one payload contract test: supplied scheme data only, disabled scheme Save, customer list, full-page form, details with no fake balances, actual ULID/account type rules. No remote writes in widget tests.

**PC validation on Windows (new tests NOT run by assistant):**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_24_28_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_19_23_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"
```
If any error or widget test failure occurs, stop next screen implementation and share FIRST meaningful compiler/test failure. Do not reset `analysis_options.yaml`, Android-generated files or run tests against a production tenant. New Dart code received a static bracket-balance check only, **not** Dart analyzer or Flutter runtime validation.

**Combined device QA after green CLI:**
1. More → Definition → **Sale Schemes**: actual scheme names/type/mode/date and Active status, search/filter; no hardcoded Ramadan or gift offers.
2. Tap **Add Scheme**: reference-only form displays expected hierarchy but all fields read-only, Save disabled, Cancel works. No promotions posted.
3. More → Definition → **Customers**: authorized real customers, code, mobile/area, search, Active filter. Customer row opens full detail page, not edit modal.
4. **Add Customer**: full-page name/code/account type, mobile, City/Area/address and status; Cancel/back works. No live Save for testing.
5. **Customer Detail**: server data only, optional Credit Limit, no fabricated Receivable Balance/Recent Transactions; Edit permission-gated. Scroll/back refresh.
6. Regression: Home/POS/Products/Reports/Modules/Notifications and previous Definitions remain stable; test Light/Dark and narrow Redmi Note 10. Don't Save Invoice, Post Stock, Create Customers or Apply live promotions for visual QA.

**Known gaps:** Screen 25 editing unsupported until full verified reward-product backend flow; Screen 27 financial opening balance/limit and customer group are not provided by simple party payload; Screen 28 receivable/recent ledger requires separate controlled read-only integration. Do not claim perfect screenshot parity or five fully functional screens; 24,26–28 are implemented UI/API with caveats and 25 is preview-only.

**Status:** GitHub commits confirmed, Flutter analyze/focused tests and device QA for 24–28 **pending**. No backend/DB modifications, branch merge, or release APK.


## 2026-11-14 — User mobile PASS 24–28; newer five-screen batch 29–33

**Accepted prior batch:** User explicitly marked **all six** mobile checks PASS for Screens 24–28: real Sale Schemes/search/filter, disabled Add Scheme preview, actual Customers list/filter, Add Customer full-page Cancel, server-backed Customer Detail/authorized Edit and stability of all main tabs. This is device functional confirmation; no new CLI analyzer log or pixel-perfect sign-off implied.

**Authoritative design references:** later individually generated original PNGs, **not rejected earlier mockups**; SHA256 verified against `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv` and visually reviewed:
- 29 `bluepos_supplier_directory.png` — Suppliers
- 30 `bluepos_supplier_detail_dashboard.png` — Supplier Details
- 31 `bluepos_supplier_form.png` — Supplier Form
- 32 `bluepos_daily_entries_dashboard.png` — Daily Entries Home
- 33 `bluepos_sales_invoice_dashboard.png` — Sales Invoice

**Implementation:**
- **29 Suppliers** — `lib/screens/parties.dart`: existing tenant-authorized `GET /api/parties?type=vendor` directory now has image-style rows showing actual supplier code/mobile/area and search + Active filter; Add Supplier action follows existing permission gates. No fake payables.
- **30 Supplier Details** — NEW `lib/screens/supplier_detail.dart`: full-page detail loaded with public ULID through `GET /api/parties/{ulid}?type=vendor`; displays server supplier name, code, status, mobile, address, area, contact, email, account type; Edit permitted only by existing supplier edit permission. **No manufactured Payable Balance/Recent Purchases or live ledger movement.**
- **31 Supplier Form** — existing shared `PartyDirectory.edit` now renders full-page `Add Supplier` / Edit with required code, name and real `account_type_ulid` selector, optional mobile/contact, City/Area, address and Active/Inactive. Uses existing `partyPayload(type: vendor)` and server POST/PATCH; no opening-balance write, no dummy group, no fake credit-days. Production Save is NOT part of design QA.
- **32 Daily Entries Home** — `lib/screens/modules.dart` adds approved vertical launcher when More → Daily Entries, mapping ONLY to existing authorized `ModuleAction` routes: Sales Invoices history, Purchase Invoices, Sales/Purchase Returns, Vouchers (covers receipts/payments/journal), Expenses and Create Sales Invoice. Browse-all directory retained. Unsupported Stock Transfer/Delivery Challan mockup entries are NOT fabricated.
- **33 Sales Invoice** — NEW `lib/screens/sales_invoice_entry.dart`: Create Sales Invoice opens existing `SaleScreen` inside Scaffold with title. Reuses current server-authoritative POS payment/invoice/stock logic; no parallel posting, calculations or fake invoice numbers. **Not pixel-identical** to Screen 33 invoice line editor; this is functional existing workflow routing, not a new financial implementation.
- **Regression tests:** NEW `test/catalog_reference_29_33_widget_test.dart` (five widget tests + supplier payload), plus UPDATED `test/catalog_reference_24_28_widget_test.dart` for title case after shared Party form polish.

**Required focused PC validation — NOT RUN by assistant (GitHub source/bracket readback only):**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_29_33_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_24_28_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"
```
If any failure, stop next batch and send FIRST actual analyzer/test exception; do not modify frozen login or reset local generated Android files.

**Phone QA (after successful tests and Hot Restart capital R):**
1. More → Definition → Suppliers: real supplier records, code/mobile/area, search/Active filter, permitted Add Supplier action.
2. Tap Supplier → Supplier Detail loads authorized record. Check actual contact/address/account type, no mock payables/recent purchases, permitted Edit/back.
3. Add Supplier: dedicated form with Code/Name/Account Type, optional mobile/city/address/status and Cancel; inspect only, **never Save live supplier** for design checking.
4. More → Daily Entries: reference-style ordered rows open actual authorized Sales Invoices, Purchase Invoices, Returns, Vouchers, Expenses; Browse all works. No unauthorized options appear.
5. Create Sales Invoice opens existing POS editor with product search/cart/payment flow. Do **not** press Save/Post invoice, since it writes real financial/stock records.
6. Confirm all previous 5-tab screens/notifications remain stable in light/dark and narrow Redmi Note 10.

**Status:** GitHub commits/source-structure verification complete. Actual Flutter analyzer/tests and new physical-device acceptance **PENDING**. No web/backend/DB modifications, no APK/release, no branch change/merge.

**Known design parity gap:** Supplier contact artwork/illustrations and Live Payable/ledger panels lack verified customer-authorized summary integration. Screen 33's standalone invoice form geometry does not yet match approved PNG: existing safe POS flow reused intentionally. No financial domain refactor without SOL-level backend/API/security/testing work.

**Next on PASS:** inspect newer individual **Screens 34–38** PNGs, current mobile modules and verified backend APIs before five-screen batch; update handoff and QA in same turn.


## 2026-11-14 — Screens 29–33 user device PASS; newer five-screen batch 34–38

**Previous acceptance:** user explicitly confirmed **6/6 mobile checks PASS**: supplier directory/search/add, supplier details/edit, full-page Add Supplier/Cancel, Daily Entries navigation, existing POS invoice editor opening, and stable Home/POS/Products/Reports/Modules/Notifications. This proves user-reported functional smoke QA, not exact image pixel parity or Flutter CLI output.

**Design references verified visually and by exact source SHA256 against newer individual SCREEN_MANIFEST.csv** (not the old rejected generic ZIP/PDF):
- 34 Sales Invoice Details: `bluepos_sales_invoice_detail.png`
- 35 Purchase Invoice: `bluepos_purchase_invoice_dashboard.png`
- 36 Purchase Invoice Entry: `bluepos_purchase_invoice_screen.png`
- 37 Purchase Invoice Details: `bluepos_purchase_invoice_detail.png`
- 38 Sales Returns: `bluepos_sales_return_dashboard.png`

**This batch implemented on `feature/daily-entries`:**
- **34 — Sales Invoice Detail:** `lib/screens/receipt.dart` now presents the approved detail heading and status/document identification while reusing existing `GET /api/sales/{ulid}`, actual invoice line values, server-computed totals, and existing PDF Print/Share. No mock Coca-Cola lines or recalculated amounts. The existing ReceiptScreen remains the authorized entry; no parallel invoice posting.
- **35 — Purchase Invoice list:** `lib/screens/transaction_widgets.dart` adds optional `referenceStyle` to the shared `TransactionDirectory`: theme-first leading icon tile, real supplier/customer name if available, date, status and real server amount, with search and existing paging. Only enabled for targeted Purchase Invoices and Sales Returns; other directories stay unchanged. `lib/screens/purchase_invoices.dart` enables it.
- **36 — Purchase Invoice Entry:** existing `PurchaseInvoiceEditor` now uses reference **Create Purchase Invoice** section heading for new draft. All actual supplier, warehouse, product/line and financial values remain existing server-authoritative flow. Create Draft/Line Save/Post buttons still have their original permission, confirmation, idempotency/uncertain-state protections. No new payment/post endpoints.
- **37 — Purchase Invoice Details:** existing server-loaded editor shows **Purchase Invoice Detail** section and real status header when opening a document. Existing item rows, server grand total, posted-only payment control, immutable posted behavior and protected Post action unchanged. No fake stock-received counts or purchase discount fields.
- **38 — Sales Returns:** `lib/screens/returns.dart` enables reference-style real return directory cards (number, customer when supplied, status, date, server amount), maintaining existing `ReturnDocumentEditor` source-linked, idempotent return draft and server posting workflow.

**Added:** `test/catalog_reference_34_38_widget_test.dart` with five offline stub-API widget cases: Sale details, Purchase list, Purchase entry, posted Purchase detail and Sales Return list. No test triggers Save/Post. Changed Dart files passed *basic source delimiter-balance check* on GitHub readback; this is NOT Flutter analyzer/test execution.

**PC validation — REQUIRED before claiming this batch passed:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_34_38_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_29_33_widget_test.dart"
```
If any test fails, share FIRST compiler error/test exception; do not force-pull, reset local Android files or change branches. Once clean, press capital `R` in running Flutter debug terminal.

**Combined phone QA:**
1. Open an existing Sales Invoice's receipt/detail (from authorized Sales/History): heading **Sales Invoice Detail**, real customer/number/date/lines/server totals, Print/Share availability. Do not create/post a sale just to obtain one.
2. Daily Entries → Purchase Invoices: actual list has invoice numbers, supplied supplier names, dates, statuses, server amounts; search/pagination/row opening works.
3. New Purchase Invoice: heading **Create Purchase Invoice**, actual supplier/warehouse and draft controls; inspect fields only, **do not Create Draft or Post Purchase** on real tenant for design QA.
4. Existing Purchase Invoice: detail heading, real posted/draft server status, lines and grand total; posted documents don't expose draft edit/post actions.
5. Daily Entries → Sales Returns: real return cards/search; source-linked details open. **Do not Create/Post Return** for visual QA.
6. Regression: Home/POS/Products/Reports/Modules/Notifications, light/dark, narrow Redmi Note 10 all stable; no overflow or blank tabs.

**Known reference gaps:** Exact illustration/pill placements, barcode-scan centered bottom navbar and artwork differ. Server may omit supplier/customer in list rows; no fake fallback values. Screen 36 screenshot's discount/freight calculations and Screen 37 freight/tax composition are not copied as new client calculations—existing purchase domain and server response are authoritative. Screen 34 PDF/print uses existing authenticated server sale, not illustrative sample receipt.

**Validation status:** User prior 29–33 device PASS recorded; new 34–38 code committed with static source checks only, **Flutter analyzer/widget tests/device QA pending**. No backend/DB change, main merge, release, forced Git actions, real money posting or new branch.

**Next on PASS:** inspect *newer original* Screens 39–43, current Flutter APIs/permissions and existing routes, then implement the next five-screen batch with focused tests, QA and handoff in same response. Prioritize compilation fixes before more work.


## 2026-11-14 — Screens 34–38 physical-device result 6/6 PASS

User explicitly confirmed **all six** mobile smoke checks PASS: (34) authorized Sales Invoice Detail with real amounts and Print/Share; (35) Purchase Invoices list shows real supplier/status/amount; (36) Create Purchase Invoice loads existing draft/line editor; (37) Purchase Invoice Detail shows server status/lines/total; (38) source-linked Sales Returns list opens; Home/POS/Products/Reports/Modules/Notifications are stable. This is user-reported **device functional acceptance**, not screenshot pixel parity or confirmation of a newly executed `catalog_reference_34_38_widget_test.dart` suite.

**Explicit hold before Screens 39–43:** User also reported pagination-position problems in screenshots of a **separate localhost Waqas ERP System** at `/admin/extra_charge`, `/admin/journal-voucher`, `/admin/sales-voucher`, and `/admin/commision-voucher` and requested those resolved before the next mobile batch. Those screenshots are not BluePOS Flutter screens. The Waqas ERP repository/source was not found in connected installed GitHub repositories by search (`Waqas ERP`, `waqas`, `extra_charge`). Do **not** change BluePOS Flutter transaction pagination to fix an unrelated web project; obtain Waqas ERP repo/source access before claiming any web pagination fix. No mobile source change in this checkpoint.


## 2026-11-14 — Waqas ERP message withdrawn; newer five-screen batch 39–43

**Correction explicitly from user:** Waqas ERP `localhost:8000` screenshots were accidentally posted in this BluePOS Mobile conversation from a different chat. **There is no web pagination blocker for this project.** Ignore the previous web-pagination hold; do not inspect/edit Waqas ERP or wait for its repository. Continue five-screen BluePOS Mobile batches.

**Previous confirmed state:** Screens 34–38 user device tests were 6/6 PASS: actual Sale Invoice Detail/Print, Purchase list, Purchase Entry, Purchase Details, Sales Returns, plus stable tabs. This is physical device functional smoke acceptance only; the separate focused Flutter CLI test output and exact pixel parity were not supplied.

**Correct newer individual PNG references for current batch**, visually inspected with SHA256 matching `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv` (never use old rejected pack):
- 39 Sales Return Entry: `bluepos_sales_return_form.png`
- 40 Purchase Returns: `bluepos_purchase_returns_dashboard.png`
- 41 Purchase Return Entry: `bluepos_purchase_return_screen.png`
- 42 Purchase Return Details: `bluepos_purchase_return_detail_interface.png`
- 43 Expense Vouchers: `bluepos_expense_vouchers_dashboard.png`

**Implemented on `feature/daily-entries`:**
- `lib/screens/returns.dart`: Screen 39 approved **Create Sales Return** form heading via existing secure `ReturnDocumentEditor`. No changes to original posted-sale selection, returnable-line API, quantity limit validation, double-submit safety, draft creation, confirmed posting or refunds.
- Same existing `ReturnDocumentsScreen` renders **Screen 40 Purchase Returns** using the opt-in reference image-style transaction cards: real document number, supplier if server provided, date, status and server amount. List stays paginated/searchable through `TransactionDirectory`.
- Screen 41 **Create Purchase Return** heading and existing source-linked return draft editor remain in original authorized workflow; no mock supplier, line, tax, discount or return values.
- Screen 42 **Purchase Return Detail** shows real server document number, status, original invoice identification and existing quantity/amount lines; per-line rate appears only when server has unit_cost. Posted records retain existing read-only/post permission behavior; no redundant money or inventory calculations introduced.
- `lib/screens/money_actions.dart`: Screen 43 Expense Vouchers uses approved-style heading, theme-aware icon rows, actual expense account, payment account, date, description, amount, server status (if provided), search and status chips. Only searches/filters the **existing first 100 server-returned records**, clearly labeled "loaded expenses"; does NOT claim full-dataset search or invent pagination. Existing `MoneyActionKind.expense` secured create flow remains unchanged; Add Expense still permission-gated.
- NEW `test/catalog_reference_39_43_widget_test.dart`: 5 offline/widget tests using stub server GETs for entry forms, real purchase return list and detail, no re-post button for posted return, and expense search. No actual Save, Post, Refund or financial DB calls in tests.

**PC commands (all commands in full project directory):**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_39_43_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\catalog_reference_34_38_widget_test.dart"
```
If compile/test fails, capture FIRST meaningful error and fix before continuing. Do not reset/clean tracked or generated Android files. No test on development/persistent DB.

**Phone QA checklist, after successful PC tests and capital R Flutter Hot Restart:**
1. Daily Entries → Sales Returns → Add Return: approved Create Sales Return heading, original posted-sale selector, date/reason/notes; do not Create Draft/Post.
2. Daily Entries → Purchase Returns: server-returned cards with document/status/date/amount, search, list pagination; tap existing entry.
3. Purchase Returns → Add Return: Create Purchase Return heading, original posted-purchase selector, date/reason; do not Save/Post.
4. Open existing Purchase Return: Purchase Return Detail shows server document/status/original purchase/lines/grand total. Posted document does not offer draft line mutations or post button.
5. Daily Entries → Expenses: Expense Vouchers heading, real expense cards, loaded-record search, status filter chips, authorized Add Expense. Do not create/post live expenses. Check no fake amounts or records; note first-100 search limitation.
6. All existing Home/POS/Products/Reports/Modules/Notifications, light/dark mode, narrow Redmi Note 10 remain stable; no overflow/blank screens.

**Known visual differences:** PNGs contain illustrative Coke/Lays lines, colors and footer scanner nav; actual authorized tenant data and Theme & Appearance take priority. Return draft/detail row geometry still leverages proven existing line/editor controls; do not claim perfect visual/pixel parity. Expense list search is local to first returned page, not the whole server. Full backend paging/search for expenses would require separate verified API contract. **New Flutter analyzer/widget tests/device acceptance PENDING**; only GitHub commit + basic delimiter-balanced source read-back completed.

**Next on PASS:** inspect five newer individual PNGs **44–48**, existing contracts and routes, implement as one batch with tests plus this QA and permanent handoff update.


### 2026-11-16 — New screen-numbered 10-batch visual QA workflow (user-selected)

- User wants **one downloadable reference archive** containing the actual later individual premium screen images, a numbered/name-mapped catalogue, 5–10 screens per batch and **pixel-oriented visual + functional review** for each screen (colors/icons/cards/geometry/fields/buttons/navigation/data). Prior functional PASS alone **does not** mean image parity.
- **Artifact produced in current chat**: `BluePOS_Mobile_92_Screens_Numbered_Batches_and_Visual_QA.zip` (140.59 MiB), based on existing 125 MB `BluePOS_Mobile_92_Screen_Reference_Pack.zip`, which is **the curated later premium pack**, not the old rejected generic set. Each of 92 original numbered PNGs was SHA-256 matched to `SCREEN_MANIFEST.csv` before copying. ZIP tested clean. This is a chat downloadable artifact, **not uploaded to GitHub**, so do not imply future GitHub raw archive URL or sandbox link persistence.
- Batch grouping **exactly 10 batches (each 6–10 screens)**: B01 01–10, B02 11–20, B03 21–30, B04 31–40, B05 41–50, B06 51–60, B07 61–70, B08 71–80, B09 81–86, B10 87–92. File structure: `START_HERE.html` clickable gallery; `SCREEN_QA.html` full-size image plus 12-check QA per screen with browser-local progress and JSON export; `MASTER_BATCH_PLAN.md` exact 92 names/statuses; `BATCH_XX_.../BATCH_QA.md` printable checklist; original source manifest.
- **Source caveats**: 07 appears as Premium Home Dashboard in original manifest but is POS Sales implementation reference; 79 duplicate/provisional; 91–92 provisional reused references (not final approved). Mockups contain fictional sample financial figures and occasionally unverified APIs; never turn these into live tenant data, schema or posting logic. Prelogin 01–05 frozen; do not change them without approval.
- **New QA definition of DONE**: for EACH numbered screen, compare reference image to running app (colors/backgrounds, icons, cards/radii/shadows, element positions/spacing, typography, fields/control order, button states, header/tab navigation, Redmi narrow/keyboard, authorized real API values, loading/empty/error), record exact differences and evidence, confirm focused tests, then mark visual+functional PASS or documented approved deviation. Export QA JSON; update handoff/plan after each batch. User wants to inspect every detail personally.
- **Current dev state**: Screens 39–43 implementation delivered on `feature/daily-entries`; device and analyzer tests pending. Newly requested next batch grouping is **Batch 05 = screens 41–50**, but 41–43 have already been implemented: validate/refine them before addressing 44–50. Avoid misleadingly reporting all ten as new. User asked to establish pack/workflow **before** further coding; next implementation cycle should start from 44–50 (seven new screens) within Batch 05 and re-review 41–43, after verifying current code/UI/backend.
- Local Windows Android path `C:\Projects\BluePOSApp`. Don't merge main, reset/clean generated Android files, post live invoices/returns/stock, change frozen screens, or claim unrun tests passed. Do not use accidental Waqas ERP screenshot message as project requirement.


### 2026-11-16 — Batch 01 reference-first development implemented; visual approval pending

**User instruction:** "go ahead" for Batch 01 (01–10), including matching login/auth screenshots to the actual newer pack. The earlier prelogin frozen-design assumption is superseded **only for reference-based visual work**; existing MFA, tenant/mart login, biometric/device security and signed-in behavior remain authoritative. No accepted functional workflows should be removed.

**Exact reference images inspected:** `BluePOS_Mobile_92_Screens_Numbered_Batches_and_Visual_QA.zip` → `BATCH_01_01-10/01_Splash.png` through `10_Notifications.png`. A 5×2 contact sheet and actual source images were inspected. Source `PROJECT_UI_DESIGN_SYSTEM.md` read before changes; Flutter uses existing `Theme.of(context).colorScheme` and `AppAppearance`.

**Committed files and per-screen state:**
- NEW `lib/screens/auth_reference_chrome.dart`: theme-aware reusable BluePOS brand/header and cyan–mint-style wave painter, not hardcoded image color values.
- **01 Splash** UPDATED `lib/screens/splash.dart`: replace prior marketing feature illustration/list with centered branded icon/wordmark, three animated loading dots, caption, bottom wave, preserving session-initialization lifetime (no artificial delay).
- **02 Login** UPDATED `lib/screens/login.dart`: flat reference-style vertically stacked tenant, username and password controls, storefront hero, Welcome Back, blue-themed Login button, biometric option, Remember Me. The old circular geometry is removed. Existing `submit`, login validation, saved accounts, MFA, biometric functions and API auth untouched. Added link to verified password recovery.
- **03 Connect Business**: NOT implemented as separate page. Earlier user explicitly rejected standalone tenant selection and chose Tenant/Mart code on Login; exact image 03 conflicts with existing functional design. No fake tenant/branch selector introduced. Await explicit product-flow decision if separate page is truly desired. May reuse its look within current tenant field without adding a route.
- **04 Account Verification**: current `LoginScreen` MFA challenge state now uses reference Verify Your Account hero, code entry, Verify & Continue, Resend Code, Trust this device, Back to Login. **Not a separate route**, retaining verified API and device trust rules. Six separate digit boxes from PNG not implemented; further pixel QA pending.
- **05 Password Recovery** NEW `lib/screens/password_recovery.dart`: themed recovery screen linked from Login, verified backend POST `/api/forgot-password` requires tenant_code/username; optional follow-up `/api/reset-password` requires tenant_code, username, token, password and confirmation. No email-only assumption or fake reset links; uses real account-scoped endpoints and generic success notice. Must test without submitting actual reset requests on user's live account unless intentionally doing recovery.
- **06 Dashboard** UPDATED `lib/screens/dashboard.dart`: align Quick Actions to three columns on ordinary width rather than four; preserve real server invoice counts, RBAC and no fabricated money KPI.
- **07 POS Sales** unchanged this pass: existing working functional catalog/cart preserved, visual comparison to `07_Premium_Home_Dashboard.png` and screenshot diff still needed.
- **08 Main Menu / 09 More Menu** UPDATED `lib/screens/modules.dart` shared approved menu; added theme-aware wave footer while preserving authenticated menu rows and existing permissions/navigation.
- **10 Notifications** UPDATED `lib/screens/notifications.dart`: reference-style theme-aware wave footer. Owner-only real access alerts/filter/read state preserved; do not fake purchase/low-stock/backup notifications illustrated in PNG.
- NEW `test/batch_01_auth_reference_widget_test.dart`: offline widget coverage for Splash brand+dots+waves, missing recovery tenant/username validation, reusable theme chrome. Tests created, **not executed** on assistant runtime; Flutter/Dart not installed there. Previous user approved core login flow/functionality but **new auth layout needs fresh phone verification**.

**Validation:** GitHub commits and source readback completed. Simple lexical delimiter-balance checks pass for touched Dart files. **Flutter analyzer, new widget tests, mobile tests and pixel-level visual matching are pending.** Do not call this 10/10 screens pixel-complete or fully tested. No backend/DB changes, invoice posting, Git main merge, forced changes or Android generation.

**User Windows PC commands:**
```powershell
Set-Location "C:\Projects\BluePOSApp"
git branch --show-current
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze --no-fatal-infos
flutter test "C:\Projects\BluePOSApp\test\batch_01_auth_reference_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\approved_navigation_menus_widget_test.dart"
flutter test "C:\Projects\BluePOSApp\test\dashboard_permissions_widget_test.dart"
```
After safe pull/tests, press capital **R** in existing Flutter debug terminal for new widget geometry; if no active run, `flutter devices` then `flutter run -d <device_id>` (Wi-Fi Debugging once adapter available). Stop on any compile failure.

**Visual QA:** Open Batch 01 folder images 01–10 next to the phone, check logo shape, top spacing, centered hero, card fields, labels, icon sizing, button geometry, wave footer and light/dark. For 02 verify tenant+username+password and biometric; 04 check authentic MFA only when naturally challenged; 05 check empty-field error without sending reset. For 06–10 validate original API data and authorized routes, and note differences, especially center Scanner bottom tab in image vs stable Products tab app. Don't post a live sale for design QA. Export `SCREEN_QA.html` results after visual compare.

**Next work:** correct any analyzer/layout regression first; then address remaining Batch 01 parity gaps (03 tenant-flow decision, 04 OTP boxes, 06 Dashboard KPI hierarchy, 07 POS product grid and bottom nav safely) with smallest diffs and screenshot-based testing; only mark visual PASS when user approves. Five-to-ten-screen batch expectation remains, but do not fabricate completion where source/API conflict exists.


### 2026-11-16 — Screen 01 Splash visual FAIL and targeted correction

- User supplied side-by-side Chrome WebQA vs `01_Splash.png`: prior brand mark, wordmark scale, color palette, vertically centered positions, text and footer waves differed materially. User explicitly requires exact reference comparison. **Original implementation marked VISUAL FAIL**.
- Reference `BATCH_01_01-10/01_Splash.png` directly opened, dimensions 941×1672 including illustrated phone frame. Interior reference visually maps to a large rounded cyan→electric-blue square cart mark, dark/navy `Blue` + bright-blue `POS` at 50px-class scale, tracked `P O S  &  E R P`, three blue dots, caption and sloping cyan/mint bottom waves with soft white/lavender background. **Phone bezel and illustrated status-bar artifacts are NOT UI elements.**
- Targeted code correction committed in `lib/screens/splash.dart`: self-contained CustomPainter gradient cart glyph and waves, brand color accents, proportional layout positions, animation-preserving dots; no new binary artwork or artificial delay. `test/batch_01_auth_reference_widget_test.dart` asserts explicit logo/wordmark keys. No auth, session, money, server, or branch changes. **Flutter tooling unavailable in assistant runtime**; lexical Dart nesting check PASS; actual analyzer, widget test and user visual sign-off PENDING.
- User's source state: `C:\Projects\BluePOSApp` on `feature/daily-entries` (prior commit `07cb923`) has local tracked modification `analysis_options.yaml` and untracked `android/`, `.idea/`, `.metadata`, `bluepos_app.iml`, `widget_test.generated.bak`; do not reset/delete/overwrite. Web-only preview `C:\Projects\BluePOS-WebQA` has lazy-HttpClient startup fix and `lib/web_qa_splash.dart`, Chrome web-server port 8086. Preserve separate WebQA `api.dart` fix and keep live app API unused for visual previews.
- Safe update: pull `feature/daily-entries` with `git pull --ff-only origin feature/daily-entries` in original project, copy **only** new `lib/screens/splash.dart` to WebQA (existing Flutter web server hot restart R, browser refresh); compare against PNG at 375×866 and screenshot. As Chrome preview uses actual Flutter widget, no fake login/session.
- Target status **Screen 01 = correction delivered, visual QA pending**, **Screen 02 = visual QA FAIL**, not claimed pixel-perfect. Fine-tune actual differences by user screenshot and device dimensions. Frozen auth security remains preserved.


### 2026-11-16 — Screen 02 Login second reference comparison/correction

- User supplied side-by-side Chrome 375x857 and `02_Login.png`, stated layout improved but not an exact copy. **Visual QA remains FAIL/pending.** Main differences: cartoon storefront too large, white flat-looking inputs vs soft raised blue gradient card, cyan-blue button curve/highlight, no separate face-unlock icon, shadows, typography/spacing.
- Source inspected: same original reference PNG plus existing actual `lib/screens/login.dart`, `lib/screens/login_reference_visual.dart`, and web visual design system before edits.
- Updated `lib/screens/login_reference_visual.dart`: narrowed illustrated storefront face, alternating canopy fabric/scallops, softened glow/cloud shapes and gradient curves on Login button.
- Updated `lib/screens/login.dart`: explicit `filled: false` to avoid theme input fill overriding card chrome, gradient reference fields with soft shadow/rounded edges/divider, branded fingerprint + face icon pair and separator; preserve actual `submit`, tenant code, MFA, saved account, biometric and password recovery flows. No auth API changes.
- Updated `test/login_layout_test.dart`: replace obsolete `login-circle` and old wordmark assertions with current reference viewport/geometric checks at 320/360/393 widths. Existing launch/functional tests still need execution.
- Git commits on existing branch `feature/daily-entries`, no new branch or main changes. Exact files in second correction: `lib/screens/login_reference_visual.dart`, `lib/screens/login.dart`, `test/login_layout_test.dart`, `docs/MOBILE_LIVE_SCREEN_QA.md`.
- **Validation:** Source/Flutter lexical nesting check PASS for Login + painter files; Flutter/Dart CLI unavailable in assistant environment, so typecheck/widget tests/device visual QA **NOT RUN**. Reference artwork is approximated with vector primitives; do not claim pixel-perfect identical to raster mockup until user side-by-side approves it.
- Local instructions: in `C:\Projects\BluePOSApp`, `git pull --ff-only origin feature/daily-entries`; copy only `lib/screens/login.dart` and `lib/screens/login_reference_visual.dart` into `C:\Projects\BluePOS-WebQA\lib\screens` (preserve local WebQA `api.dart` lazy initialization); press capital `R` in already-running port-8085 Web Server terminal and refresh Chrome. For static responsive QA use 375x857. Browser production login remains unsupported due to `dart:io` HTTP client; do not request real credentials or claim authentication works in Chrome.


### 2026-11-16 — Batch 01 consolidated visual pass (user requested 5–10 screens together)

The user rejected iterative single-screen cycles and requires one coordinated reference-driven batch. The side-by-side `02_Login.png` reference still differs in storefront/fields/scale despite earlier iterations. **Do not call it pixel-perfect or user-approved.** Actual newer source images `01_Splash.png` through `10_Notifications.png` directly reviewed.

**Code delivered on `feature/daily-entries` this pass:**
- `lib/screens/login.dart`: Screen 04 account verification has six visually separate OTP digit slots over a real bounded, numeric six-digit `TextField`. Existing MFA challenge ULID, trust option, resend, errors, backend verify, no dummy OTP.
- `lib/screens/password_recovery.dart`: Screen 05 uses consistent BluePOS login-brand, login-style background/waves, input faces and gradient action; existing real tenant/username/token/password reset endpoints unmodified. Mockup says email link but actual API expects tenant+username, so no fabricated email flow.
- `lib/screens/auth_reference_chrome.dart`: BluePOS reference cyan+mint curved footer instead of purple theme footer for menu/notification chrome.
- `lib/screens/modules.dart`: Screens 08/09 more compact gradient menu cards, colored icon plates, softened shadow; More tenant card mint glass gradient; preserve group permission gating and clickable destinations. No fabricated categories/modules.
- `lib/screens/notifications.dart`: Screen 10 three pill-like filters, white/blue shadow cards, reference waves. Only real owner-authorized device access notifications; mocked purchase, low-stock, backup alerts remain UNAVAILABLE from API.
- `lib/screens/dashboard.dart`: Screen 06 emerald hero/shadows and action icon geometry; preserves live **invoice count** semantics and RBAC. Does not show fictional Today's Sales amount from mockup.
- **Previously committed in same Batch 01 cycle**: Screen 01 corrected cyan/blue Splash and centered cart; Screen 02 vector storefront, fixed brand, colored inputs, gradient login and biometric controls.
- **03 Connect Business**: no separate step, conflicts with user's prior approval to use Tenant/Mart Code on Login. **07 POS Sales**: existing secure POS remains; item cards, cart sticky footer, scanner tab visual parity not yet implemented. Do not sacrifice real product pricing, stock permissions or posting security for design.
- Changed in this consolidated pass: `lib/screens/login.dart`, `lib/screens/password_recovery.dart`, `lib/screens/auth_reference_chrome.dart`, `lib/screens/modules.dart`, `lib/screens/notifications.dart`, `lib/screens/dashboard.dart`. No backend/DB changes, migrations, posting operations, credentials or production data.
- **Validation**: GitHub commit readback and lexical parentheses/brackets check PASS for 6 files. Flutter CLI unavailable in assistant runtime; **flutter analyze, focused tests, actual render, on-device and user visual approval PENDING**. Some reference styling remains an approximation of raster image, do not claim exact 1:1.
- **QA and delivery rule**: one consolidated copy/Hot Restart cycle for modified screens. User original `C:\Projects\BluePOSApp` contains local `analysis_options.yaml` modification/untracked `android/` etc; safe `git pull --ff-only origin feature/daily-entries` only, never reset/remove. Web-only `C:\Projects\BluePOS-WebQA` runs port 8085 with local lazy-HttpClient startup mitigation; keep `lib/core/api.dart` untouched. Copy only modified `lib/screens/` files. Login Chrome UI can render but browser login cannot authenticate (dart:io HttpClient); do not attempt actual login or fake server session to render secure screens. Screen 05 form visual can be navigated without login. Native Android device is needed to validate authenticated screens 06–10 or a separately designed read-only supported preview.


### 2026-11-16 — Recovery screenshot mismatch and browser login error checkpoint

User side-by-side reference screenshot file labelled `03_Password_Recovery.png` vs Chrome WebQA recovery; existing numbered development index maps recovery to **Screen 05**. Be explicit about file label mismatch and do not infer the numbered pack manifest has silently changed.
- Recovery visual FAIL before correction: tiny lock reset glyph, low hierarchy, fields flat and shifted upward, no reference info card, weak Back to Login.
- Updated `lib/screens/password_recovery.dart`: larger gradient lock/mint reset layered art, larger heading and reference vertical spacing, real blue-white rounded input faces with shaded icon plates, reference-styled info card, gradient action and bold Back to Login; preserve real tenant+username scoped reset API and generic eligibility messaging. Do not falsely state an email is sent or imply client knows user eligibility.
- Updated `test/batch_01_auth_reference_widget_test.dart` to cover lock artwork and info card, and remove stale expectation of `AuthReferenceWaves` inside new custom-painted Splash.
- On Chrome WebQA port 8085, `Sign-in failed. Check your connection and retry.` is not evidence of incorrect user credentials. The copied Android-origin `dart:io` HttpClient transport is not browser-compatible; earlier local WebQA lazy-init change merely allowed UI to render. Do NOT test production login, disable security, seed fake sessions or fabricate authenticated backend responses to unlock screens. A separate scoped browser transport design would be required for functional web login; Android real-device auth QA remains pending.
- File scope this change: `lib/screens/password_recovery.dart`, `test/batch_01_auth_reference_widget_test.dart` and this QA doc. No backend or production DB operation, no auth protocol changes. GitHub commit readback + lexical braces check PASS; **Flutter analyzer/tests/actual screenshot after correction unverified**. Keep visual status PENDING USER APPROVAL.
- Local update: safe fast-forward pull on `feature/daily-entries` (respect existing modified `analysis_options.yaml` and untracked android), copy only new `password_recovery.dart` into `C:\Projects\BluePOS-WebQA\lib\screens`, use capital R in running Flutter web-server window on 8085 and Ctrl+Shift+R Chrome. Need not restart command. User can visit Forgot Password without attempting login, but should not submit a real recovery request as visual QA.


### 2026-11-16 — LIVE ANDROID batch, screens 06–10

- User authenticated successfully on physical Redmi Note 10 / Android 12 via wireless ADB `192.168.1.11:38983` and scrcpy. Live Dashboard currently shows tenant Alpha, Main branch, 2453 authorized products, 0 current-branch invoices. This proves *real Android authentication*, not browser authentication.
- Visual comparison used original individually numbered PNGs `06_Dashboard.png`, `07_Premium_Home_Dashboard.png` (the POS reference in the approved batch), `08_Main_Menu.png`, `09_More_Menu.png`, `10_Notifications.png`. The live Dashboard was dark with vertically stacked tall stats, unlike reference light compact KPI grid.
- `lib/screens/shell.dart`: Mobile-only conditional light reference presentation for Home/POS/More (existing Products/Reports default appearance unchanged), BluePOS cart header, hamburger to existing Modules tab, rounded bottom navigation. Existing five destinations stay 0 Home,1 POS,2 Products,3 Reports,4 Modules/More; **cannot relabel Products as scanner** without real scanner route. Profile, notification and refresh actions retained. Note: this visual override is limited to the mobile reference screen; canonical web `PROJECT_UI_DESIGN_SYSTEM.md` applies to React web and says theme/appearance authoritative—do not transplant visual overrides into web, and reconcile mobile user theme preferences before freeze.
- `lib/screens/dashboard.dart`: Two compact blue/gold KPI tiles (all invoices and products) instead of tall dark stats, green hero retained, brighter action cards. Counts are live API totals, not fabricated reference sales revenue, expenses, collections or percent-change metrics. Existing RBAC and entitlement guards unchanged.
- `lib/screens/sale.dart`: Reference pastel POS heading and mint checkout footer for real inline catalog and cart. Existing Decimal calculations, server-side total ownership, attempt/idempotency handling and Payment screen untouched.
- `lib/screens/modules.dart`: Reference five section icon colors/typography; permission-gated Main/More actions unchanged.
- `lib/screens/notifications.dart`: Light reference heading icon + segmented pill filters and existing real device alert list. No fictional invoice/stock/backup alerts.
- **Files changed:** `lib/screens/shell.dart`, `lib/screens/dashboard.dart`, `lib/screens/sale.dart`, `lib/screens/modules.dart`, `lib/screens/notifications.dart`, this QA doc. No schema, backend or financial migrations.
- **Validation:** GitHub source readback, lexical bracket balancing of all five files PASS. Flutter/Dart analyzer, widget tests and Android render after these changes NOT RUN by assistant (Flutter unavailable here), **visual QA pending user side-by-side screenshots and explicit approval**. Do not call Batch 01 finished or pixel-perfect. Risk: reference navigation central scanner differs from live Products tab; mockup finance metrics are not exposed; mobile app appearance settings may differ from reference.
- **Next local validation:** in `C:\Projects\BluePOSApp` safely `git pull --ff-only origin feature/daily-entries` with original worktree unchanged, then capital `R` in already-running `flutter run -d 192.168.1.11:38983` terminal. scrcpy stays open. If compilation error, capture exact Dart lines. Check Home, POS, Modules→Main Menu, Modules→More, notification bell. Do not run posting or test transactions while visual-QAing POS.


### 2026-11-16 — Direct GitHub fix pass after side-by-side Android QA: 06–10

User supplied five side-by-side screenshots (actual Redmi Note 10 scrcpy vs original references 06 Dashboard, 07 POS, 08 Main Menu, 09 More Menu, 10 Notifications), explicitly requesting fixes committed to GitHub and pull commands, NOT repeated checklists or local code uploads. Previous assistant statement that GitHub edits were unavailable was incorrect: connected GitHub `fetch_file/update_file` actions work.

**Files modified on existing `feature/daily-entries` branch (no branch switch/merge):**
- `lib/screens/dashboard.dart` (06): reference orange storefront accent, translucent bar-chart motif on emerald hero, brighter colored quick action cards. KPIs remain live authorized `/api/products`, `/api/sales` counts, no fake reference rupee figures.
- `lib/screens/products.dart` (07): real inline POS product grid now uses white gradient elevated cards, colored image/thumb area (actual API image if available, fallback icon otherwise), navy prices, green stock/add affordance, rounded search. Existing product ULID, catalog filtering, authorized click handler and price data unchanged. The photographed mockup's Coca-Cola/Lays images cannot appear without actual API image assets; do not fabricate merchandise.
- `lib/screens/shell.dart` (06–09): center BluePOS brand, remove extra Home refresh/profile shortcuts (pull-to-refresh and More/Settings remain), preserve actual Products tab rather than relabeling it fake Scan; POS filter shortcut opens real Products catalog.
- `lib/screens/modules.dart` (08/09): search opens actual permission-gated directory, More top Settings opens real Settings, More adds Help & Support through existing Help directory and a real confirmation-based `app.logout()` action with existing server request/local cookie clearing. Decorative cyan/mint footer anchored to viewport; menu list has bottom padding to keep all actions accessible. No new APIs or unguarded data.
- `lib/screens/notifications.dart` (10): force scoped light reference palette instead of inheriting active dark theme, remove duplicated header, contrast-correct pills, anchor decorative waves to bottom, preserve real owner-authorized device alerts/read callbacks and no fake purchase/stock/backup alerts.
- `docs/MOBILE_LIVE_SCREEN_QA.md` updated (this entry).

**Validation:** Fetched readback of all five changed Dart files from GitHub; lexical delimiter balancing PASS. Actual Flutter analyzer, widget tests and Android render after this pass NOT RUN in assistant environment (no local Flutter); user needs `git pull --ff-only origin feature/daily-entries` in original `C:\Projects\BluePOSApp`, then capital `R` in existing Android Flutter terminal, check compiler output. scrcpy stays open. No database modifications, no backend changes, no checkout test transactions.
**Visual parity remains PENDING, not exact PASS:** 06 mockup revenue/collections/expenses versus real invoice/product counts; 07 product photography requires real API photos; 08/09 central reference Scanner navigation differs from existing real Products route; 10 mockup multi-type feed absent in backend. Fixes are code changes, not claims of 1:1 screenshot equality.

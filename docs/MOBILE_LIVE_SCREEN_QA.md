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

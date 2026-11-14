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

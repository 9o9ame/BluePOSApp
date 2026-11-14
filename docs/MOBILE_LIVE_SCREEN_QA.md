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
| Pending | POS visual comparison / phone behavior | **Not approved** | User screenshot and interactive checks |
| Pending | Final 92 mockups / binary pack upload | **Not complete** | 79,91,92 provisional; PNGs not in repository |

## Next development step

After the user reports POS results and sends a safe screenshot, inspect actual `ProductsScreen` and its product API schema, then consider a **read-only inline POS catalog grid** with search/category chips that reuses existing product permissions and selection. That change must be bounded and cannot modify payment/posting services. If it requires more than seven files, stop and report scope before proceeding. Keep the handoff and this QA document updated at every batch.

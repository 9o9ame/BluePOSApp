# BluePOS Mobile — Reference Screen Progress

_Last updated: 2026-11-17. Branch: `feature/daily-entries`._
_Source: numbered 92-image reference ZIP and live Android screenshots supplied by the user._

## Rules for interpreting status

- **Implemented** means Flutter UI code is present on the named module branch, **not** that Android pixel-level acceptance is complete.
- **Visual QA pending** means updated Android screenshots still need comparison to the reference image.
- **Preview only** means a static/navigation-safe design with no writable server endpoint or verified request contract; do not display fake records or enable Save.
- Never invent tenant data, server-supported fields, prices, counts, codes, conversion factors, or account permissions. Real server responses always win over illustrative screenshot content.

## Screen-by-screen delivery

| # | Reference screen | Status | Implementation / remaining work |
|---|---|---|---|
| 01–10 | Auth, Dashboard, Navigation | Earlier work; not re-verified in this pass | Preserve prior approved UI, regression QA pending |
| 11 | Definition Home | Implemented earlier | Prior widget tests exist |
| 12 | Products Catalog | Implemented earlier | Prior widget tests exist |
| 13 | Product Details | Implemented earlier | Prior widget tests exist |
| 14 | Categories | Implemented earlier | Reference-styled real API list |
| 15 | Add Category | UI corrected | Compact controls; no unnecessary generated code input; pinned footer wave; responsive one-line Save label |
| 16 | Subcategories | UI corrected | Live API list, search, filter and FAB; empty state appears when server has no records (not a visual bug) |
| 17 | Add Subcategory | UI corrected | Reference cards, parent selector, status; removed server-generated-code display field; real category ULIDs only |
| 18 | Brands | UI corrected | Real API list and reference styling; no fictional product-count badges |
| 19 | Add Brand | UI corrected | Brand icon/color preview, form cards/status; removed server-generated-code display field; Country/Origin omitted until supported contract exists |
| 20 | Units | UI corrected | Real unit symbols, row badges and icons |
| 21 | Add Unit | Reference-styled UI implemented | Verified name, symbol and allows_decimal inputs; no invented conversion-factor or description persistence; visual QA pending |
| 22 | Price Lists | **Preview only** | Reference header, search shell, CTA, empty/integration notice. No verified Price Lists API |
| 23 | Add Price List | **Preview only** | Reference form and fixed footer. Inputs read-only and Save disabled pending API/RBAC |
| 24 | Sale Schemes | Real-data UI implemented | GET /api/sale-schemes; permission gate, search/filter, real status/dates |
| 25 | Add Sale Scheme | **Preview only** | Reference fields + pinned footer. Save disabled: current server contract requires reward product ULID/quantity not included in mockup |
| 26 | Customers | Reference-styled real API list | Search, filter, compact record cards, authorized Add; customer balances are not invented |
| 27 | Add Customer | Reference-styled existing real API form | Required party code + account type retained; compact fields and centralized small footer; mocked opening balance/credit limit not submitted |
| 28 | Customer Details | Reference-styled authorized detail view | Shared labeled rows, real ULID fetch, no fabricated receivables or transactions |
| 29 | Suppliers | Reference-styled real API list | Search, filter, compact cards and authorized Add |
| 30 | Supplier Details | Reference-styled authorized detail view | Shared detail rows, real ULID fetch, no invented payable summaries |
| 31–92 | Later modules/screens | Not claimed complete by this document | Next batch 31–35; inspect existing code/API before edits |

## Current fixes from user feedback

- Category footer wave previously overlapped the status section; current catalog code places the decorative wave immediately above the pinned bottom action bar, outside scrolling form content.
- Add Subcategory Save action previously wrapped into overlapping lines; `FittedBox(fit: BoxFit.scaleDown)` constrains it to one line.
- Subcategory and Brand generated-code display inputs were removed; their codes remain server-generated and are not submitted by the client.
- Reference forms use theme-aware card colors/spacing and preserve Settings Light/Dark behavior.
- Unit form uses valid API fields; unsupported screen mockup-only fields must not be shipped as falsely functional.

## Shared component system (new in 26–30 pass)

- `lib/widgets/reference_surface.dart` owns `BpReferenceMetrics`, `BpReferenceFormField`, `BpReferenceFooter` and `BpReferenceDetailLine`. Compact field padding, row gaps, action heights, and corner sizes are centralized.
- Screens 23 and 25 now reuse the shared compact form fields/footer. Screen 27 uses the same form fields/footer. Screens 28/30 share detail rows.
- Existing catalog editor and unrelated screens have not all been migrated. Avoid implying every screen uses the shared controls; migrate incrementally only when those screens are in scope.
- Button height reduced to 43 logical px; preview Save remains disabled. Existing server-generated-code field removal in 15/17/19 is preserved.

## Validation

- Repository files edited on `feature/daily-entries`; no main merge.
- Focused tests: `test/reference_11_15_smoke_test.dart`, `test/catalog_reference_16_20_test.dart`, `test/mobile_reference_21_25_test.dart`, `test/mobile_reference_26_30_test.dart`.
- **Pending:** `flutter analyze`, actual focused `flutter test` on the Windows checkout, device layout review for 15–30, API contract verification for preview-only features.
- The agent environment has no Flutter/Dart SDK, so test execution success is **not** claimed.

## Safe update workflow

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git branch --show-current
git pull --ff-only origin feature/daily-entries
flutter analyze lib/widgets/reference_surface.dart lib/screens/catalog_master.dart lib/screens/price_lists.dart lib/screens/sale_schemes.dart lib/screens/parties.dart lib/screens/customer_detail.dart lib/screens/supplier_detail.dart
flutter test test/reference_11_15_smoke_test.dart test/catalog_reference_16_20_test.dart test/mobile_reference_21_25_test.dart test/mobile_reference_26_30_test.dart
flutter run
```

If the pull fails due to DNS/network, the Android app still runs **old local code**. Don't claim the latest UI is installed until `git log -1 --oneline` confirms the new branch commit.

## Important source-of-truth note

The mobile GitHub repository does **not** contain `PROJECT_UI_DESIGN_SYSTEM.md` at its root as of this update. The uploaded BluePOS web master/current-state files describe the separate web project, so do not silently replace the mobile reference images or mobile source with web assumptions. Preserve the frozen Sales Invoice UI.

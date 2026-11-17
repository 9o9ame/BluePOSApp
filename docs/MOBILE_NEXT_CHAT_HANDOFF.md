# BluePOS Mobile — Next Chat Handoff

_Updated 2026-11-17. Authoritative working repository: `9o9ame/BluePOSApp`, branch `feature/daily-entries`._

## Read this first

Continue with **implementation**, not planning-only responses. The user expects the assistant to use the connected GitHub read/write tools directly and commit changes; do not ask for already supplied files. The user's reference visual source is the ZIP named `BluePOS_Mobile_92_Screens_Numbered_Batches_and_Visual_QA.zip` with numbered PNGs. User compares live Android screenshots against those images. Light theme is primary because original reference screenshots are light; explicit Dark/System choices must still work.

Development routing: start task with Recommended mode/model/usage/reason. For UI tasks, first seek `PROJECT_UI_DESIGN_SYSTEM.md` (it was not present in the mobile repo when checked); use approved reference PNGs and current code as the mobile basis, flag doc conflicts rather than guessing.

## Architecture / boundaries

- Flutter mobile app, independent from BluePOS React/Laravel web project.
- No code changes on `main`; module work stays on `feature/daily-entries` until approved.
- Real APIs/ULIDs only; server handles prices, stock, permissions, codes, transactions. No invented backend data or fake product counts.
- Do not change frozen web Sales Invoice geometry.
- Preserve API/RBAC and tenant isolation; use existing `AppController`, `BlueposApi`, existing catalog flows.
- Do not use destructive DB or Git commands.
- Avoid claiming tests/build have passed without actual execution.

## Current state — what was changed

- `lib/screens/catalog_master.dart`: Category/Subcategory/Brand/Unit reference cards and forms, pinned Save/Cancel; wave belongs below scrollable form, not over Status; Submit button text constrained to one line; generated-code inputs removed from Subcategory and Brand; Add Unit styled for the verified name/symbol/decimal API inputs.
- `lib/screens/price_lists.dart`: screen 22 list reference shell and screen 23 Add Price List reference form. Preview-only, **no Price Lists API verified**, no fake rows and disabled Save.
- `lib/screens/sale_schemes.dart`: screen 24 real /api/sale-schemes list with search/filter and server response-driven rows; screen 25 design-preview form with disabled Save due to verified server contract mismatch.
- Tests: `test/catalog_reference_16_20_test.dart` and `test/mobile_reference_21_25_test.dart`; earlier `test/reference_11_15_smoke_test.dart`.
- Progress document: `docs/MOBILE_REFERENCE_PROGRESS.md` describes each screen through 25 and pending 26–30.

## User's precise requests and resolution

1. Bottom cyan/green wave painted behind Category Status area: the current catalog code uses `bottomNavigationBar: Column(... AuthReferenceWaves, SafeArea action buttons ...)`; it is intentionally outside the form `body`.
2. Add Subcategory Save label overlapped/wrapped: constrained to one-line `FittedBox`. Verify on device at narrow width.
3. Remove **all generated-code placeholder fields** from forms when codes are server-generated (Subcategory, Brand). Do not recreate them in future screens. Editable code fields in unsupported preview-only designs must never be presented as working server submissions.
4. Next five screenshots are **21 Add Unit, 22 Price Lists, 23 Add Price List, 24 Sale Schemes, 25 Add Sale Scheme**; UI pass committed. Actual Android visual QA is still needed.
5. User wants persistent progress and next-chat handoff; keep these docs updated after each batch.

## What is still pending / honesty boundary

- **Run on user's Windows Flutter installation**: analyze 3 affected Dart files and run focused tests. Our execution environment did not have Flutter/Dart binaries. Distinguish static source inspection from actual test execution.
- Compare fresh Android screenshots for screens 15–25 against user PNGs. Do not promise pixel-perfect until compared.
- There is no verified Price Lists CRUD endpoint. Screens 22/23 should stay preview-only; implementing CRUD requires backend contract, authZ, migrations and tests in approved domain scope.
- Screen 25 cannot legitimately post the illustrative mockup without a reward product and quantity required by the current Sale Scheme server contract. No silent fake write.
- Reference 21 includes Base Conversion Factor and Description, but those fields are not in verified current mobile units payload; keep unsupported display-only elements out until contract confirmed.
- Subcategories list may correctly show 'No subcategories yet' because the account's API currently returns zero records.
- UI screenshots contain illustrative category/brand/unit names; display real tenant data, never seed demo values.
- `PROJECT_UI_DESIGN_SYSTEM.md` missing from mobile repo. The root `BLUEPOS_MASTER_CONTEXT.md` / `BLUEPOS_CURRENT_STATE.md` attachments refer to web project rules, not proof of mobile screens' current code.

## Continue after approval

1. Run latest focused Flutter checks and fix any analyzer/runtime errors. Re-read latest repo file before editing: other commits might land.
2. Obtain screenshot comparison for 15–25, resolve only remaining visual mismatch without changing real data.
3. Move to reference images **26 Customers, 27 Add Customer, 28 Customer Details, 29 Suppliers, 30 Supplier Details**, inspect existing screens/APIs/permission checks and implement in small safe commits.
4. After each batch update both `docs/MOBILE_REFERENCE_PROGRESS.md` and this handoff, report exact commit SHA, tests, pending items.

## Pull / verify commands

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git branch --show-current
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/screens/catalog_master.dart lib/screens/price_lists.dart lib/screens/sale_schemes.dart
flutter test test/reference_11_15_smoke_test.dart test/catalog_reference_16_20_test.dart test/mobile_reference_21_25_test.dart
flutter run
```

Do not overwrite user local changes blindly; resolve Git network/DNS pull failure separately if encountered.

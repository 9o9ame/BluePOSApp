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

## Latest pass: shared sizing and screens 26–30

- `lib/widgets/reference_surface.dart` now owns `BpReferenceMetrics` (field padding/spacing and 43px action height), `BpReferenceFormField`, `BpReferenceFooter`, and `BpReferenceDetailLine`.
- 23 Add Price List and 25 Add Sale Scheme were migrated to shared compact fields/buttons. Both remain preview-only, disabled Save.
- `lib/screens/parties.dart` now uses shared form fields/footer for 27 Add Customer and reference-style real directory cards for 26 Customers / 29 Suppliers. Existing `partyPayload`, RBAC, ULIDs, and server account-type selection retained. Mobile/screens 26–30 should not display illustrative numbers as live.
- `lib/screens/customer_detail.dart` and `lib/screens/supplier_detail.dart` now use reference header, cards and shared compact detail rows for 28 Customer Details and 30 Supplier Details. They still intentionally do not invent receivable/payable amounts or transaction history.
- New focused test: `test/mobile_reference_26_30_test.dart` (not yet executed on Flutter SDK).
- **Not every screen uses the shared component yet.** Don't broad-refactor frozen modules; migrate each next batch only when needed.

## Web repository contract inspection and current mobile fixes (2026-11-17)

Directly inspected `9o9ame/bluepos` branch `main` in:
`PROJECT_UI_DESIGN_SYSTEM.md`, `backend/routes/api.php`,
`backend/app/Http/Requests/Parties/StorePartyRequest.php`,
`backend/app/Http/Requests/Parties/UpdatePartyRequest.php`,
`backend/app/Http/Resources/PartyResource.php`,
`backend/app/Http/Controllers/Api/PartyLedgerController.php`,
`backend/app/Accounting/PartyLedgerBalanceSummary.php` and
`backend/app/Accounting/AccountLedgerBuilder.php`.

- Web repo **was not edited**. It confirms `code`, `name`, `account_type_ulid` required for party creation; email, credit_limit_amount (4 decimal places), and credit_limit_days supported. No customer-group/price-list API was found in the current routes.
- `lib/screens/parties.dart`: now sends verified email, credit limit string, credit days integer; validates input; keeps required code and account type. List now uses **POST /api/parties/ledger-balances** in <=200-item batches, shows only returned posted balances, never mislabels a credit limit as financial balance; the UI remains usable if balance API errors.
- `lib/screens/customer_detail.dart` and `lib/screens/supplier_detail.dart`: now pass authorized party ULIDs into shared real ledger view, show server credit policy and truncate long codes safely.
- `lib/widgets/party_ledger_summary.dart`: new shared GET `/api/parties/{ulid}/ledger?type=customer|vendor` flow with posted-only closing balance, last-5 journal lines, retry and pageable View Ledger. Values are from backend response; no client-side derived accounting.
- `lib/widgets/reference_surface.dart`: shared compact `BpReferenceStatusSelector` used by party form.
- Opening balances use dedicated GET/POST + `post` endpoints: do NOT treat this as a regular property of party creation. Further accounting flow requires transactional security/posted immutability tests and approval. No sample balances/transactions should ever be displayed as real.
- Price Lists API still absent in inspected `api.php`: Screens 22/23 remain previews. Sale Scheme CRUD exists, but form 25 preview cannot submit without correct server request model.
- `PROJECT_UI_DESIGN_SYSTEM.md` exists in **web** repo, not mobile; apply design principles to Flutter shared widgets without copying React CSS.
- After latest changes **Flutter tests and Android visual QA remain unexecuted**; compile errors/edge cases must be prioritized before more screens. Minimum checks: `flutter analyze` for affected files, `flutter test test/mobile_reference_26_30_test.dart`, Android manual data+ledger QA.

## Latest: detail actions and reference batch 31–35 (2026-11-17)

**User's current request:** Side-by-side bottom **Edit** / **View Ledger** buttons on Customer Detail and Supplier Detail matching reference PNGs, plus five more screens (31–35) and continued documentation.

- `lib/widgets/reference_surface.dart`: added reusable `BpReferenceDetailActions` with small height and side-by-side permissions-sensitive Edit / View Ledger controls.
- `lib/screens/customer_detail.dart` and `lib/screens/supplier_detail.dart`: hooked footer into the page Scaffold, with real authorized ledger navigation using existing `BpPartyLedgerScreen`. Removed redundant inline full-width Edit button.
- `lib/screens/parties.dart`: **31 Add Supplier** form reorders visible fields to align with reference; retains required editable Code and Account Type from Laravel `StorePartyRequest`. No invented Opening Balance or Supplier Group field, both of which require domain-specific verification.
- `lib/screens/modules.dart`: **32 Daily Entries** uses colorful reference action rows bound to existing RBAC/entitlement-aware module actions. No nonexistent direct receipts/delivery routes fabricated.
- `lib/screens/sales_invoice_entry.dart`: **33 Sales Invoice** remains existing frozen POS `SaleScreen` with server calculation and posting; no UI geometry modification or duplicate invoice engine.
- `lib/screens/receipt.dart`: **34 Sales Invoice Detail** reference header, real invoice line summary, totals, and pinned Print/Share actions. Existing authorized server sale detail and PDF export retained.
- `lib/screens/transaction_widgets.dart`: **35 Purchase Invoices** now uses reference cards/header/search/Add Purchase when `referenceStyle` is enabled, while `PurchaseInvoicesScreen` still handles real existing purchase draft and posting workflows.
- `test/mobile_reference_31_35_test.dart` added, static delimiter check performed, **Flutter compile and device QA still pending**.
- `docs/MOBILE_REFERENCE_PROGRESS.md` updated to mark 31–35 with precise completed vs pending work.

Next development batch: **36–40**, but FIRST ask user to run focused Flutter analyze/tests or inspect reported errors. User will supply Android screenshots for visual QA. Don't claim pixel-perfect parity or full runtime validation from static source checks. Continue on `feature/daily-entries`; do not switch to `main`.

Suggested commands on Windows:

```powershell
cd "C:\Projects\BluePOSApp"
git pull --ff-only origin feature/daily-entries
flutter analyze lib/widgets/reference_surface.dart lib/screens/customer_detail.dart lib/screens/supplier_detail.dart lib/screens/parties.dart lib/screens/modules.dart lib/screens/receipt.dart lib/screens/transaction_widgets.dart
flutter test test/mobile_reference_26_30_test.dart test/mobile_reference_31_35_test.dart
flutter run
```

## Latest reference batch 36–40 (2026-11-17)

**Requested screenshots:** 36 Create Purchase Invoice; 37 Purchase Invoice Detail; 38 Sales Returns; 39 Create Sales Return; 40 Purchase Returns. The 92-PNG ZIP contains these under `BATCH_04_31-40/`.

GitHub code changes on `feature/daily-entries`:

- `lib/widgets/reference_surface.dart`: **`BpReferenceWorkflowActions`** shared compact, accessible two-action footer with dynamic labels, permissions/disabled callbacks supplied by each domain screen.
- `lib/screens/purchase_invoices.dart`: 36/37 use compact shared field tiles, real supplier/date/warehouse selection, original server-backed draft/line/post operations, server amounts and reference item cards. Footer separates Create Draft/Save Header from Post Purchase and disables posting until an authorized draft has lines. Existing duplicate Post button removed. Posted purchase adds Print PDF from authorized response and **View Ledger** opening the supplier party ledger only with valid supplier ULID and supplier view/manage permission; NOT a purchase-specific ledger.
- `lib/screens/transaction_widgets.dart`: generic reference directory reuses real endpoints, now renders return icon/source information, search and a **loaded-record** status filter, and green Add Return action for screens 38/40.
- `lib/screens/returns.dart`: 39 Create Sales Return and existing purchase return editor use real source selection, server returnable lines, compact form/item cards, and safe Save Draft/Post Return footer. Existing `SaleReturnAttemptStore` idempotency on uncertainty and server stock/accounting mutation remain untouched. Never invent client return/refund totals.
- `test/mobile_reference_36_40_test.dart`: source ULID keys/endpoints and compact enabled/disabled action tests; **not run here**.
- `docs/MOBILE_REFERENCE_PROGRESS.md`: screens 36–40 statuses recorded.

**Important limitations / next actions:** Run Flutter analyzer and focused tests; compare new Android screenshots to approved reference. Verify API authorization and posted purchase print/ledger behaviors on real accounts. No Flutter/Dart SDK in assistant container, so runtime status remains unknown. Check branch `git status` before pull; no force/reset. Next reference batch is **41–45**, not begun. Frozen Sales Invoice creation remains unchanged.

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/widgets/reference_surface.dart lib/screens/purchase_invoices.dart lib/screens/returns.dart lib/screens/transaction_widgets.dart
flutter test test/mobile_reference_31_35_test.dart test/mobile_reference_36_40_test.dart
flutter run
```

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
3. Next batch is references **41–45**. Inspect existing screens, API contracts, frozen design requirements and permissions before editing.
4. After each batch update both `docs/MOBILE_REFERENCE_PROGRESS.md` and this handoff, report exact commit SHA, tests, pending items.

## Pull / verify commands

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git branch --show-current
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/widgets/reference_surface.dart lib/widgets/party_ledger_summary.dart lib/screens/parties.dart lib/screens/customer_detail.dart lib/screens/supplier_detail.dart
flutter test test/reference_11_15_smoke_test.dart test/catalog_reference_16_20_test.dart test/mobile_reference_21_25_test.dart test/mobile_reference_26_30_test.dart
flutter run
```

Do not overwrite user local changes blindly; resolve Git network/DNS pull failure separately if encountered.

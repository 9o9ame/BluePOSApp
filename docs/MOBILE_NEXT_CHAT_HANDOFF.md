# BluePOS Mobile — Next Chat Handoff

_Updated 2026-11-18. Authoritative working repository: `9o9ame/BluePOSApp`, branch `feature/daily-entries`._

## MOST CURRENT STATE — Screens 51–55 implemented/previewed (2026-11-18)

**Branch:** Mobile `9o9ame/BluePOSApp` `feature/daily-entries`; web `9o9ame/bluepos` `main` used READ ONLY for real Laravel API contracts. Do not switch branches or edit web backend without scope and approval. UI screenshot references for this batch: `BATCH_06_51-60/51_Delivery_Challans.png`, `52_Delivery_Challan_Form.png`, `53_Delivery_Challan_Details.png`, `54_Opening_Stock.png`, `55_Opening_Stock_Entry.png`. Reference **visuals only**, not fake tenant records or guaranteed web fields.

**Current verified user results before 51–55:** Windows fast-forward pull successful and `flutter test test/mobile_reference_46_50_test.dart` passed **6 tests**. `flutter analyze` showed **17 INFO-only curly-braces warnings** (`money_actions.dart`, `vouchers.dart`). These exact reported cases were cleaned in the 51–55 GitHub pass, but **analyzer has not been rerun after cleanup**.

**This pass:**
1. `lib/screens/delivery_challans.dart` **NEW, SCREENS 51–53 PREVIEW ONLY**: compact reference list/create/detail look and navigation. The live `backend/routes/api.php` has **NO Delivery Challan API**, so Save Draft, Dispatch, Print and Share remain nonfunctional/disabled. No imaginary customer/invoice, driver, vehicle, quantities or totals. Do not claim these screens production-complete or fabricate backend.
2. `lib/screens/inventory_documents.dart`: **SCREEN 54** `OpeningStockReferenceDirectory` fetches actual `/api/inventory/opening-balances`, groups each server-returned product line with real warehouse/qty/unit_cost/**server total_cost**, supports simple client search, refresh, and ULID tap. API list is bounded by backend to 100 docs; don't assert complete server-wide search. Honest empty state with no data.
3. Same file **SCREEN 55** `openingReference` is a reference-styled *real two-stage* stock draft/line/post form. `CreateOpeningBalanceAction` requires warehouse/date before `UpsertOpeningBalanceLineAction` can add product ULID, 6dp qty, 4dp unit cost, notes. Reuses current `create`, `lineEditor`, `updateHeader`, `removeLine`, `post`, `removeDraft`, authZ and uncertain-create safeguards. The backend calculates totals; posted stock immutable. `Batch/Lot` and `Expiry Date` are NOT in verified Opening Balance line request: omit them (even though screenshot displays them).
4. `lib/screens/modules.dart`: references 51–53 linked as a clearly labeled read-only Delivery Challan preview action (sales.view), Opening Stock uses real directory instead of old generic. `stockTake` and `adjustment` code paths unchanged.
5. `test/mobile_reference_51_55_test.dart` **NEW**, contract and preview widget tests, unexecuted.
6. `lib/screens/money_actions.dart`, `lib/screens/vouchers.dart`: brace-lint cleanup for Windows reported 17 INFO findings; no intended business logic change.
7. `docs/MOBILE_REFERENCE_PROGRESS.md` updated individual 51–55 statuses. **NEXT BATCH 56–60**, but first compile/device-review newly committed screens and last rejected 44/46/48/50.

**Real backend contract verified:** `backend/routes/api.php` inventory opening balances routes `GET /api/inventory/opening-balances`, `POST`, `GET/{ulid}`, `PATCH/{ulid}`, lines `POST/PATCH/DELETE` and `POST/{ulid}/post`. `backend/app/Http/Controllers/Api/Inventory/OpeningBalanceController.php`: header `warehouse_ulid` required, optional `document_date` and `notes` max500; line `product_ulid`, `quantity` decimal scale6, `unit_cost` decimal scale4, notes max500. `OpeningBalanceResource`: document ULID/number/date/status/warehouse/lines; `OpeningBalanceLineResource`: product ULID/name/SKU, quantity, unit_cost, total_cost. No batch/lot/expiry fields. No delivery challan API present in `api.php`. Any delivery backend implementation demands separate justified multi-domain review before enabling writes.

**Do not repeat mistakes:** No fake rows to fill empty lists, no server-generated client document numbers, no screenshot-driven unsupported fields, no client-financial calculations, no new stock/posting logic, no changing frozen Sales Invoice geometry, no posting tests on development DB. Use `bluepos_test` for authorized posting/idempotency/stock tests. Light theme first; Dark/System selectable; use shared `BpReference*` Flutter components and the approved UI source as visual guide.

**Run on user's Windows machine (not verified in assistant runtime):**

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/screens/inventory_documents.dart lib/screens/delivery_challans.dart lib/screens/modules.dart lib/screens/money_actions.dart lib/screens/vouchers.dart lib/widgets/reference_surface.dart
flutter test test/mobile_reference_51_55_test.dart test/mobile_reference_46_50_test.dart
flutter run
```

**Reporting:** GitHub commit plus changed file list; no migration/backend changes; previous 6 tests pass as reported by user, new tests unrun; pixel-accurate Android QA still pending; next reference batch 56–60. This is the latest authoritative section and OVERRIDES historical statements below claiming 51–55 "next."

## ADDENDUM: completion details for the rejected screenshot fixes (2026-11-18)

- Updated `BpReferenceSubpageAppBar` with **opt-in** `titleBelowBack: true`, producing reference-style left-aligned headings below logo/back (130px). Default remains the previous 112px centered title so frozen/approved screens are unchanged.
- Applied opt-in heading to 44 Expense, 46/48/50 voucher editor and voucher directories 45/47/49 only. Do not change global AppBar behavior to fix a single reference.
- In `VoucherEditor.referenceEditor`, empty account lines now render a tappable real `Add Line` entry row, not a large inactive explanatory box. The existing modal/account picker performs the real selected-account input; no dummy records.
- Voucher directory cards use actual server fields with fixed voucher identity tones: Journal indigo, Payment red, Receiving green; document status still comes from the backend. List remains honestly empty when tenant has no records.
- New narrow layout test and optional heading-height regression tests in `test/mobile_reference_46_50_test.dart`. **Not executed** on a Flutter runtime here.
- **Visual focus:** user rejected previous 44/46/48/50 screens. This new code is significantly closer in row density/heading placement but **has not yet been compared against a fresh installed Android build**. Most recent visible old screenshots are not QA of new commits.
- **Current tasks on continuation:** run Flutter analyzer/test after pulling, correct any compiler or overflow issues, compare new phone screenshots; do not skip that and jump to 51–55 claiming 44/46/48/50 approved.
- Web `PROJECT_UI_DESIGN_SYSTEM.md` requires unified controls and voucher identity colors. Web and mobile have separate UI technologies. Manual Payment/Receiving Voucher API is distinct from invoice-specific payment allocation. Preserve that distinction.

## MOST RECENT CORRECTION — 2026-11-18, read before anything below

The user supplied Android screenshots for **44 Create Expense Voucher**, **46 Create Journal Voucher**, **48 Create Payment**, **50 Create Receipt** and strongly rejected the previous visual design: every field was a tall independent card with excessive blank space, unlike the reference's compact one-card horizontal field rows and small right-aligned controls. The rejected UI **has been replaced in code and committed on `feature/daily-entries`**, but a fresh Android screenshot has **not** been received; pixel-perfect approval and Flutter compile remain pending.

**Latest actual changes:**
1. `lib/widgets/reference_surface.dart`: **`BpReferenceInlineRow` + `BpReferenceInlinePanel`**, reusable theme-aware compact horizontal field rows and grouped card. Do not create another page-specific field chrome.
2. `lib/screens/vouchers.dart`: replace the shared `referenceEditor` used by 46/48/50 with a single compact field panel (server-generated voucher number; real date; description/narration; optional book number; Cash/Bank header only for Payment/Receiving), dense actual account-line cards with edit/delete via existing `addLine`, real server debit/credit values after draft creation, existing `save`/`post`/RBAC/idempotency unchanged.
3. `lib/screens/money_actions.dart`: 44 Expense direct-post entry uses same compact field panel with **only** verified web fields (`expense_date`, `expense_account_ulid`, `payment_account_ulid`, positive 4dp `amount`, optional `reference`, `description`). Preview shows the **entered amount verbatim**, not client-derived tax or a fabricated financial total. Existing direct-post attempt safety unchanged.
4. `test/mobile_reference_46_50_test.dart`: new 360px compact grouped-panel and picker interaction test. This test and Flutter analyzer have **not** run in the assistant environment.
5. `docs/MOBILE_REFERENCE_PROGRESS.md`: rows 44/46/48/50 and latest correction history updated.

**Web API contract is mandatory:** Generic voucher `POST /api/vouchers` accepts `type`, `entry_date`, `description`, `book_number`, `header_account_ulid` for cash/bank types, and line `account_ulid` plus `amount` (payment/receiving) or `debit/credit` (journal). No generic manual-voucher invoice/payee/payment-method fields. The reference 48/50 pictures show *invoice-specific settlement*, which is a **different** flow from these existing generic voucher endpoints. Do not fake it or silently wire invoice settlement to journal vouchers. Expense `POST /api/sales/expenses` posts directly; no Save Draft endpoint. Web design-system document identifies Journal=indigo, Payment=red, Receiving=green and requires shared controls; Flutter owns its own `BpReference*` widgets.

**Next instruction to future chat:** Pull latest `feature/daily-entries`, run `flutter analyze` on `reference_surface.dart`, `vouchers.dart`, `money_actions.dart`, and run `flutter test test/mobile_reference_46_50_test.dart`. Fix any compilation/widget failures before claiming screenshot match or proceeding to screens **51–55**. Compare fresh screenshot to user's uploaded 44/46/48/50 references. No backend changes, migrations, deleted data, main merge or production posting tests were made in this correction.

## CURRENT AUTHORITATIVE STATUS — 2026-11-18

**Working repositories:** Mobile Flutter `9o9ame/BluePOSApp` long-lived branch **`feature/daily-entries`**; web Laravel/React `9o9ame/bluepos` **READ-ONLY** contract source on `main`. Do not switch to or implement on mobile `main`. Web repo remains unmodified. Reference visuals: `BluePOS_Mobile_92_Screens_Numbered_Batches_and_Visual_QA.zip`, grouped in numbered batches. Light-first design; preserve user-selectable Dark/System. The web `PROJECT_UI_DESIGN_SYSTEM.md` applies to the web UI and provides shared visual principles; the mobile repo does not have that root file. Keep Flutter styling in existing `BpReference*` widgets rather than copying web CSS.

**Exactly where we are:** Reference screens **01–50 have prior code or safe preview implementations**, with **46–50 implemented in the current pass**. This is *not* a claim of pixel-perfect Android acceptance. Prior screens **22/23/25 are still preview-only** because their required backend integrations do not match/are absent. The user supplied Android comparisons for 41/42/44/45: current app has no populated return/journal data; do not invent reference image records. **Next batch is 51–55**, after focused compile/test and device QA.

**User's non-negotiables:** Work directly in GitHub and commit, not advice-only. Copy images' VISUAL hierarchy, spacing and compactness, **never their sample data, fictional fields or statuses**. Use real fields, permissions, server tenant/branch/warehouse context, ULID APIs, server financial totals, immutable posting, stock append-only, existing idempotency. Keep progress docs and this handoff current. No destructive Git/database commands; posting tests only on `bluepos_test`.

**Latest changed files and current behavior:**
- `lib/screens/returns.dart`: 41 Purchase Return is real source-linked draft/editor; 42 posted/detail is read-only server line/total PDF view. Existing API only shows real returnable stock after selecting a posted purchase. Supplier Reference field is supported. Empty purchase-return listing is expected without tenant data.
- `lib/screens/money_actions.dart`: 43 expenses use paginated real server expenses with filters; 44 title **Create Expense Voucher**, compact actual 6-field direct-post form, not screenshot's fake Draft/Payee/Tax. Existing secure persisted idempotency retry and server posting preserved.
- `lib/screens/vouchers.dart`: 45 Journal directory uses **`GET /api/vouchers?type=journal`**. New **46 Create Journal Voucher** compact reference editor; **47 Payments** uses **`GET /api/vouchers?type=payment`**, **48 Create Payment** locked payment voucher editor; **49 Receipts** uses **`GET /api/vouchers?type=receiving`**, **50 Create Receipt** locked receiving voucher editor. Shared editor displays real server voucher number, entry date, book number/description, account picker, account lines, read-only server debit/credit and RBAC-gated Save Draft/Post. Existing `VoucherAttemptStore` idempotency, validate/modify/post guards untouched; no parallel accounting flow.
- `lib/screens/transaction_widgets.dart`: shared server query (type/status/search/pagination), status badges and Add Journal/Payment/Receipt CTA; true empty state when server returns none. Fake `Balanced`/`Approved`/`Cleared`/mock statuses from screenshots must not be introduced; backend voucher statuses are **draft/posted**.
- `lib/screens/modules.dart`: Journal Vouchers, Payments and Receipts actions connected in permission-gated Daily Entries.
- `test/mobile_reference_46_50_test.dart`: new focused Flutter unit/widget tests for `VoucherKind`, real payload decimal strings and 360px footer. `test/mobile_reference_41_45_test.dart` exists for prior batch.
- `docs/MOBILE_REFERENCE_PROGRESS.md`: per-screen 01–50 status and historical/API notes.

**Actual backend route/field facts (verified via GitHub):** `backend/routes/api.php` and `backend/app/Http/Controllers/Api/Accounting/VoucherController.php` authorize `GET /api/vouchers?type=journal|payment|receiving`, `POST /api/vouchers`, `PUT /api/vouchers/{ulid}`, `POST /api/vouchers/{ulid}/post`. The generic voucher API requires entry_date and lines; allows book_number, description, type and header_account_ulid for cash/bank vouchers. Lines use account_ulid, amount for payment/receiving or debit/credit for journal, with NUMERIC max 4 fractional places; no client-computed debit/credit balance. The expense API `POST /api/sales/expenses` posts directly, **no draft endpoint**. Payment/receipt voucher workflow is **not** the same as `/api/sales/{ulid}/payments` or `/api/purchases/{ulid}/payments`: those invoice-specific payments remain separate.

**Unverified/next actions (DO NOT CLAIM PASS):** Flutter analyzer and tests on Windows; Android screenshot side-by-side visual QA, 360px overflow, actual voucher record selection and post, no-data empty states, authorization/cross-tenant/branch checks, concurrency/idempotency on **bluepos_test** only. GitHub commits and bracket checks alone do NOT prove compilation or runtime correctness. No migrations in this batch. Next reference images: `BATCH_06_51-60/51_...` through 55 — inspect actual ZIP names before implementation.

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/screens/vouchers.dart lib/screens/money_actions.dart lib/screens/transaction_widgets.dart lib/screens/modules.dart lib/screens/returns.dart lib/widgets/reference_surface.dart
flutter test test/mobile_reference_46_50_test.dart test/mobile_reference_41_45_test.dart
flutter run
```

**Historical material below is retained for provenance. If it names an older "next batch", this CURRENT section supersedes it.**

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
- `lib/screens/transaction_widgets.dart`: generic reference directory reuses real endpoints, renders real party/source/amount/status cards, and uses a **server-applied** status filter with enum-backed options; fake Refunded/Adjusted statuses are removed. Green Add Return remains permission-gated.
- `lib/screens/returns.dart`: 39 Create Sales Return and existing purchase return editor use real source selection, server returnable lines, compact form/item cards, and safe Save Draft/Post Return footer. Existing `SaleReturnAttemptStore` idempotency on uncertainty and server stock/accounting mutation remain untouched. Never invent client return/refund totals.
- `test/mobile_reference_36_40_test.dart`: source ULID keys/endpoints and compact enabled/disabled action tests; **not run here**.
- `docs/MOBILE_REFERENCE_PROGRESS.md`: screens 36–40 statuses recorded.

**Important limitations / next actions:** Run Flutter analyzer and focused tests; compare new Android screenshots to approved reference. Verify API authorization and posted purchase print/ledger behaviors on real accounts. No Flutter/Dart SDK in assistant container, so runtime status remains unknown. Check branch `git status` before pull; no force/reset. Screens 46–50 are committed; next batch is **51–55**; Flutter/Android QA pending. Frozen Sales Invoice creation remains unchanged.

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
git log -1 --oneline
flutter analyze lib/widgets/reference_surface.dart lib/screens/purchase_invoices.dart lib/screens/returns.dart lib/screens/transaction_widgets.dart
flutter test test/mobile_reference_31_35_test.dart test/mobile_reference_36_40_test.dart
flutter run
```

## Latest correction after user screenshot comparison (2026-11-17)

**User explicitly rejected the old screen designs** and insists the `9o9ame/bluepos` web application determines real fields and behavior. Avoid adding screenshot-only fields/statuses or fake rows. All fixes below were written directly to mobile `feature/daily-entries`, not to web `main`.

**Verified web sources:**
`backend/routes/api.php`, `backend/app/Http/Controllers/Api/Purchases/{PurchaseInvoiceController,PurchaseReturnController}.php`,
`backend/app/Http/Controllers/Api/Sales/{SaleController,SaleReturnController}.php`,
`backend/app/Http/Resources/{Purchases,Sales}/*Resource.php`,
`backend/app/Enums/{SaleStatus,SaleReturnStatus,PurchaseInvoiceStatus,PurchaseReturnStatus}.php`,
and `frontend/src/pages/{PurchasesPage,SalesReturnsPage,PurchaseReturnsPage}.tsx`. Read actual API contract, not just example screenshots.

**Changes written and committed:**

- `lib/screens/modules.dart`: Sales Invoices now opens real `/api/sales` reference directory; tapping an invoice opens **full** `ReceiptScreen` (no generic bottom sheet). Existing separate Create Sales Invoice route still calls frozen authorized POS editor.
- `lib/screens/transaction_widgets.dart`: dense reference cards use real status/party/source/date/server amounts. Search goes to actual backend, status filter is now **backend pagination**, not just first 25 records. Valid statuses: Sales posted/void; Purchase draft/posted/cancelled; both Return kinds draft/posted. No fictional refunded/adjusted status.
- `lib/widgets/reference_surface.dart`: reusable `BpReferenceCompactField` for dense metadata pairs and shared `BpReferenceWorkflowActions.rightColor` allowing blue View Ledger/Share while Post stays green. Common action height remains 43.
- `lib/screens/purchase_invoices.dart`: real web-verified Supplier ULID, session warehouse ULID, invoice_date, supplier_invoice_number, due_date, payment_terms, freight_amount, other_discount, notes in server payload. Generated `document_number` is read-only. Freight/discount strings validated non-negative 4 decimals; server recalculates totals. Posted detail header is read-only, with real `discount_amount` (not the nonexistent `total_discount_amount`), freight/other charges/tax/grand total; preview only when backend returns data. Existing draft/line edits/posting/uncertain-retry logic is unchanged. Posted Print PDF and authorized supplier-party View Ledger available. No fake purchase-only ledger.
- `lib/screens/returns.dart`: return metadata uses read-only server document number and party from selected posted invoice. After selecting an invoice, show genuine `returnable-lines` preview with remaining quantities (no invented returnable rows). Existing idempotent Sales Return create, line save/post and Purchase Return real flow remain.
- `lib/screens/receipt.dart`: server actual sale items, display-only compact decimal strings, highlighted server total and actual payment summary when available; pinned Print/Share now shares common footer geometry.
- `test/mobile_reference_33_40_web_contract_test.dart`: added numeric 4dp/6dp, ULID boundary, 360px compact field and semantic footer widget checks; **not executed** in this environment.
- `docs/MOBILE_REFERENCE_PROGRESS.md` updated to distinguish implementation vs Android review.

**Key UX honesty:** Mockup 37 shows a POSTED invoice, but the user's screenshot contains a real DRAFT from the backend. Never paint it as posted or enable Print/Post without the existing server-authorized state. Mockup 40 shows fictional purchase returns, but a blank live API result must remain a genuine empty state, not example transactions.

**Remaining:** Full Flutter compile/analyze/test, narrow device QA and live tenant/branch/warehouse/RBAC verification. Do not claim visual approval, posting success, or production readiness from a GitHub write. Backend posting/valuation tests belong on `bluepos_test` only.

Focused commands:

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze lib/screens/modules.dart lib/widgets/reference_surface.dart lib/screens/purchase_invoices.dart lib/screens/returns.dart lib/screens/transaction_widgets.dart lib/screens/receipt.dart
flutter test test/mobile_reference_33_40_web_contract_test.dart test/mobile_reference_36_40_test.dart
flutter run
```

### Additional detail cleanup in the same correction pass

- `lib/screens/purchase_invoices.dart`: screen 37 **posted** invoice now renders a dense read-only Product/Qty/Rate/Amount table with actual server values. Screen 36 and draft 37 retain editable line cards and existing save/post flow.
- `lib/widgets/reference_surface.dart`: `bpReferenceDecimalLabel` shared **display-only** decimal string shortening. Never feed shortened labels into accounting, stock, quantity or money payloads.
- `lib/screens/receipt.dart`: replaces local decimal formatter with the shared helper; uses `BpReferenceWorkflowActions` for Print/Share.
- `test/mobile_reference_33_40_web_contract_test.dart` also covers shared decimal labels; not executed yet.
- Before declaring screens approved, run Flutter analyzer/tests, test real tenant records including empty return lists/draft purchases, then compare Android screenshots to reference.

## Flutter analyzer incident correction — 2026-11-17

Windows verification after `b3bf748` successfully fast-forwarded the mobile branch, but failed to compile `lib/screens/returns.dart:509–513` due to an ambiguous nested conditional with null-aware map reads. Both focused test suites failed **to load**, not because their assertions failed.

**Committed fix:** Return detail/customer-or-supplier name is resolved from already-converted `objectOf(document)` and `objectOf(source)` maps using one type-safe party key before rendering. Removed unused imports from affected files, migrated PDF `Table.fromTextArray` to `TableHelper.fromTextArray`, added braces around the logged guarded flows in Purchase/Return/Transaction widgets, and cleaned the shared display-label interpolation warning. No backend/schema/posting calculations changed.

**Validation:** Structural bracket/quote checks across five touched Dart files passed; **Flutter analyzer/tests have not been rerun in the assistant runtime**. The prior Windows run reported 38 diagnostics including compile errors; user must pull latest branch and rerun targeted checks. Their local `analysis_options.yaml` modification and untracked `.idea/`, `.metadata`, `android/`, `bluepos_app.iml`, `widget_test.generated.bak` were deliberately untouched. Never reset or delete them without explicit approval.

## Latest 41–45 implementation / web contract handoff (2026-11-18)

**Reference PNGs:** `BATCH_05_41-50/41_Purchase_Return_Entry.png`,
`42_Purchase_Return_Details.png`, `43_Expense_Vouchers.png`,
`44_Expense_Voucher_Entry.png`, `45_Journal_Vouchers.png`.

**Web source inspection on `9o9ame/bluepos` main:** `PROJECT_UI_DESIGN_SYSTEM.md`, `backend/routes/api.php`,
`backend/app/Http/Controllers/Api/Purchases/PurchaseReturnController.php`,
`backend/app/Http/Controllers/Api/Sales/ExpenseController.php`,
`backend/app/Http/Controllers/Api/Accounting/VoucherController.php`,
`backend/app/Http/Requests/Sales/StoreExpenseRequest.php` and
`backend/app/Http/Resources/{Sales/ExpenseResource,Purchases/PurchaseReturnResource,Purchases/PurchaseReturnLineResource}.php`.

**Code in `9o9ame/BluePOSApp` `feature/daily-entries`:**

- `lib/screens/returns.dart`: 41/42 purchase returns retain real source invoice selection, actual server remaining return quantities, create/update/draft/line/post authorization. Added real nullable `supplier_reference` to create/update and reload. Posted purchase returns now have read-only server item table, real discount/tax/grand total, actual posting status, and PDF Print. Drafts remain editable; posted movement logic not modified. Do not invent `Adjustment Type` just because mockup shows it.
- `lib/screens/money_actions.dart`: 43 expense directory loads actual `GET /api/sales/expenses` with pagination, server `q` and `date_from/date_to`; cards/read-only sheet display actual expense account, payment account, amount, reference and date. Do not show fake status/document numbers: `ExpenseResource` has none.
- Same file screen 44 Record Expense uses shared compact fields for actual contract: date, expense account ULID, payment account ULID, positive amount max 4dp, optional reference and description. **Important:** `POST /api/sales/expenses` immediately records/posts, with existing persisted `MoneyActionAttemptStore` idempotency. No draft or separate Post endpoint; Cancel/Confirm Expense footer is intentional and server-aligned.
- `lib/screens/vouchers.dart`: 45 journal-only `JournalVoucherDirectoryScreen` uses `/api/vouchers?type=journal` and existing actual draft/post VoucherEditor. New `initialKind` and `lockInitialKind` restrict this journal-only entry to journal type. Back navigation refreshes server results. All-vouchers directory continues to work.
- `lib/screens/transaction_widgets.dart`: journal list now shows actual book number or description, not fictitious customer/supplier. Add Journal label.
- `lib/screens/modules.dart`: RBAC-gated Journal Vouchers action exposed under Daily Entries.
- `test/mobile_reference_41_45_test.dart`: unit/widget smoke tests for real route mapping, 4dp money constraints, journal kind lock baseline and shared compact controls; **not executed**.
- `docs/MOBILE_REFERENCE_PROGRESS.md` updated.

**Boundaries:** No web/API/backend, DB migrations, posted accounting or stock mutation changed. **No Android pixel-perfect signoff, Flutter analyzer/tests, or live tenant/branch/RBAC posting test has been run.** Keep working on `feature/daily-entries`. Do not force Git, reset local user files or switch branches. Next batch is references **51–55** after focused validation.

Focused validation on user's Windows:

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git pull --ff-only origin feature/daily-entries
flutter analyze lib/screens/returns.dart lib/screens/money_actions.dart lib/screens/vouchers.dart lib/screens/transaction_widgets.dart lib/screens/modules.dart lib/widgets/reference_surface.dart
flutter test test/mobile_reference_41_45_test.dart test/mobile_reference_33_40_web_contract_test.dart
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
3. Next batch is references **51–55**. Inspect existing screens, API contracts, frozen design requirements and permissions before editing.
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

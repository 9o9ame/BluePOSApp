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
| 31 | Add Supplier | UI implemented, device QA pending | Reordered existing real party fields to match reference: Supplier Name, Mobile, City, Address, Credit Limit/Days, Contact, Email, then required Code/Account Type; no fake opening balance/group field |
| 32 | Daily Entries Home | UI implemented, device QA pending | Color-coded reference menu uses only existing permission/entitlement-gated actions, including stock flows; no fictional voucher routes |
| 33 | Create Sales Invoice | Existing approved/frozen POS reused | No geometry or posting logic changes in this batch; preserves server totals/stock rules |
| 34 | Sales Invoice Detail | UI implemented, device QA pending | Existing real sale detail + PDF export reused; table-style read-only rows, totals and pinned Print/Share footer |
| 35 | Purchase Invoices | UI implemented, device QA pending | Existing server-backed draft/post flows preserved; shared TransactionDirectory reference list/search and Add Purchase CTA refined |
| 36 | Create Purchase Invoice | Reference-style functional draft editor; device QA pending | Compact server-backed Supplier/Date/Warehouse/Remarks, product cards and shared Create Draft/Post footer; uses existing authorized purchase draft/line/post methods |
| 37 | Purchase Invoice Detail | Reference-style real detail; device QA pending | Server-confirmed purchase lines/totals/status; Print PDF from authorized server response and vendor View Ledger when permitted, without a fake purchase-ledger endpoint |
| 38 | Sales Returns | Functional server list, styled; device QA pending | Real `/api/sales-returns`, search/status filter, compact colored reference cards, Add Return; no sample returns |
| 39 | Create Sales Return | Reference-style functional return editor; device QA pending | Posted original sale selection, server returnable lines, draft/line edit/delete, preserved persisted idempotency key and server Post Return; compact form/item cards and footer |
| 40 | Purchase Returns | Functional server list, styled; device QA pending | Real `/api/purchase-returns`, search/status filters, Add Return; existing server purchase return editor/posting reuse |
| 41–92 | Remaining references | Not claimed complete by this document | Next batch 41–45; inspect reference PNGs and live API before implementation |

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

## Web API contract inspection — 2026-11-17

Source: `9o9ame/bluepos` `main` (`PROJECT_UI_DESIGN_SYSTEM.md`, `backend/routes/api.php`,
`StorePartyRequest.php`, `UpdatePartyRequest.php`, `PartyResource.php`,
`PartyLedgerController.php`, `PartyLedgerBalanceSummary.php`, `AccountLedgerBuilder.php`).
This was an **inspection only** of the web repository; it was not edited.

- The create/update contract **requires** `party_type`, `code`, `name`, `account_type_ulid` on create. Retain real code and account-type fields; do not fake auto-generated codes.
- For customers/vendors `email`, `credit_limit_amount` with NUMERIC(20,4)-style regex, and integer `credit_limit_days` (0..99999) are supported.
- `credit_limit_amount` is **not** an account balance. There is a real tenant/branch-scoped `POST /api/parties/ledger-balances` returning `balances` keyed `customer:<ulid>` or `vendor:<ulid>`. Screens 26/29 now show the posted balance when the authorized endpoint responds instead of mislabeling the credit limit. On failure, omit the amount.
- `GET /api/parties/{partyUlid}/ledger?type=customer|vendor&page=N&per_page=50` returns posted-only `rows`, `totals.closing_balance` and pagination. Screens 28/30 now display the real ledger and a pageable View Ledger route. No fabricated invoices, payable/receivable summaries or client arithmetic.
- `GET/POST /api/parties/{ulid}/opening-balances` and dedicated `.../post` exist, but opening balances are a **separate accounting/posting workflow**. Do not add an arbitrary opening balance amount to party-create payload. Full posting integration requires transaction/idempotency/authZ tests on `bluepos_test` and domain review.
- Price Lists routes are **absent** from current `backend/routes/api.php`; Screens 22/23 remain disabled previews. Sale Schemes CRUD routes are present, but Screen 25 requires a verified full request contract before write enablement.
- Web `PROJECT_UI_DESIGN_SYSTEM.md` exists in the **web** repository. The Flutter application uses its own shared `BpReference*` components; do not copy React CSS directly into Flutter.

### Updated UI implementation status

- **26 Customers:** compact, server-backed list with correct posted ledger balance (not credit limit); long LEG codes truncated to one line.
- **27 Add Customer:** maintained required `code` and `account_type_ulid`; added verified email, credit limit and credit days; compact Account Type dropdown and shared green status selector. Money remains string precision, validated by the server.
- **28 Customer Details:** valid ULID-driven detail, supported Credit Limit/Days and real posted ledger totals, recent 5 entries and pageable View Ledger.
- **29 Suppliers:** same posted balance endpoint with `vendor` request type and server-driven list.
- **30 Supplier Details:** same real ledger, supported credit policy fields and supplier-only authorized data.
- New `lib/widgets/party_ledger_summary.dart` owns shared ledger UI; `BpReferenceStatusSelector` is in the common reference style file.

## Latest pass — detail actions and screens 31–35 (2026-11-17)

- **Customer/Supplier Detail:** shared `BpReferenceDetailActions` footer now pins **Edit** and **View Ledger** side by side. Edit only enabled when the existing permission plus onEdit callback exists. Ledger goes to existing authorized pageable `BpPartyLedgerScreen`. Inline full-width Edit button was removed. Both views use the same code and action metrics.
- **31 Add Supplier:** field order updated to prioritize reference fields, while preserving web API required `code`, `name`, and `account_type_ulid` (the screenshot does not show two of them). The reference's Opening Balance is **not** a normal party attribute; it belongs to a separate posting flow. Supplier Group is not a verified current API field and was not invented.
- **32 Daily Entries:** approved launcher now shows more authorized actual module routes with semantically colored icons. Server permission/entitlement-gated action registry is unchanged; do not create fake submodule links.
- **33 Create Sales Invoice:** unchanged existing `SalesInvoiceEntryScreen` delegates to POS `SaleScreen`; its UI is frozen. No new client posting or total calculation.
- **34 Sales Invoice Detail:** `ReceiptScreen` now uses reference-styled readonly, authorized invoice rows/totals with pinned Print/Share buttons. Existing PDF/OS print/share flows preserved.
- **35 Purchase Invoices:** `TransactionDirectory(referenceStyle: true)` uses a reference header, compact cards, search and Add Purchase CTA. Actual `PurchaseInvoicesScreen` continues to own server draft/header/line/post flow; no parallel purchasing implementation.
- New test `test/mobile_reference_31_35_test.dart test/mobile_reference_36_40_test.dart` covers shared detail actions and disabled Edit state. **Not executed** in current environment.
- Static delimiter/nesting inspection performed on changed Dart sources. Flutter analyzer, tests and Android visual QA **pending**.

## Latest reference batch — Screens 36–40 (2026-11-17)

- Reference PNGs reviewed: `36_Purchase_Invoice_Entry.png`, `37_Purchase_Invoice_Details.png`, `38_Sales_Returns.png`, `39_Sales_Return_Entry.png`, `40_Purchase_Returns.png`.
- `lib/widgets/reference_surface.dart`: added **`BpReferenceWorkflowActions`** using shared 43px button height, single-line responsive labels and caller-owned callbacks. It does not perform financial calculations or posting.
- `lib/screens/purchase_invoices.dart`: screen 36/37 compact real supplier/date/warehouse inputs, server-returned purchase line cards, conditional server totals, Create Draft/Save Header/Post Purchase footer with existing permissions. Posted purchase print exports an authorized server-data PDF; View Ledger opens the existing **supplier party ledger** (not an invented purchase-specific ledger) only when supplier ULID and permissions are valid. No duplicate Post button.
- `lib/screens/transaction_widgets.dart`: screens 38/40 reuse generic real-data `TransactionDirectory`, adding iconography, reference search/filter (filter applies to **loaded** items only) and Add Return CTA. Other transaction directories retain their existing logic.
- `lib/screens/returns.dart`: screen 39 now uses compact shared form fields and returned-items cards; real source selection, server-calculated return totals, existing create/line/post permissions, idempotency and uncertainty handling remain untouched. The same existing editor also opens authorized purchase returns from screen 40.
- `test/mobile_reference_36_40_test.dart`: focused tests for route/source keys, small footer, and disabled Post state were added but not executed in this environment.
- Web contract previously verified: `backend/routes/api.php` exposes `/api/purchases`, `/api/purchases/{ulid}/post`, `/api/sales-returns`, `/api/sales-returns/{ulid}/post`, `/api/purchase-returns`, `/api/purchase-returns/{ulid}/post`, and party ledger. **No purchase-specific ledger endpoint** is implied by the mockups.
- No backend/schema migrations, fake line totals or sample return data. No change to frozen Sales Invoice creation geometry.
- **Pending:** Flutter compiler/analyzer and focused tests; 360–390px device screenshots, Android UI review, real RBAC/API integration QA, server posting and retry tests on `bluepos_test`. The GitHub tool commits are not proof of runtime success.

## Validation

- Repository files edited on `feature/daily-entries`; no main merge.
- Focused tests: `test/reference_11_15_smoke_test.dart`, `test/catalog_reference_16_20_test.dart`, `test/mobile_reference_21_25_test.dart`, `test/mobile_reference_26_30_test.dart test/mobile_reference_31_35_test.dart`.
- **Pending:** `flutter analyze`, actual focused `flutter test` on the Windows checkout, device layout review for 15–30, API contract verification for preview-only features.
- The agent environment has no Flutter/Dart SDK, so test execution success is **not** claimed.

## Safe update workflow

```powershell
cd "C:\Projects\BluePOSApp"
git status --short
git branch --show-current
git pull --ff-only origin feature/daily-entries
flutter analyze lib/widgets/reference_surface.dart lib/screens/purchase_invoices.dart lib/screens/returns.dart lib/screens/transaction_widgets.dart
flutter test test/reference_11_15_smoke_test.dart test/catalog_reference_16_20_test.dart test/mobile_reference_21_25_test.dart test/mobile_reference_26_30_test.dart
flutter run
```

If the pull fails due to DNS/network, the Android app still runs **old local code**. Don't claim the latest UI is installed until `git log -1 --oneline` confirms the new branch commit.

## Important source-of-truth note

The mobile GitHub repository does **not** contain `PROJECT_UI_DESIGN_SYSTEM.md` at its root as of this update. The uploaded BluePOS web master/current-state files describe the separate web project, so do not silently replace the mobile reference images or mobile source with web assumptions. Preserve the frozen Sales Invoice UI.

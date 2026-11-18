# BluePOS Mobile — Reference Screen Progress

_Last updated: 2026-11-18. Branch: `feature/daily-entries`._
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
| 27 | Add Customer | Reference-styled existing real API form | Required party code + account type retained; email/credit limit/credit days supported by real API; opening balance remains separate posting flow |
| 28 | Customer Details | Reference-styled authorized detail view | Shared labeled rows, real ULID fetch, no fabricated receivables or transactions |
| 29 | Suppliers | Reference-styled real API list | Search, filter, compact cards and authorized Add |
| 30 | Supplier Details | Reference-styled authorized detail view | Shared detail rows, real ULID fetch, no invented payable summaries |
| 31 | Add Supplier | UI implemented, device QA pending | Reordered existing real party fields to match reference: Supplier Name, Mobile, City, Address, Credit Limit/Days, Contact, Email, then required Code/Account Type; no fake opening balance/group field |
| 32 | Daily Entries Home | UI implemented, device QA pending | Color-coded reference menu uses only existing permission/entitlement-gated actions, including stock flows; no fictional voucher routes |
| 33 | Create Sales Invoice | Existing approved/frozen POS reused; list navigation fixed | Dedicated Sales Invoices list now opens full ReceiptScreen instead of generic history bottom sheet; separate Create Sales Invoice still uses existing authorized POS |
| 34 | Sales Invoice Detail | UI refined, device QA pending | Server sale items, compact displayed decimals, highlighted backend grand total, actual payment method/amount banner only when payments exist; shared pinned Print/Share footer |
| 35 | Purchase Invoices | Shared directory cards improved, device QA pending | Actual supplier, document/date/amount/status rendered; server-side search/status filtering, no mocked Paid/Unpaid badges; authorized Add Purchase |
| 36 | Create Purchase Invoice | API-verified compact UI, device QA pending | Two-column fields: supplier, server document number, invoice date, session warehouse, supplier reference, due date, payment terms, freight, other discount, notes; 4dp numeric validation; existing authorized draft/line/post |
| 37 | Purchase Invoice Detail | Draft/posted views distinguished; device QA pending | Draft remains editable, posted record shows real server invoice, status and items; resource-backed discount/freight/charges/tax/grand total; Print PDF and vendor-party View Ledger only as authorized |
| 38 | Sales Returns | Real server directory, device QA pending | Status filter only draft/posted per SaleReturnStatus enum, real customer/source/date/amount, no fictional Refunded status |
| 39 | Create Sales Return | API-verified compact UI, device QA pending | Read-only server return number, party derived from selected invoice, compact source/date/optional reason/notes, server-returnable items preview, persisted idempotency and real draft/line/post flow |
| 40 | Purchase Returns | Real server directory, device QA pending | Actual data only; draft/posted server filter and source/party display; genuine purchase return draft/line/post flow retained; empty view when backend has no records |
| 41 | Create Purchase Return | Functional existing draft/line/post, UI enhanced; Android QA pending | Original posted purchase required by this mobile path; real supplier/warehouse/date, Supplier Reference (supported), reason/notes, returnable quantities from server; no invented adjustment type or stock total |
| 42 | Purchase Return Detail | Real server detail and PDF, Android QA pending | Posted records read-only, actual returned-line Product/Qty/Rate/Amount table, server discount/tax/total, posted indicator and Print PDF; draft remains editable/postable by permission |
| 43 | Expense Vouchers | Reference-style paginated server list, Android QA pending | True `/api/sales/expenses` server q/date filters, real accounts/date/reference/amount and read-only detail sheet; no unsupported expense status/number |
| 44 | Record Expense | Compact horizontal UI redesign committed, Android QA pending | Shared inline row panel with true expense account, date, paid-from account, amount, reference, description; entered-amount-only preview; existing idempotency and immediate server posting retained. No screenshot-only payee/tax/draft |
| 45 | Journal Vouchers | Real journal-only server directory, Android QA pending | `/api/vouchers?type=journal`, draft/posted, server amounts/narration, authorized Add Journal, lock journal editor kind, refresh after exit; existing server draft/post flows reused |
| 46 | Create Journal Voucher | Compact horizontal UI redesign committed, Android QA pending | One grouped horizontal panel, real server voucher number/date/narration/book number, functional account-line editor and server total panel only after draft exists; no demo rows/balance badge |
| 47 | Payments | Real `type=payment` voucher list; Android QA pending | `GET /api/vouchers?type=payment`, server-side q/status/page, authentic draft/posted status, real voucher amount/date/narration; Add Payment route |
| 48 | Create Payment | Compact horizontal UI redesign committed, Android QA pending | Real Cash/Bank Account header, posted/draft voucher number/date/book/description, authentic chart-of-accounts amount lines, shared footer; no unsupported invoice summary, supplier field or payment mode |
| 49 | Receipts | Real `type=receiving` voucher list; Android QA pending | `GET /api/vouchers?type=receiving` using authorized actual voucher fields and Add Receipt |
| 50 | Create Receipt | Compact horizontal UI redesign committed, Android QA pending | Shared inline receiving voucher entry with genuine cash/bank header, date/book/description, account amount lines and server Draft/Post; no fake invoice/customer fields |
| 51–92 | Future references | Not implemented in this batch | Next screens 51–55. Verify visual reference and web APIs before modifying |

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

## Corrections after Android screenshot review — 2026-11-17

**Important distinction:** the supplied 33–40 mockups demonstrate visual hierarchy, **not the live BluePOS business contract**. The live `9o9ame/bluepos` `main` backend and React frontend have been inspected directly before these changes. No illustrative mockup product, total, date, status or customer was inserted.

- Web sources inspected: `PROJECT_UI_DESIGN_SYSTEM.md`; `backend/routes/api.php`; `backend/app/Http/Controllers/Api/Purchases/PurchaseInvoiceController.php` and `PurchaseReturnController.php`; `backend/app/Http/Controllers/Api/Sales/SaleReturnController.php` and `SaleController.php`; respective `Http/Resources/Purchases/*Resource.php` and `Http/Resources/Sales/*Resource.php`; enums `SaleReturnStatus`, `PurchaseReturnStatus`, `PurchaseInvoiceStatus`, `SaleStatus`; `frontend/src/pages/PurchasesPage.tsx`, `SalesReturnsPage.tsx`, `PurchaseReturnsPage.tsx`.
- Server status contracts: Sales/Purchase Returns = **draft/posted only**. Purchase Invoice = draft/posted/cancelled. Sale = posted/void. Removed mockup-derived `Refunded`/`Adjusted` dropdown statuses. Filtering now calls each backend endpoint with `status`, not client-side subset filtering.
- `lib/screens/modules.dart`: Sales Invoices action now opens shared server-backed `TransactionDirectory`, whose records open the **full** `ReceiptScreen` instead of a generic history-sheet. Dedicated Create Sales Invoice action still delegates to the existing frozen POS editor. No duplicate invoice posting engine.
- `lib/screens/transaction_widgets.dart`: shared reference cards now use real party, document, source invoice, date, status and server grand total; color keyed to the returned status. Search placeholder adapts to Sales, Purchases and Returns.
- `lib/widgets/reference_surface.dart`: new `BpReferenceCompactField` two-column input component plus semantic right-action color support in shared footer; form geometry centralized.
- `lib/screens/purchase_invoices.dart`: create/edit now use verified header fields and server-generated invoice number (read-only), active session warehouse, real optional supplier reference/due date/payment terms/freight/other discount/notes. Decimal inputs remain strings and are validated as nonnegative with max 4 places; backend recalculates all totals. Posted records use read-only header/status instead of showing editable draft form, with PurchaseInvoiceResource fields (including actual `discount_amount`, not nonexistent `total_discount_amount`). 37 Print and View Ledger actions remain real and permission-checked.
- `lib/screens/returns.dart`: 39 compact return number/party/source/date form is sourced from real SaleReturnResource/PurchaseReturnResource or chosen source record; no generated-code input. Shows **server returnable-line preview** before a draft exists; creating/adding/posting continues through existing authorized API actions, including persisted idempotency for sale return creation.
- `lib/screens/receipt.dart`: no generic bottom-sheet route; quantity/rate strings compacted for **display only**, no client-side financial arithmetic; server grand total and optional actual payment banner; shared Print/Share footer.
- `test/mobile_reference_33_40_web_contract_test.dart` added for 4dp/6dp validation, ULID-only boundaries, compact two-column layout and shared footer action color.
- **Not claimed:** Full pixel-perfect parity, Flutter compile/analyzer passing, server posting integration tests or approved Android comparison. These still require focused on-device QA and backend tests on `bluepos_test`. Do **not** run posting tests on persistent development DB.
- **No web backend/frontend changes, no database migrations, no Git branch switch**. All mobile commits are on `feature/daily-entries`.

### Final narrow-layout refinement

- **37 posted purchase details:** posted records now use an actual server-sourced Product/Qty/Rate/Amount table; draft line cards and edit controls remain draft-only. Shared `bpReferenceDecimalLabel` shortens decimal display text without modifying server amounts or write payloads.
- **34 sales details:** uses the same shared decimal label utility. Real sale payments appear only when `SaleResource.payments` contains records.
- **Shared UI:** `BpReferenceCompactField` drives dense invoice metadata; `BpReferenceWorkflowActions` now controls both Post (green) and authorized Ledger/Share (blue) without duplicating footer layouts.
- Added test coverage for shared decimal label rendering. Flutter SDK still unavailable in this execution environment; no analyzer/test pass is asserted.

## Flutter analyzer incident correction — 2026-11-17

Windows verification after `b3bf748` successfully fast-forwarded the mobile branch, but failed to compile `lib/screens/returns.dart:509–513` due to an ambiguous nested conditional with null-aware map reads. Both focused test suites failed **to load**, not because their assertions failed.

**Committed fix:** Return detail/customer-or-supplier name is resolved from already-converted `objectOf(document)` and `objectOf(source)` maps using one type-safe party key before rendering. Removed unused imports from affected files, migrated PDF `Table.fromTextArray` to `TableHelper.fromTextArray`, added braces around the logged guarded flows in Purchase/Return/Transaction widgets, and cleaned the shared display-label interpolation warning. No backend/schema/posting calculations changed.

**Validation:** Structural bracket/quote checks across five touched Dart files passed; **Flutter analyzer/tests have not been rerun in the assistant runtime**. The prior Windows run reported 38 diagnostics including compile errors; user must pull latest branch and rerun targeted checks. Their local `analysis_options.yaml` modification and untracked `.idea/`, `.metadata`, `android/`, `bluepos_app.iml`, `widget_test.generated.bak` were deliberately untouched. Never reset or delete them without explicit approval.

## Latest reference batch — Screens 41–45 (2026-11-18)

Sources compared: `BATCH_05_41-50/41_Purchase_Return_Entry.png` through
`45_Journal_Vouchers.png`; live `9o9ame/bluepos` `main`
`PROJECT_UI_DESIGN_SYSTEM.md`,
`backend/routes/api.php`,
`backend/app/Http/Controllers/Api/{Purchases/PurchaseReturnController,Sales/ExpenseController,Accounting/VoucherController}.php`,
`backend/app/Http/Requests/Sales/StoreExpenseRequest.php`,
`backend/app/Http/Resources/{Sales/ExpenseResource,Purchases/PurchaseReturnResource,Purchases/PurchaseReturnLineResource}.php`.
Visual images guide **appearance only**, not server field availability.

- **41–42 Purchase Return:** `lib/screens/returns.dart` still reuses real authorized purchase return source/draft/line/edit/post domain methods. Added supported `supplier_reference` to create/update and reload; read-only posted detail now has the actual server-sourced item table and `discount_amount`, `tax_amount`, `grand_total`. Posted Return Print exports a PDF exclusively from authorized server data. Never amend a posted return through a draft form. Purchase Return general mode exists on the web but was **not added** to this source-linked mobile flow.
- **43 Expense Vouchers:** `lib/screens/money_actions.dart` shows compact reference cards, paged `GET /api/sales/expenses`, server-side search `q`, date range `date_from/date_to` and read-only server detail sheet. **ExpenseResource has NO `status` or `document_number`**; the UI does not invent Draft/Paid/Approved states or voucher IDs. `Recorded` is an action description, not a fake resource field.
- **44 Record Expense:** same file uses shared `BpReferenceCompactField` and `BpReferenceWorkflowActions` with actual `StoreExpenseRequest` values: date, expense account ULID, payment account ULID, amount (positive decimal max 4), reference, description. Existing `MoneyActionAttemptStore`, persisted idempotency key and confirm-before-post flow preserved. **The expense create API posts directly and does not have draft or separate post endpoints**, so UI offers Cancel / Confirm Expense rather than fake Save Draft / Post Expense.
- **45 Journal Vouchers:** `lib/screens/vouchers.dart` adds a dedicated `JournalVoucherDirectoryScreen` with `/api/vouchers?type=journal`; `VoucherEditor(initialKind: journal, lockInitialKind: true)` retains server draft/lines/post and prevents selecting a payment/receiving type from Journal-only route. `lib/screens/transaction_widgets.dart` uses actual `description`/`book_number` instead of fake customer/supplier names; journal create CTA says Add Journal. `lib/screens/modules.dart` exposes new permission-gated Journal Vouchers action in Daily Entries.
- Shared `BpReference*` appearance, selected theme and compact sizing reused. No web, database, schema, accounting valuation or posting-domain changes.
- Added `test/mobile_reference_41_45_test.dart` with route/schema and compact-widget smoke assertions; **not executed**. Flutter/Dart SDK unavailable in this environment, and Android visual approval remains pending. Tests involving actual posting/concurrency must run against **`bluepos_test`**, never development DB.

## Latest progress — Screenshot review 41–45 and new screens 46–50 (2026-11-18)

**User intent:** Reference PNGs set the *visual presentation*; the authoritative real fields, permissions and posting behavior must come from `9o9ame/bluepos` web Laravel/API implementation, not from sample invoice/receipt mockups. The app has few/no actual purchase returns or journal records currently. Therefore screen 42 and 45 should show honest empty states rather than fabricated sample rows. The appearance of data-rich reference screenshots cannot be duplicated without live tenant data.

**41–45 follow-up:** `lib/screens/money_actions.dart` expense entry is now titled **Create Expense Voucher** to match reference, with compact form and a short confirmation warning instead of a long developer-facing API note. Do not add mockup payee, tax, payment mode, voucher number or Save Draft to this expense API: `StoreExpenseRequest` only supports `expense_date, expense_account_ulid, payment_account_ulid, amount, reference, description` and immediately posts. `lib/screens/transaction_widgets.dart` now has contextual empty states for Purchase Returns and Journal Vouchers rather than misleading generic results. Purchase Return still depends on a real posted purchase and server-returnable lines, not an illustrative inventory table.

**Verified web contract for 46–50:** `backend/routes/api.php`, `backend/app/Http/Controllers/Api/Accounting/VoucherController.php` and existing `ManageVoucherAction`. `GET /api/vouchers?type=journal|payment|receiving` accepts `q`, `status=draft|posted` and pagination. `POST /api/vouchers`, `PUT /api/vouchers/{ulid}`, `POST /api/vouchers/{ulid}/post` are the actual routes. Voucher request: `type`, `entry_date`, optional `book_number` and `description`, optional header cash/bank account ULID for payment/receiving, and account lines (amount for header types; debit/credit for journal). Server exposes `voucher_number, total_debit, total_credit, status, lines`. **There are no separate generic /api/payments or /api/receipts voucher CRUD routes**; invoice-specific payment endpoints are different workflows and were deliberately not substituted here.

**Implementation:**
- `lib/screens/vouchers.dart`: adds `CashVoucherDirectoryScreen` for **47 Payments** and **49 Receipts**, filters by true voucher type and links to authorized real `VoucherEditor`. Screens **46 Journal Entry**, **48 Payment Entry**, **50 Receipt Entry** now use a shared reference editor layout when `lockInitialKind` is enabled: compact date, server number, description, optional book reference, real account picker/lines, edit/remove lines and shared Create Draft/Post footer. `initialKind` and `lockInitialKind` prevent switching types in those routes. Safe original idempotency retry remains possible; server-side debit/credit totals are displayed only after a draft exists. No front-end ledger arithmetic or invented payable/receivable balances.
- `lib/screens/transaction_widgets.dart`: real voucher-card content, correct Add Payment/Add Receipt/Add Journal CTAs, truthful empty states. Shared search/status/filter and server paging remain.
- `lib/screens/modules.dart`: adds permission-gated **Payments** and **Receipts** navigation plus existing Journal entry in Daily Entries.
- `test/mobile_reference_46_50_test.dart`: adds focused type-mapping/decimal-string payload and shared narrow-footer tests. **Not executed**.
- `docs/MOBILE_NEXT_CHAT_HANDOFF.md`: updated current-first summary.

**Validation status:** GitHub file commits and static delimiter checks only; Flutter/Dart SDK absent in this execution environment. **Not yet confirmed:** `flutter analyze`, widget tests, on-device 360px layout, real tenant permissions, actual voucher post/retry and cross-tenant tests. Never run posting tests against persistent development DB; use `bluepos_test`. No backend changes or migrations. Frozen Sales Invoice layout untouched. Next batch **51–55** after checks.

## Android screenshot rejection and corrective UI pass — 2026-11-18

**User supplied side-by-side screenshots for 44 / 46 / 48 / 50 and explicitly rejected the old visual quality.** Previous mobile implementation showed separate tall stacked cards; reference uses compact single-card horizontal rows, colored icon chips, right-aligned controls, dense voucher-account lines and focused total panels. That mismatch was real and is not considered approved.

**Committed targeted changes:**
- `lib/widgets/reference_surface.dart`: new reusable `BpReferenceInlineRow` and `BpReferenceInlinePanel` with shared height, icon treatment, labels, inset control slot and row separators; theme-aware surfaces. Changes are additive, not global replacements.
- `lib/screens/vouchers.dart`: replaces prior bloated `referenceEditor` for 46/48/50 with grouped compact icon/label/control rows, optional Cash/Bank selector for Payment/Receiving, dense account lines with real account/code and line amounts, plus server-debit/credit totals only when a real document exists. Keeps `chooseDate`, `chooseHeader`, `addLine`, `save`, `post`, `refresh`, draft deletion, RBAC and persisted idempotent attempts intact. Voucher number is read-only and server-generated.
- `lib/screens/money_actions.dart`: 44 Expense entry now uses the same shared inline panel, functional existing account/date selectors, editable amount/reference/description and a clearly **input-only** amount preview (not tax arithmetic or an invented computed total). Direct server-post confirmation unchanged.
- `test/mobile_reference_46_50_test.dart`: added a narrow 360px layout/picker interaction smoke test for shared inline panels. The existing voucher-kind/decimal/footer tests remain.
- **No backend, schema, migration, account-balance computation or posted-record updates.** Reference image sample vouchers, accounts, invoices and amounts were not inserted.
- **Pending:** Flutter `analyze`, focused widget tests, a fresh Android build/screenshot and side-by-side visual acceptance at 360–390dp. This pass is a real committed code change, **not** proof of pixel-perfect match. Next priority is to fix any new analyzer error before screens 51–55.

**Design/API boundary:** The provided 48/50 mockups depict invoice-specific settlement (payee, purchase/sales invoice, balance, payment mode) but the implemented menu actions are generic manual `/api/vouchers` Payment/Receiving types, which **do not have those request fields**. Keep them absent until a dedicated invoice-payment flow is explicitly scoped and verified. The web `PROJECT_UI_DESIGN_SYSTEM.md` confirms voucher colors and the single shared-component principle; the mobile repository has separate Flutter widgets.

### Additional layout corrections in the same 44/46/48/50 pass

- The journal/payment/receipt reference editor now has a **clickable empty account-line row**. It opens the existing real `addLine` picker; no placeholder account or transaction is fabricated.
- Shared `BpReferenceSubpageAppBar(titleBelowBack: true)` adds the reference's **logo → back → left-aligned heading** hierarchy for Expense and voucher editors, plus the 45/47/49 voucher directories. Its default remains unchanged to protect approved/frozen pages.
- `lib/screens/transaction_widgets.dart` voucher list cards use backend-independent voucher identity tones (Journal indigo, Payment red, Receiving green), with the actual voucher date under the real narration/description. Status badges still reflect only server status.
- `test/mobile_reference_46_50_test.dart` includes a header opt-in regression check alongside the responsive grouped-panel test.
- **The user has not yet provided updated Android output after these commits.** Prior rough screenshots are evidence of the old design; they do not verify this new code. Any visual acceptance claim is pending.

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
flutter analyze lib/screens/vouchers.dart lib/screens/money_actions.dart lib/screens/modules.dart lib/screens/transaction_widgets.dart lib/screens/returns.dart lib/widgets/reference_surface.dart
flutter test test/mobile_reference_46_50_test.dart test/mobile_reference_41_45_test.dart
flutter run
```

If the pull fails due to DNS/network, the Android app still runs **old local code**. Don't claim the latest UI is installed until `git log -1 --oneline` confirms the new branch commit.

## Important source-of-truth note

The mobile GitHub repository does **not** contain `PROJECT_UI_DESIGN_SYSTEM.md` at its root as of this update. The uploaded BluePOS web master/current-state files describe the separate web project, so do not silently replace the mobile reference images or mobile source with web assumptions. Preserve the frozen Sales Invoice UI.

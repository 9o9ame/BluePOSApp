# BluePOS Mobile — Complete Application Implementation Plan

> Status: **APPROVED SCOPE / IMPLEMENTATION IN PROGRESS**  
> Last reviewed: 2026-11-05  
> Repository: `9o9ame/BluePOSApp`; development branch: `feature/daily-entries`  
> Reference (read-only): `9o9ame/bluepos` — `PROJECT_UI_DESIGN_SYSTEM.md`, `BLUEPOS_MASTER_CONTEXT.md`, `BLUEPOS_CURRENT_STATE.md`, actual frontend routes/module registry, and actual backend contracts.  
> User instruction: **Do not build or publish an APK until explicitly authorized.** Commits for this effort should skip CI APK builds. Do not modify the web repository.

## 0. Source of truth and acceptance rules

- Approved mockup: professional BluePOS blue/white POS & ERP showcase (login, Home, POS, Products, Reports, Settings). Mobile layout must match its visual hierarchy, polish and density while respecting web appearance tokens. User screenshots of the installed 0.2.1 release demonstrate current visual and camera defects; they are **not** the new design baseline.
- Preserve existing **web** frozen layouts; create mobile-native responsive equivalents without modifying web code.
- Every visible feature must have a real, permission-checked action; no decorative/inert buttons, fabricated business metrics, fake API responses, or placeholder success.
- Never infer backend endpoints from the fact that a web page exists. Confirm actual routes/requests/payloads/responses, tenancy, entitlement and RBAC before writing workflows.
- Public API identifiers: ULIDs only. Backend exclusively determines tenant, branch, warehouse and financial state. Server recalculates price, discount, tax, stock, accounting and payment totals. Precise decimal quantities and money only.
- Posted records immutable; stock movements append-only. Server posting, idempotency, duplicates, retries and failure recovery are mandatory for financial mutations.
- Design states for every screen: initial loading, pagination/loading more, populated, empty, denied, offline, error, success, refresh. Light/Dark/System, all six primary palettes, density, radius, shadow, font/animation preferences. Prefer reduced motion if configured.
- Mark each item `[x]` **only after** mobile implementation and relevant verification. A web-ready page or mockup does not make a mobile feature complete.
- Test device: Redmi Note 10 (Android 12, MIUI 14.0.9), especially camera/biometrics and keyboard overflow. No APK builds until requested; tests may include focused static/test checks only if explicitly permitted by environment and user instructions.

## 1. Startup and login — highest priority

- [ ] **01.01 Animated splash:** approved BluePOS "Run Your Business Anywhere" brand artwork with POS terminal/barcode scanner, 4 feature callouts, blue/white gradient; respectful short reveal/motion. Auth restore occurs concurrently. No false loading promises or artificial blocking; after init route correctly. Support reduced-motion.
- [ ] **01.02 Circular sign-in:** `BLUEPOS` then `POS & ERP` (remove "Mobile"). Preserve circular/neumorphic web-inspired card, center and balance logo, "Welcome Back", Tenant/Mart Code, Username, Password, Remember Me, Login. **Remove "Sign in to your secure workspace" under Welcome Back.** All three fields same height/width; responsive for keyboard, safe area, short screens, small displays. Preserve MFA challenge form.
- [ ] **01.03 Biometric button:** separated noticeably from circle; remove both text lines under it. Always tappable (except during actual in-flight auth); if not enrolled, show concise English: **"Sign in first to enable biometrics."** If enrolled with valid session, Android BiometricPrompt; if cancelled leave login open; manual re-tap retries. No automatic enrollment, biometric template storage, or MFA/device bypass.
- [ ] **01.04 Automatic biometric:** splash → visible login → one automatic OS biometric prompt per launch if app opted in, device enrolled and a previously approved valid server session is recoverable. On cancel keep login screen, do not reprompt in a loop. On success re-check `/api/auth/me`, same user, branch and security context before entering; on expired/revoked session require credentials.
- [ ] **01.05 Netflix-style remembered accounts:** after successful authorized login, store safe per-user display metadata (mart code, username, display name/initials, last used). Focus/tap on Tenant or Username shows selectable account history; selecting fills safe fields. Provide remove account and cross-tenant isolation. **Never store plaintext passwords or secret recovery tokens.** Password autofill delegated to Android credential manager/Autofill. If server session not valid, credentials are required; fingerprints cannot invent new sessions.
- [ ] **01.06 Authentication states:** forgot/reset password when supported, change password, MFA resend/verify, device approval pending/rejected, explicit no-internet, 401/403, lock, sign-out, branch/session change. Show safe, short messages.
- [ ] **01.07 Login tests:** small Redmi-style viewport, narrow/landscape, keyboard, history without passwords, UI order, disabled/working biometric, first session, cancelled automatic prompt, revoked session, MFA and device approval.

## 2. Shared UI foundation / navigation

- [ ] **02.01 Theme system:** preserve server appearance contract: Light/Dark/System; Indigo/Blue/Emerald/Teal/Purple/Slate; Classic/Hybrid/Advanced; compact/comfortable, radius, shadow, font, animations.
- [ ] **02.02 Components:** consistent cards, input fields, searchable dropdowns, date/date-range picker, buttons, badges, tables/list rows, dialogs/bottom sheets, notices, skeleton/error/empty states, responsive layouts. No independent hardcoded page color system.
- [ ] **02.03 Bottom tabs:** Home / POS / Products / Reports / Modules; selected state, consistent header, icons, short labels, no navigation data loss.
- [ ] **02.04 Module directory:** Definition / Daily Entries / Reports / Tools / Administration / Help, dynamically permission/entitlement-filtered; unauthorized navigation blocked again by backend.
- [ ] **02.05 System:** secure branching, warehouse context, connection state, pull-to-refresh, search/filter/pagination, tablet/landscape responsiveness, meaningful feedback; premium loader and no fabricated analytics.
- [ ] **02.06 Custom BluePOS icon:** consistent launcher/adaptive icons, splash, top bars and receipts.

## 3. Dashboard / Home

- [ ] **03.01** Personalized greeting; real tenant/branch/warehouse and authorized account summary.
- [ ] **03.02** Today's sales, invoice count, paid/due, products and stock KPIs from genuine supported summary endpoints.
- [ ] **03.03** Actual daily/weekly/monthly charts and period controls; do not synthesize statistics from a partial page.
- [ ] **03.04** Quick New Sale, Purchases, Products, Stock, Customers, Reports action grid.
- [ ] **03.05** Recent transactions and notification/read state based on backend.
- [ ] **03.06** Authorized branch switching with explicit draft/pending-post warnings.
- [ ] **03.07** Polished blue/white mockup geometry; no oversized single banner or empty wasted space.

## 4. Sales & POS — Daily Entries

- [ ] **04.01–04.04** New Sale; Default/Retail/Wholesale; customer picker (walk-in allowed); product picker/name/SKU/barcode/category/stock.
- [ ] **04.05 Scanner:** camera permission, Android 12 real device, torch/supported camera switch, clear overlay, readable scanner status, manual barcode fallback, duplicate detection and barcode → product+unit mapping. **Release blocker:** current `mobile_scanner` displays "An unexpected error occurred" on Redmi Note 10. Capture camera exception, show recovery, and verify physical scan.
- [ ] **04.06–04.09** Cart line editing (quantities, units, price, discount, tax), schemes where backend supports them, server-authoritative totals, stock warnings.
- [ ] **04.10–04.13** Payments cash/card/bank/credit as authorized; server-sourced receiving bank account; review/confirm/post with idempotency and safe retries; success with server invoice ULID/number; PDF/Android print/share.
- [ ] **04.14–04.18** Sales history, invoice details, recoverable hold/draft if supported, quotations/estimates, sales returns, product-wise sales.
- [ ] **04.19** Focused financial/security tests for permissions, cross-tenant access, recomputed totals, precision, race/duplicate, rollback, pending-post recovery.

## 5. Purchases — Daily Entries

- [ ] **05.01–05.05** Purchase overview, invoice entry with supplier/product/warehouse and accurate tax/payment, review, authorized posting, history and detail.
- [ ] **05.06** Purchase Orders create/view/edit/approval where supported.
- [ ] **05.07** Purchase Returns against server documents with proper quantities, permissions, validation.
- [ ] **05.08** Purchase preview/print/PDF. Preserve *web* Purchase Invoice frozen geometry.
- **Current mobile status:** read-only purchases; verify actual backend write contracts before implementation.

## 6. Products / Definition

- [ ] **06.01–06.07** Professional mockup product list with real image, SKU, category chips, price/stock; detail; authorized create/edit; safe image upload; barcode+unit mapping; tabular product view.
- [ ] **06.08–06.14** Categories, subcategories, brands, units, price lists, sale schemes, barcode label/print workflows.
- [ ] **06.15** Product warehouse stock lookup with server context, precise quantity conversion.

## 7. Customers, vendors and accounts

- [ ] **07.01–07.06** Searchable customer/supplier lists, profiles, authorized create/edit; safe form data.
- [ ] **07.07–07.09** Customer/supplier ledger, outstanding receivables/payables, server authoritative.
- [ ] **07.10–07.12** Chart of Accounts/leaf accounts, account detail, guarded bulk import/export if actually available.
- **Source conflict to resolve:** web module registry lists `/definition/parties` as `shell`, while historical project context describes Parties as implemented/frozen. Inspect backend/routes before promising mobile write capabilities.

## 8. Inventory / Stock

- [ ] **08.01–08.04** Warehouse dashboard, product stock, SKU/barcode search, stock detail.
- [ ] **08.05–08.08** Opening stock, stock taking, adjustments, append-only movements and history when API routes support them.
- [ ] **08.09–08.10** Stock status and product ledger reports.
- No fictional batch/expiry quantities or duplicate inventory flow.

## 9. Accounting / Payments / Vouchers

- [ ] **09.01–09.06** Ledger overview and voucher workflows: Opening (amber), Payment (red), Receiving (green), Journal (indigo); history, server validation/posting.
- [ ] **09.07–09.10** Account ledger, daily cash, authorized bank accounts, supported expenses.
- Journal must balance; posted documents immutable; no client-computed balances or duplicated accounting service.

## 10. Reports & Insights

- [ ] **10.01–10.04** Reports dashboard, sales summary, product-wise sales, outstanding invoices.
- [ ] **10.05–10.10** Trial Balance (including six-column variants), Balance Sheet, Income Statement (daily/monthly/yearly), General Journal, Cash Book.
- [ ] **10.11–10.15** Daily Business Activity, Total Turnover, Top Products/Vendors/Customers, Stock Status, Product Ledger.
- [ ] **10.16–10.17** Report preview/search/zoom/refresh and supported Print/PDF/CSV, native date-range/account/product/branch filters.
- Web registry marks FBR registers, Dead Stock, Expiry, advanced P/L, detailed transactions and several party reports as **later**. Do not show unsupported reports as live; only add after contract is verified.

## 11. Tools

- [ ] **11.01–11.08** Tool directory, calculator, report headings, permission-restricted custom query, software options, guarded stock recalculation, lock, access-management shortcuts. High-risk admin actions require explicit confirmation and server permissions.

## 12. Administration

- [ ] **12.01–12.10** Administration directory, business settings, branches, warehouses, users, role editor, device approvals, session security, plan/entitlements and supported audit events.
- Platform super admin is a *separate* authorized workspace, not merged with tenant admin.

## 13. Settings / Profile

- [ ] **13.01–13.12** Account/profile, complete appearance options, interface preferences, biometric enrollment/disable, remembered accounts, lock/session, password change, authorized branch/warehouse display, app diagnostics/version, secure signout.
- Biometric capability and enrollment status must be explicit; don't claim Face ID is available unless Android reports compatible hardware.

## 14. Help and common screens

- [ ] **14.01–14.10** Help/About, notifications, unified search, offline, unauthorized, session expired, empty, skeletons, recoverable errors, print/share.
- Accessibility: tap targets, screen reader labels, keyboard safe areas, contrast and reduced motion.

## 15. Security, data and quality contract

- [ ] Per-request authorization/RBAC and tenant/branch/warehouse isolation.
- [ ] Never expose BIGINT IDs, passwords, biometric templates, unprotected session cookies or PII in logs.
- [ ] API response validation and explicit unsupported endpoint behavior.
- [ ] NUMERIC (20,4) money, (20,6) quantity, (12,8) factors/percentages; decimal-safe rendering.
- [ ] Financial idempotency, retries, server totals, append-only stock and posted immutability.
- [ ] Safe permission gating, camera permission fallback, session expiry, crash-safe draft preservation.
- [ ] Focused tests for all security-sensitive, posted/financial and app-auth flows; no production financial test writes.

## 16. Execution order and progress

1. **Phase A:** Shared UX, splash and full login (including biometrics and saved account list), focused tests.
2. **Phase B:** Navigation, Home, Products and scanner defect (physical Redmi testing).
3. **Phase C:** POS, payments, history, receipts, quotation, sales returns with live server-contract verification.
4. **Phase D:** Definition, purchases, parties and inventory (supported CRUD/posting only).
5. **Phase E:** Accounting, all supported reports, real exports.
6. **Phase F:** Tools, Administration, Settings and Help; completeness audit.
7. **Phase G:** Focused integration/security tests and visual QA. Configure stable release signing before any production distribution. **Do not build/publish an APK without user's separate permission.**

### Definition of done for each screen

- [ ] Matches approved responsive mockup and design system.
- [ ] Every displayed action performs a correct authorized backend/local workflow.
- [ ] No made-up values, fake permissions, or silent failures.
- [ ] Loading, empty, validation, error, offline and permission states work.
- [ ] Back navigation and safe session/draft persistence work.
- [ ] Relevant focused tests pass; real-device behaviors verified when applicable.
- [ ] Status and unverified API dependencies documented accurately.

## 17. Current baseline / known defects

- Existing mobile `0.2.1` is a partial preview: login, read-only entity data, sales cart, simple reports, appearance; **not** full ERP CRUD/posting.
- On Redmi Note 10: installed using ADB, but barcode scanner shows "An unexpected error occurred"; layouts differ significantly from approved mockup.
- Existing mobile login has overly dense circle, extra subtitle/security lines and visually disabled biometric entry. Android biometric code is present but user-requested disabled-state messaging/history/auto-prompt UX is not complete.
- Existing web `PROJECT_UI_DESIGN_SYSTEM.md` governs color/shape/motion. Do not change frozen web Sales Invoice Amounts geometry.
- No app build, release, keystore rotation, backend/database migration, or web-repo modification as part of this approval.

## 18. Implementation journal

| Date | Work | Validation | Status |
|---|---|---|---|
| 2026-11-05 | This plan recorded from approved user requirements and read-only source inspection | Source inspection | Done |


### Implementation progress checkpoint — 2026-11-05 (no APK)

- Source implementation on the existing module branch includes BluePOS splash, refined circular sign-in, remembered account picker, opt-in biometrics, camera error/retry/manual barcode entry, shared mobile navigation and permissioned modules. Final visual/device acceptance remains pending.
- Catalog master editors (category/subcategory/brand/unit), party directory/editors, improved dashboard, server-authoritative Stock Status and Trial Balance and Product Ledger reports have been introduced. Their completion checkboxes remain open until contract/integration/device testing.
- Trial Balance row syntax was corrected after a failing analyzer CI; subsequent analyzer-only run succeeded.
- The biometric unenrolled guidance is the concise English **"Sign in first to enable biometrics."**
- **Cash Book** screen added using verified `GET /api/reports/accounting/cash-book` and `GET /api/reports/accounting/cash-book/accounts` contracts. It exposes an account filter, bank toggle, date range and server-authoritative opening, received, paid and closing totals. Permissions are required and the backend rechecks tenant/branch. Its UI and request integration need focused validation.
- APK compilation and release publishing remain prohibited; `.github/workflows/android-apk.yml` is manual-only. `mobile-checks.yml` performs analysis and tests without compiling an APK.

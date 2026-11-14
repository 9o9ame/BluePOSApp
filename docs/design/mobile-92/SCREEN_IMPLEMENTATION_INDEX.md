# BluePOS Mobile — numbered design-to-implementation index

Working branch: `feature/daily-entries`. Design-only indexing: **not** an implementation checklist. Current source is Flutter/Dart; verify actual mobile and Laravel API contracts and `PROJECT_UI_DESIGN_SYSTEM.md` before UI changes.

**Status:** 92 numbered design references, **89 unique**. The actual PNG files and SHA256 CSV are **not yet in GitHub**, only in the local 125 MB ZIP `BluePOS_Mobile_92_Screen_Reference_Pack.zip`. Screen **79 repeats 63; 91 repeats 09; 92 repeats 08**. Do not mark the three as approved. Proposals do not authorize new backend features.

## Exact sequence (the ZIP filenames have a zero-padded prefix)

| ID | Screen | Phase/module | Design status |
|---:|---|---|---|
| 01 | Splash | Startup | Reference — functional contract to verify |
| 02 | Login | Startup | Reference — functional contract to verify |
| 03 | Connect Business | Startup | **NOT REQUIRED** — tenant/mart code is entered in the existing Login; no separate tenant-selection route to implement |
| 04 | Account Verification | Startup | Reference — functional contract to verify |
| 05 | Password Recovery | Startup | Reference — functional contract to verify |
| 06 | Dashboard | Navigation | Reference — functional contract to verify |
| 07 | POS Sales | Navigation | Premium reference PNG actually depicts POS Sales, not a second Home Dashboard |
| 08 | Main Menu | Navigation | Reference — functional contract to verify |
| 09 | More Menu | Navigation | Reference — functional contract to verify |
| 10 | Notifications | Navigation | Reference — functional contract to verify |
| 11 | Definition Home | Definition | Reference — functional contract to verify |
| 12 | Products Catalog | Definition | Reference — functional contract to verify |
| 13 | Product Details | Definition | Reference — functional contract to verify |
| 14 | Categories | Definition | Reference — functional contract to verify |
| 15 | Add Category | Definition | Reference — functional contract to verify |
| 16 | Subcategories | Definition | Reference — functional contract to verify |
| 17 | Add Subcategory | Definition | Reference — functional contract to verify |
| 18 | Brands | Definition | Reference — functional contract to verify |
| 19 | Add Brand | Definition | Reference — functional contract to verify |
| 20 | Units | Definition | Reference — functional contract to verify |
| 21 | Add Unit | Definition | Reference — functional contract to verify |
| 22 | Price Lists | Definition | Reference — functional contract to verify |
| 23 | Add Price List | Definition | Reference — functional contract to verify |
| 24 | Sale Schemes | Definition | Reference — functional contract to verify |
| 25 | Add Sale Scheme | Definition | Reference — functional contract to verify |
| 26 | Customers | Definition | Reference — functional contract to verify |
| 27 | Add Customer | Definition | Reference — functional contract to verify |
| 28 | Customer Details | Definition | Reference — functional contract to verify |
| 29 | Suppliers | Definition | Reference — functional contract to verify |
| 30 | Supplier Details | Definition | Reference — functional contract to verify |
| 31 | Supplier Form | Definition | Reference — functional contract to verify |
| 32 | Daily Entries Home | Daily Entries | Reference — functional contract to verify |
| 33 | Sales Invoice | Daily Entries | Reference — functional contract to verify |
| 34 | Sales Invoice Details | Daily Entries | Reference — functional contract to verify |
| 35 | Purchase Invoice | Daily Entries | Reference — functional contract to verify |
| 36 | Purchase Invoice Entry | Daily Entries | Reference — functional contract to verify |
| 37 | Purchase Invoice Details | Daily Entries | Reference — functional contract to verify |
| 38 | Sales Returns | Daily Entries | Reference — functional contract to verify |
| 39 | Sales Return Entry | Daily Entries | Reference — functional contract to verify |
| 40 | Purchase Returns | Daily Entries | Reference — functional contract to verify |
| 41 | Purchase Return Entry | Daily Entries | Reference — functional contract to verify |
| 42 | Purchase Return Details | Daily Entries | Reference — functional contract to verify |
| 43 | Expense Vouchers | Daily Entries | Reference — functional contract to verify |
| 44 | Expense Voucher Entry | Daily Entries | Reference — functional contract to verify |
| 45 | Journal Vouchers | Daily Entries | Reference — functional contract to verify |
| 46 | Journal Voucher Entry | Daily Entries | Reference — functional contract to verify |
| 47 | Payments | Daily Entries | Reference — functional contract to verify |
| 48 | Make Payment | Daily Entries | Reference — functional contract to verify |
| 49 | Receipts | Daily Entries | Reference — functional contract to verify |
| 50 | Create Receipt | Daily Entries | Reference — functional contract to verify |
| 51 | Delivery Challans | Daily Entries | Proposed — verify API and approval |
| 52 | Delivery Challan Form | Daily Entries | Proposed — verify API and approval |
| 53 | Delivery Challan Details | Daily Entries | Proposed — verify API and approval |
| 54 | Opening Stock | Inventory | Reference — functional contract to verify |
| 55 | Opening Stock Entry | Inventory | Reference — functional contract to verify |
| 56 | Stock Taking | Inventory | Reference — functional contract to verify |
| 57 | Stock Taking Detail | Inventory | Reference — functional contract to verify |
| 58 | Stock Transfers | Inventory | Reference — functional contract to verify |
| 59 | Stock Transfer Entry | Inventory | Reference — functional contract to verify |
| 60 | Stock Transfer Detail | Inventory | Reference — functional contract to verify |
| 61 | Reports Home | Reports | Reference — functional contract to verify |
| 62 | Sales Reports | Reports | Reference — functional contract to verify |
| 63 | Sales Summary | Reports | Reference — functional contract to verify |
| 64 | Customer Reports | Reports | Reference — functional contract to verify |
| 65 | Customer Sales | Reports | Reference — functional contract to verify |
| 66 | Supplier Reports | Reports | Reference — functional contract to verify |
| 67 | Inventory Reports | Reports | Reference — functional contract to verify |
| 68 | Stock Valuation | Reports | Reference — functional contract to verify |
| 69 | Account Statement | Reports | Reference — functional contract to verify |
| 70 | General Ledger | Reports | Reference — functional contract to verify |
| 71 | Financial Reports | Reports | Reference — functional contract to verify |
| 72 | Profit and Loss | Reports | Reference — functional contract to verify |
| 73 | Trial Balance | Reports | Reference — functional contract to verify |
| 74 | Balance Sheet | Reports | Reference — functional contract to verify |
| 75 | Receivables Aging | Reports | Reference — functional contract to verify |
| 76 | Payables Aging | Reports | Reference — functional contract to verify |
| 77 | Cash Flow | Reports | Reference — functional contract to verify |
| 78 | Account Ledger | Reports | Reference — functional contract to verify |
| 79 | Sales Summary Variant | Reports | PROVISIONAL — duplicate image |
| 80 | Inventory Valuation | Reports | Reference — functional contract to verify |
| 81 | Tools and Utilities | Tools | Reference — functional contract to verify |
| 82 | Data Import | Tools | Proposed — verify API and approval |
| 83 | Data Export | Tools | Proposed — verify API and approval |
| 84 | Backup and Sync | Tools | Proposed — verify API and approval |
| 85 | Barcode Printing | Tools | Reference — functional contract to verify |
| 86 | Users | Administration | Reference — functional contract to verify |
| 87 | Roles and Permissions | Administration | Reference — functional contract to verify |
| 88 | Branches | Administration | Reference — functional contract to verify |
| 89 | Warehouses | Administration | Reference — functional contract to verify |
| 90 | Device and Security | Administration | Reference — functional contract to verify |
| 91 | Settings / Profile Reference | Administration | PROVISIONAL — duplicate image |
| 92 | Administration Overview Reference | Administration | PROVISIONAL — duplicate image |

## Phase 1 acceptance checklist (next actual UI implementation batch)

- [ ] Verify existing Flutter navigation and first 10 actual screens; no invented mockup features or fake numbers.
- [ ] Ensure mobile visual language is clean light / neutral with restrained BluePOS blue, semantic green/amber/red, shared theming and accessible control states.
- [ ] Preserve login biometric, MFA and server session security: no bypass, no device approval workaround.
- [ ] Resolve proposed center scan button versus existing Home / POS / Products / Reports / Modules navigation by explicit design review before changes.
- [ ] Check product, sales, reports permissions and real entitlement server contracts before enabling controls.
- [ ] Build focused responsive widget tests for targeted screens, verify analyzer and physical Android camera/biometric when touched.
- [ ] No APK publishing, no backend DB commands, no new branches or changes to frozen web geometry.

## Source and handoff

See `docs/MOBILE_92_MOCKUP_IMPLEMENTATION_HANDOFF.md` and `docs/BLUEPOS_MOBILE_COMPLETE_APP_PLAN.md`. Once PNGs are uploaded under `docs/design/mobile-92/screens/`, verify all hashes with `tool/verify_mobile_mockups.py`; use `--require-unique` only once 79, 91, 92 are replaced and approved.

## 2026-11-14 user-approved implementation scope correction

- **Pre-login is frozen for this work:** Splash, Login, Tenant/Mart Code login field, OTP/MFA verification, Password Recovery and related already-approved authentication screens are implemented and visually accepted by user. **Do not redesign, reorder or recreate them.** Only fix a verified security defect if explicitly requested.
- There is **no standalone tenant-selection or Connect Business screen** to build. The existing login accepts Tenant/Mart Code. Design slot 03 remains an archival reference only and is excluded from development scope; this does not change sequential image numbering.
- Begin implementation with **post-login Home/Dashboard (design 06)**, then actual POS (design 07) and subsequent post-login flows. First check the actual image, not only the filename/index: design 07 is a POS catalog.
- Approved mockup's Today’s Sales rupee amount, percentages, collections and expense totals are **illustrative**, not API-backed data. Implement only real permitted server metrics; do not fabricate a revenue chart or pretend invoice count equals sales amount.
- Keep existing login/auth/session implementation untouched. Mobile visual polish must follow the authoritative web `PROJECT_UI_DESIGN_SYSTEM.md` and Flutter theme preferences.

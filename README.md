# BluePOS Mobile — Android 0.2.0 preview

Independent Flutter app in `9o9ame/BluePOSApp`, connecting to existing live BluePOS APIs. This repository does not modify `9o9ame/bluepos`, its frontend, backend, database or policies.

## Product experience

- Custom BluePOS launcher icon and responsive blue / white premium layout.
- Circular embossed login inspired by the approved BluePOS web sign-in visual.
- Tenant/Mart Code + Username + Password, mandatory location when server requires it, owner MFA, staff device/network approval, expiry / revocation responses.
- Optional **real Android fingerprint or face unlock** via `local_auth` and Android `BiometricPrompt` (only if enrolled and available). Opt in from Settings after a successful authorized login. On app return and restored sessions a biometric check protects access. Server session is rechecked before showing data; biometric login cannot bypass MFA/device approval or create a new session. Android decides whether fingerprint/face works, not the app.
- Dashboard, server-backed Products with authenticated images/categories/barcode search, live Inventory Stock, Sales Cart, separate Payment page, Sales History, Purchase History, Customers, Suppliers, Expenses, Product-wise Sales, Outstanding Invoices, read-only Reports with date range and clear sample limits, profile Settings, and PDF receipt print/share.
- BluePOS server appearance profile: Light/Dark/System, Blue/Indigo/Emerald/Teal/Purple/Slate, Classic/Hybrid/Advanced, density, radius, shadow, font preference and animations.
- Cart amounts are explicitly estimates only; server controls real tax, discounts, valuation, credits, payments, tenant and warehouse context. No fake financial metrics, no batch/expiry claims.
- Pending POST /api/sales attempt + stable idempotency key are encrypted and recoverable after interruption. Never blindly generate a second sale when status is uncertain.

## Server/API

Fixed HTTPS origin: `https://bluepos.bluemarketing.com.pk`.

Browser-compatible Sanctum CSRF session with secure cookie storage. Only server-issued ULIDs are used in public API requests. Device and network approval remain backend-enforced. This app **does not** store passwords, biometric templates or facial images.

Payment methods supported by API: cash, card, bank. For card/bank, the receiving account is selected from the authorized `/api/sales/payment-accounts` response. `payment_due` requires a customer. Price, discount, quantity and tax are validated by backend.

**Warning:** The base API is live; posting an invoice can change stock, accounting and cash. Perform first testing only with an authorized test tenant and test products. There is no offline posting, local ledger or shadow inventory system.

## Developer workflow

All mobile work is on the allowed `feature/daily-entries` branch. Do not edit the BluePOS web repository.

```bash
flutter pub get
flutter create --platforms=android --org pk.com.bluemarketing --project-name bluepos_app .
python3 tool/patch_android.py
dart run flutter_launcher_icons
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

GitHub Actions runs those checks on push and uploads the Android APK artifact. A direct-download GitHub prerelease is published only when the commit message contains `[publish-apk]`. The optimized APK is smaller than the previous debug preview.

## Important security and distribution limitations

- The generated preview APK uses Flutter's generated/default Android debug signing for its *optimized release-mode* build. It is **not a production-signed Play Store release**. For stable future in-place upgrades, configure a private signing keystore securely in GitHub Actions. Never commit signing keys.
- Installing over the previous preview may fail if signing identities differ. Back up authorized data, uninstall old app if necessary, then install the new package. A different signing key is expected in ephemeral CI.
- Fingerprint/face behavior requires testing on the target phone with biometrics enrolled. Devices lacking qualifying facial biometric hardware may offer only fingerprint; that's an Android hardware/platform restriction.
- Reports only summarize the fetched API page; they do not pretend to be a complete accounting income statement.
- Purchase, customer, supplier and accounting screens currently expose server-authorized **read-only** records; full create/edit/posting flows for those domains are not implemented here. No feature should be claimed implemented merely because an icon or module tile exists.
- PDF printing uses the Android system print/share sheet, not proprietary Bluetooth/thermal printer commands.
- Physical-device biometric, camera, printer and production-server integration testing is still necessary before commercial release.

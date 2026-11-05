# BluePOS Mobile — Android preview 0.1.0

A separate **Flutter** mobile client for BluePOS. This repository is independent of
`9o9ame/bluepos`; no web/backend file is written or altered by this project.

## API

The client uses **only** `https://bluepos.bluemarketing.com.pk`, HTTPS and
existing Laravel endpoints. Authentication uses Sanctum CSRF/session cookies,
Tenant/Mart Code, username, password, precise sign-in location with explicit
permission, owner MFA, and existing device/network approval. No tenant, branch
or warehouse identifier is trusted from an unauthenticated input.

## Included screens

- Circular login design aligned to the web AuthLayout direction (mobile adaptation)
- MFA, device-approval messaging and forced password change
- Home dashboard with **real API** invoice/product counts (no invented numbers)
- Products with search and active-warehouse stock preview
- New sale with barcode scanning, quantity/discount, price mode, customer, due/cash/card/bank payment
- Idempotent sale POST, safe retries and server-returned invoice confirmation
- Sales history, products, warehouse inventory, purchases, customers and suppliers (read-only listings)
- Reports using real fetched sales, clearly labeled as recent-page figures
- Theme & Appearance linked to `/api/auth/appearance`: System/Light/Dark,
  Indigo/Blue/Emerald/Teal/Purple/Slate, Classic/Hybrid/Advanced, density,
  radius, shadow, font and animations
- Secure credential storage and sign out

**Preview limitations:** A usable first build, not a claim that every web ERP
module has full mobile CRUD or printing parity. Sales tax, schemes, stock,
accounting, server roles and final totals are validated on the backend. Product
price and tax previews in the mobile UI are explicitly illustrative only. There
is no fake batch/expiry allocation or offline posting; the client requires a
network connection for business operations. Device approval/location/MFA may be
required by the existing backend, so a valid approved BluePOS account is needed.

## Build locally

Flutter stable and an Android SDK are required:

```bash
flutter create --platforms=android --org pk.com.bluemarketing --project-name bluepos_app .
python3 tool/patch_android.py
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

## Download from GitHub Actions

The workflow `.github/workflows/android-apk.yml` automatically builds the debug
APK on each push to `feature/daily-entries`. Open **GitHub → Actions → Build
Android APK → latest successful run → Artifacts** to download
`BluePOS-Mobile-0.1.0-debug-APK`. Unzip and install `app-debug.apk` on Android
with permission to install apps from your browser/file manager.

Debug builds are for owner installation/visual review only, not production
release distribution. Android Play Store publishing requires separate release
signing and review.

## Security and build details

- No credentials or secret keys are hard-coded.
- Public server requests use ULIDs only; the backend is authoritative for
  tenant/warehouse access, prices, stock and financial calculations.
- Secure cookies are held in Android KeyStore-backed encrypted storage.
- Login location is requested only with user permission and sent to the
  existing authentication endpoint; it is not written to app analytics.
- The mobile client does not alter the existing frozen desktop Sales UI.
- Never use destructive DB commands; no database is packaged with the app.

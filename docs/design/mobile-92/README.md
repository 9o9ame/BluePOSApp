# BluePOS Mobile Premium Mockup Assets — Upload Checklist

**Branch:** `feature/daily-entries`  
**Status:** Text-only checkpoint; binary images are **not yet committed to GitHub**.

## Local download

The user-facing download is `BluePOS_Mobile_92_Screen_Reference_Pack.zip` (124 MB), generated from the individual premium-quality mockups in the conversation. The ZIP contains:

- `BluePOS_Mobile_Design_Approval_Pack/screens/`: 92 numbered PNG slots
- `BluePOS_Mobile_Design_Approval_Pack/SCREEN_MANIFEST.csv`: complete ordered manifest with source filenames, dimensions and SHA-256 hashes
- `BluePOS_Mobile_Design_Approval_Pack/README.md`: pack integrity and design gaps

There are **89 unique designs**; 79 duplicates a Sales Summary variant; 91 and 92 are *provisional duplicate menu references*. Obtain new final Settings and Administration Overview mockups before declaring all 92 approved.

**Never use** the previous rejected generic mockups under `BluePOS_92_Screen_Mockups/`.

## Safe upload procedure (only after verifying branch, approvals and clean tree)

1. Clone/open `9o9ame/BluePOSApp` on its existing `feature/daily-entries` branch. Do **not** create a new branch and do **not** switch away from unfinished work.
2. Verify the working tree is clean and current branch fast-forward pulled. Stop if diverged.
3. Unzip locally and copy the entire `screens/` directory into `docs/design/mobile-92/screens/`, and the CSV to `docs/design/mobile-92/SCREEN_MANIFEST.csv`.
4. Compare the 92 entries and SHA256 hashes in the manifest against copied PNGs.
5. Ensure the images are design-only documents, not declared in `pubspec.yaml` runtime Flutter assets.
6. Commit **only** `docs/design/mobile-92/` additions on `feature/daily-entries`; review diff, then push according to approved branch policy.
7. Record the resulting GitHub commit SHA and re-check the remote file count.
8. Keep repository release/CI and APK publishing restrictions unchanged.

See `docs/MOBILE_92_MOCKUP_IMPLEMENTATION_HANDOFF.md` for screen order, design decisions, security and tests.

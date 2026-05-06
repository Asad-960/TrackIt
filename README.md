# TrackIt

TrackIt is an offline-first expense tracker built with Flutter. Add daily
expenses by item name and amount, review monthly and yearly reports, and export
or restore backups using a portable JSON payload.

## Features

- Daily expense entry with item name, amount, category, notes, and date.
- Monthly and yearly totals with previous month history.
- Manual backup and restore via JSON (clipboard export/import).
- Settings for currency symbol, locale tag, and backup provider preference.

## Assumptions

- Storage is on-device (offline-first) using local preferences.
- Cloud backup is optional and shown as a placeholder until configured.
- Currency formatting uses a user-supplied symbol rather than locale-aware
  formatting.

## Getting Started

1. Install Flutter and its platform toolchains.
2. Fetch dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

# Daily Collection — Offline-first PWA

A static, installable PWA that stores its working dataset in IndexedDB. It has no server dependency and makes no network requests for application data.

## Run locally

Serve this directory over localhost (service workers require HTTPS or localhost):

```bash
cd offline
python3 -m http.server 4173
```

Open http://localhost:4173. Install from the browser menu after the first load. For production, deploy the contents of this directory under the intended URL path using HTTPS.

## Implemented

- Borrower create, search and edit
- Loan creation with principal, total payable and installment amount
- Payment recording with receipt number, date, mode and note
- Atomic IndexedDB transaction for payment + loan balance update
- Payment history, dashboard totals and outstanding balances
- Expense recording and cash-flow summary
- JSON backup/restore and payment CSV export
- Service-worker app-shell cache for offline launch

## Data model

All monetary values are integer paise. IndexedDB stores four object stores: borrowers, loans, payments and expenses. Payment rows are append-only in the UI. A payment write and corresponding loan balance update occur in one IndexedDB read-write transaction. Each payment has a UUID and a human-readable receipt number.

## Offline and durability guarantees

- The app works offline after the shell has been cached once.
- Records remain in the current browser profile on this device.
- There is no cloud sync, multi-device replication, authentication, encryption-at-rest layer, or remote backup in this build.
- Browser storage can be cleared by the user or reclaimed by the browser. Export backups frequently and store them securely.
- Do not treat browser-local storage as a substitute for a server-side financial ledger or disaster-recovery backup.

## Important next hardening

1. Add payment reversal records (never edit/delete posted payments).
2. Add loan schedule generation and due/overdue calculations.
3. Add IndexedDB schema migrations and automated tests.
4. Add PIN/biometric app lock and encrypted backup with a recovery key.
5. Add a conflict-safe sync protocol only after offline workflows are validated.
6. Validate amounts and all business rules in a tested domain layer.
7. Add receipt print/share, borrower detail view and expense history.

This is a local-first prototype, not yet a production accounting system. The app deliberately does not connect to the existing VPS MongoDB.

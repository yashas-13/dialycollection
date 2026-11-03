# Daily Collection Manager

Mobile-first admin-only loan and collections PWA based on the supplied screenshots.

## Features
- Dashboard: principal portfolio, collections, outstanding amount, today's receipts, charts and recent loans.
- Borrowers: add and search borrower records; view linked loans and exposure.
- Loans: daily, weekly and monthly cycles; flat-interest calculations and installment estimates.
- Collections: cash, UPI and bank payments, partial collections, notes and references.
- Reports: CSV loan register, collection register, outstanding summary and borrower export.
- PWA: manifest, install icons, service worker and Vite base path /dialycollection/.
- Supabase Auth integration and PostgreSQL schema with explicit admin allow-list, RLS and atomic payment RPC.

## Stack
React 19, TypeScript, Vite 7, vite-plugin-pwa, Recharts, Lucide, Supabase JS and PostgreSQL.

## Development
```sh
npm install
cp .env.example .env.local
npm run dev
```
Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in .env.local. Never expose a service-role key in browser code.
```sh
npm run typecheck
npm run build
npm run preview
```

The production build uses /dialycollection/. Publish the contents of dist/ at the VPS web subdirectory /dialycollection/.

## Database
Apply supabase/migrations/202611030001_initial_schema.sql. Create the first Auth user in Supabase Auth, then bootstrap the admin profile:
```sql
insert into public.admin_profiles(user_id, display_name)
select id, 'Administrator' from auth.users
where email = 'ADMIN_EMAIL_HERE';
```
A user is not an administrator until explicitly inserted into admin_profiles. Disable public self-registration. RLS gates application data. Direct payment insert/update/delete is intentionally not granted; authenticated admins must use post_payment with a fresh UUID idempotency key. The RPC locks the loan row, checks remaining balance and inserts the ledger record atomically.

## Current implementation boundary
The UI currently includes browser-local demo records for interaction review. It is not a production multi-device persistence layer: borrower/loan forms use localStorage and the payment UI does not yet call post_payment. Supabase sign-in and the secure SQL schema/RPC are integration foundations; the live data repository adapter, server-authoritative repayment schedules, receipts and automated integration/browser tests remain incomplete. Do not enter real customer or payment records in demo mode. Seeded names/amounts are illustrative.

## VPS deployment
1. Build with Node.js 20.19+ or 22.12+.
2. Upload dist/ contents to the VPS directory serving https://parkzone.in/dialycollection/.
3. Example Nginx configuration:
```nginx
location = /dialycollection { return 301 /dialycollection/; }
location /dialycollection/ {
    alias /var/www/parkzone/dialycollection/;
    try_files $uri $uri/ /dialycollection/index.html;
}
```
Check the alias path against the actual VPS layout. Serve HTTPS, add CSP/security headers, cache hashed assets immutably and avoid long caching index.html or sw.js.
4. VITE_* values are embedded at build time. Only Supabase URL and anon/publishable key belong in the browser.
5. Enable database backups/PITR where available and perform a restore drill.
6. Create admin Auth user and matching admin_profiles row; disable public sign-up.

## Financial assumptions
- INR currency.
- Current UI models flat simple interest: payable = principal × (1 + rate / 100).
- Installment amount rounds up; production schedule must adjust the final installment to reconcile exactly.
- Partial payments are allowed but cannot exceed remaining payable.
- Define holiday/weekend, missed installment, early payment and due-date rules before live usage.
- Set business timezone explicitly to Asia/Kolkata.
- Do not use screenshot content or seeded examples as real customer records.

## Verification checklist
- [ ] npm ci
- [ ] npm run typecheck
- [ ] npm run build
- [ ] Verify manifest and service worker at /dialycollection/
- [ ] Test sign-in/logout and direct unauthenticated access
- [ ] Test borrower CRUD and RLS
- [ ] Test daily/weekly/monthly schedule, including rounding reconciliation
- [ ] Test partial/final/overpayment, duplicate idempotency and concurrent payments
- [ ] Reconcile reports to ledger
- [ ] Test mobile install, offline shell and reconnect behavior
- [ ] Verify backup restore and deployed HTTPS URL

## Security
This is financial and personal data. Complete integration, security review, dependency audit, test suite, restore test and applicable legal/privacy review before production. Frontend navigation is not an authorization boundary; PostgreSQL RLS and least-privilege keys are required.

-- Daily Collection Manager: initial PostgreSQL schema
-- Apply with Supabase SQL editor or: supabase db push
create extension if not exists pgcrypto;

create table if not exists public.admin_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Administrator',
  created_at timestamptz not null default now()
);

create table if not exists public.borrowers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (length(trim(full_name)) between 1 and 160),
  phone text not null check (phone ~ '^\+?[0-9 ()-]{8,20}$'),
  address text not null default '',
  city text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists borrowers_phone_normalized
  on public.borrowers (regexp_replace(phone, '[^0-9]', '', 'g'));

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  borrower_id uuid not null references public.borrowers(id) on delete restrict,
  loan_code text not null unique,
  frequency text not null check (frequency in ('daily','weekly','monthly')),
  principal numeric(14,2) not null check (principal > 0),
  flat_interest_rate numeric(7,4) not null default 0 check (flat_interest_rate >= 0),
  total_payable numeric(14,2) not null check (total_payable >= principal),
  installment_amount numeric(14,2) not null check (installment_amount > 0),
  installment_count integer not null check (installment_count > 0),
  start_date date not null,
  next_due_date date not null,
  status text not null default 'active' check (status in ('active','closed','defaulted')),
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  amount numeric(14,2) not null check (amount > 0),
  paid_at timestamptz not null default now(),
  method text not null check (method in ('cash','upi','bank')),
  reference text,
  note text not null default '',
  idempotency_key uuid not null unique,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists loans_borrower_id_idx on public.loans(borrower_id);
create index if not exists loans_status_due_idx on public.loans(status,next_due_date);
create index if not exists payments_loan_paid_at_idx on public.payments(loan_id,paid_at desc);

create or replace view public.loan_balances
with (security_invoker = true) as
select l.*,
       coalesce(sum(p.amount),0)::numeric(14,2) as amount_paid,
       greatest(l.total_payable-coalesce(sum(p.amount),0),0)::numeric(14,2) as outstanding
from public.loans l
left join public.payments p on p.loan_id=l.id
group by l.id;

-- Only explicitly onboarded admin_profiles may use application tables.
create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_profiles ap where ap.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.admin_profiles enable row level security;
alter table public.borrowers enable row level security;
alter table public.loans enable row level security;
alter table public.payments enable row level security;

create policy "Admin can read own admin profile" on public.admin_profiles
for select to authenticated using (user_id=(select auth.uid()));
create policy "Admins manage borrowers" on public.borrowers
for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "Admins manage loans" on public.loans
for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "Admins read payment ledger" on public.payments
for select to authenticated using ((select public.is_admin()));

-- Payment posting is atomic: lock loan, verify admin, enforce idempotency,
-- reject overpayment, insert immutable payment and close a fully-paid loan.
create or replace function public.post_payment(
  p_loan_id uuid,
  p_amount numeric,
  p_method text,
  p_idempotency_key uuid,
  p_reference text default null,
  p_note text default ''
) returns public.payments
language plpgsql security definer
set search_path = ''
as $$
declare
  v_loan public.loans%rowtype;
  v_paid numeric(14,2);
  v_payment public.payments%rowtype;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'admin access required' using errcode='42501';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode='22023';
  end if;
  if p_method not in ('cash','upi','bank') then
    raise exception 'unsupported payment method' using errcode='22023';
  end if;

  select * into v_loan from public.loans where id=p_loan_id for update;
  if not found then raise exception 'loan not found' using errcode='P0002'; end if;

  select * into v_payment from public.payments where idempotency_key=p_idempotency_key;
  if found then return v_payment; end if;

  select coalesce(sum(amount),0) into v_paid from public.payments where loan_id=p_loan_id;
  if p_amount > v_loan.total_payable-v_paid then
    raise exception 'payment exceeds outstanding balance' using errcode='22003';
  end if;

  insert into public.payments(loan_id,amount,method,reference,note,idempotency_key,created_by)
  values(p_loan_id,p_amount,p_method,nullif(trim(p_reference),''),coalesce(p_note,''),p_idempotency_key,auth.uid())
  returning * into v_payment;

  if v_paid+p_amount >= v_loan.total_payable then
    update public.loans set status='closed',closed_at=now() where id=p_loan_id;
  end if;
  return v_payment;
end;
$$;
revoke all on function public.post_payment(uuid,numeric,text,uuid,text,text) from public, anon;
grant execute on function public.post_payment(uuid,numeric,text,uuid,text,text) to authenticated;

-- Do not grant direct insert/update/delete access to the financial ledger.
revoke insert, update, delete on public.payments from anon, authenticated;
grant select on public.payments to authenticated;
grant select, insert, update, delete on public.borrowers, public.loans to authenticated;

-- Bootstrap: create an auth user using Supabase Auth first, then run:
-- insert into public.admin_profiles(user_id,display_name)
-- select id, 'Administrator' from auth.users where email='ADMIN_EMAIL_HERE';

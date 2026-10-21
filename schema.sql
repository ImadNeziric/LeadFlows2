-- LeadFlow MVP — run this whole file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null default 'My Service Business',
  public_slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_name text not null,
  phone text,
  email text,
  service_type text not null,
  service_address text,
  description text,
  source text not null default 'Website form',
  status text not null default 'new' check (status in ('new','contacted','qualified','won','lost')),
  estimated_value numeric(12,2) not null default 0 check (estimated_value >= 0),
  won_value numeric(12,2) not null default 0 check (won_value >= 0),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists leads_business_created_idx on public.leads (business_id, created_at desc);
create index if not exists leads_business_status_idx on public.leads (business_id, status);

alter table public.businesses enable row level security;
alter table public.leads enable row level security;
revoke all on public.businesses from anon, authenticated;
revoke all on public.leads from anon, authenticated;
grant select, insert, update on public.businesses to authenticated;
grant select, insert, update, delete on public.leads to authenticated;

drop policy if exists "Owners can read own business" on public.businesses;
create policy "Owners can read own business" on public.businesses for select to authenticated
using ((select auth.uid()) = owner_id);
drop policy if exists "Owners can create own business" on public.businesses;
create policy "Owners can create own business" on public.businesses for insert to authenticated
with check ((select auth.uid()) = owner_id);
drop policy if exists "Owners can update own business" on public.businesses;
create policy "Owners can update own business" on public.businesses for update to authenticated
using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);

drop policy if exists "Owners can read own leads" on public.leads;
create policy "Owners can read own leads" on public.leads for select to authenticated
using (exists (select 1 from public.businesses b where b.id = leads.business_id and b.owner_id = (select auth.uid())));
drop policy if exists "Owners can create own leads" on public.leads;
create policy "Owners can create own leads" on public.leads for insert to authenticated
with check (exists (select 1 from public.businesses b where b.id = leads.business_id and b.owner_id = (select auth.uid())));
drop policy if exists "Owners can update own leads" on public.leads;
create policy "Owners can update own leads" on public.leads for update to authenticated
using (exists (select 1 from public.businesses b where b.id = leads.business_id and b.owner_id = (select auth.uid())))
with check (exists (select 1 from public.businesses b where b.id = leads.business_id and b.owner_id = (select auth.uid())));
drop policy if exists "Owners can delete own leads" on public.leads;
create policy "Owners can delete own leads" on public.leads for delete to authenticated
using (exists (select 1 from public.businesses b where b.id = leads.business_id and b.owner_id = (select auth.uid())));

-- Public inquiry form can create leads only through this function. Direct anonymous table access remains revoked.
create or replace function public.submit_public_lead(
  p_slug text, p_customer_name text, p_phone text, p_email text,
  p_service_type text, p_service_address text, p_description text,
  p_honeypot text default ''
) returns boolean
language plpgsql security definer set search_path = '' as $$
declare v_business_id uuid;
begin
  if coalesce(p_honeypot, '') <> '' then return true; end if;
  if length(trim(coalesce(p_customer_name,''))) < 2 or length(trim(coalesce(p_service_type,''))) < 2
    or length(coalesce(p_description,'')) > 3000 or length(coalesce(p_customer_name,'')) > 120
    or length(coalesce(p_phone,'')) > 60 or length(coalesce(p_email,'')) > 254
    or length(coalesce(p_service_address,'')) > 300 then
    raise exception 'Please check the form fields.';
  end if;
  if nullif(trim(coalesce(p_phone,'')), '') is null and nullif(trim(coalesce(p_email,'')), '') is null then
    raise exception 'Please provide a phone number or email address.';
  end if;
  select b.id into v_business_id from public.businesses b where b.public_slug = p_slug limit 1;
  if v_business_id is null then raise exception 'This inquiry form is unavailable.'; end if;
  insert into public.leads (business_id, customer_name, phone, email, service_type, service_address, description, source, status)
  values (v_business_id, trim(p_customer_name), nullif(trim(coalesce(p_phone,'')), ''), nullif(trim(coalesce(p_email,'')), ''),
    trim(p_service_type), nullif(trim(coalesce(p_service_address,'')), ''), trim(coalesce(p_description,'')), 'Website form', 'new');
  return true;
end; $$;
revoke all on function public.submit_public_lead(text,text,text,text,text,text,text,text) from public;
grant execute on function public.submit_public_lead(text,text,text,text,text,text,text,text) to anon, authenticated;

-- Only publishes a business display name for the public inquiry form; it exposes no customer records.
create or replace function public.get_public_business_name(p_slug text)
returns text language sql security definer set search_path = '' as $$
  select b.name from public.businesses b where b.public_slug = p_slug limit 1;
$$;
revoke all on function public.get_public_business_name(text) from public;
grant execute on function public.get_public_business_name(text) to anon, authenticated;

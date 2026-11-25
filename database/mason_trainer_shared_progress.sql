
create table public.mason_trainer_families (
 user_id uuid primary key references auth.users(id) on delete cascade,
 settings jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table public.mason_trainer_days (
 user_id uuid not null references public.mason_trainer_families(user_id) on delete cascade,
 day date not null,
 details jsonb not null default '{}'::jsonb check (jsonb_typeof(details)='object'),
 primary key(user_id,day)
);
create table public.mason_trainer_awards (
 user_id uuid not null references public.mason_trainer_families(user_id) on delete cascade,
 day date not null check(day <= (now() at time zone 'America/New_York')::date),
 mission text not null check(mission in ('morning','brain','gear','center','night')),
 created_at timestamptz not null default now(),
 primary key(user_id,day,mission)
);
create table public.mason_trainer_redemptions (
 user_id uuid not null references public.mason_trainer_families(user_id) on delete cascade,
 id uuid not null,
 cost integer not null check(cost in (100,200,300)),
 label text not null check(length(label) between 1 and 500),
 day date not null,
 created_at timestamptz not null default now(),
 primary key(user_id,id)
);
create table public.mason_trainer_claims (
 user_id uuid not null references public.mason_trainer_families(user_id) on delete cascade,
 week date not null check(extract(isodow from week)=1),
 created_at timestamptz not null default now(),
 primary key(user_id,week)
);
alter table public.mason_trainer_families enable row level security;
alter table public.mason_trainer_days enable row level security;
alter table public.mason_trainer_awards enable row level security;
alter table public.mason_trainer_redemptions enable row level security;
alter table public.mason_trainer_claims enable row level security;
create policy family_select on public.mason_trainer_families for select to authenticated using ((select auth.uid())=user_id);
create policy family_insert on public.mason_trainer_families for insert to authenticated with check ((select auth.uid())=user_id);
create policy family_update on public.mason_trainer_families for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy day_select on public.mason_trainer_days for select to authenticated using ((select auth.uid())=user_id);
create policy day_insert on public.mason_trainer_days for insert to authenticated with check ((select auth.uid())=user_id);
create policy day_update on public.mason_trainer_days for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy award_select on public.mason_trainer_awards for select to authenticated using ((select auth.uid())=user_id);
create policy award_insert on public.mason_trainer_awards for insert to authenticated with check ((select auth.uid())=user_id);
create policy redemption_select on public.mason_trainer_redemptions for select to authenticated using ((select auth.uid())=user_id);
create policy redemption_insert on public.mason_trainer_redemptions for insert to authenticated with check ((select auth.uid())=user_id);
create policy claim_select on public.mason_trainer_claims for select to authenticated using ((select auth.uid())=user_id);
create policy claim_insert on public.mason_trainer_claims for insert to authenticated with check ((select auth.uid())=user_id);
revoke all on public.mason_trainer_families,public.mason_trainer_days,public.mason_trainer_awards,public.mason_trainer_redemptions,public.mason_trainer_claims from anon,authenticated;
grant select,insert,update on public.mason_trainer_families,public.mason_trainer_days to authenticated;
grant select,insert on public.mason_trainer_awards,public.mason_trainer_redemptions,public.mason_trainer_claims to authenticated;
create function public.mason_check_redemption() returns trigger language plpgsql security invoker set search_path='' as $$
declare available integer;
begin
 if auth.uid() is null or new.user_id<>auth.uid() then raise exception 'Not authorized'; end if;
 perform 1 from public.mason_trainer_families where user_id=new.user_id for update;
 if exists(select 1 from public.mason_trainer_redemptions where user_id=new.user_id and id=new.id) then return null; end if;
 select (select count(*) from public.mason_trainer_awards where user_id=new.user_id)-(select coalesce(sum(cost),0) from public.mason_trainer_redemptions where user_id=new.user_id) into available;
 if new.cost>available then raise exception 'Not enough saved points'; end if;
 return new;
end $$;
revoke all on function public.mason_check_redemption() from public,anon,authenticated;
create trigger mason_redemption_balance before insert on public.mason_trainer_redemptions for each row execute function public.mason_check_redemption();
create function public.mason_check_claim() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if auth.uid() is null or new.user_id<>auth.uid() then raise exception 'Not authorized'; end if;
 if (select count(*) from public.mason_trainer_awards where user_id=new.user_id and day>=new.week and day<new.week+7)<25 then raise exception 'Earn 25 weekly points first'; end if;
 return new;
end $$;
revoke all on function public.mason_check_claim() from public,anon,authenticated;
create trigger mason_claim_threshold before insert on public.mason_trainer_claims for each row execute function public.mason_check_claim();


-- aadat — Supabase schema
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New query).

-- ─── Habits ────────────────────────────────────────────────────────────────

create table public.habits (
  id           bigserial    primary key,
  user_id      uuid         not null references auth.users(id) on delete cascade,
  title        text         not null default '',
  description  text         not null default '',
  category     text         not null default '',
  recurrence   text         not null default 'daily',
  custom_days  text         not null default '',
  start_date   date,
  end_date     date,
  is_favorite  boolean      not null default false,
  created_at   timestamptz  not null default now()
);

alter table public.habits enable row level security;

create policy "users manage own habits"
  on public.habits for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── Completions ───────────────────────────────────────────────────────────
-- completion_key stores the full key used in the Flutter app:
--   daily:   'd|{habitId}|yyyy-MM-dd'
--   weekly:  'w|{habitId}|yyyy-MM-dd'  (week-start date)
--   monthly: 'm|{habitId}|yyyy-MM'

create table public.completions (
  id              bigserial    primary key,
  user_id         uuid         not null references auth.users(id) on delete cascade,
  habit_id        bigint       not null references public.habits(id) on delete cascade,
  completion_key  text         not null,
  created_at      timestamptz  not null default now(),
  unique (user_id, completion_key)
);

alter table public.completions enable row level security;

create policy "users manage own completions"
  on public.completions for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── Notes ─────────────────────────────────────────────────────────────────
-- note_key format: '{habitId}|yyyy-MM-dd'

create table public.notes (
  id          bigserial    primary key,
  user_id     uuid         not null references auth.users(id) on delete cascade,
  habit_id    bigint       not null references public.habits(id) on delete cascade,
  note_key    text         not null,
  content     text         not null default '',
  created_at  timestamptz  not null default now(),
  unique (user_id, note_key)
);

alter table public.notes enable row level security;

create policy "users manage own notes"
  on public.notes for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── Profiles ──────────────────────────────────────────────────────────────
-- Auto-created on signup via trigger below. Used for friend lookups by email.

create table public.profiles (
  id           uuid  primary key references auth.users(id) on delete cascade,
  email        text  not null,
  display_name text,
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "authenticated users can read profiles"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "users update own profile"
  on public.profiles for update
  using (auth.uid() = id);

grant select, update on public.profiles to authenticated;

-- Trigger: create profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── Friendships ───────────────────────────────────────────────────────────

create table public.friendships (
  id           bigserial    primary key,
  requester_id uuid         not null references auth.users(id) on delete cascade,
  addressee_id uuid         not null references auth.users(id) on delete cascade,
  status       text         not null default 'pending',  -- 'pending' | 'accepted'
  created_at   timestamptz  not null default now(),
  unique (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

alter table public.friendships enable row level security;

create policy "users see their own friendships"
  on public.friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "users send requests as requester"
  on public.friendships for insert
  with check (auth.uid() = requester_id);

create policy "addressee can accept"
  on public.friendships for update
  using (auth.uid() = addressee_id);

create policy "either party can remove"
  on public.friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

grant select, insert, update, delete on public.friendships to authenticated;
grant usage, select on sequence public.friendships_id_seq to authenticated;

-- ─── Grants ────────────────────────────────────────────────────────────────
-- RLS policies filter rows, but the authenticated role also needs base table
-- privileges or Postgres will deny the request before RLS even runs.

grant select, insert, update, delete on public.habits      to authenticated;
grant select, insert, update, delete on public.completions to authenticated;
grant select, insert, update, delete on public.notes       to authenticated;

grant usage, select on sequence public.habits_id_seq      to authenticated;
grant usage, select on sequence public.completions_id_seq to authenticated;
grant usage, select on sequence public.notes_id_seq       to authenticated;

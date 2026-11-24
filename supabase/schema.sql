-- =====================================================================
-- Rising Stars — instructor portal database (Supabase / PostgreSQL)
-- Run this whole file once in Supabase: SQL Editor -> New query -> Run.
-- Safe to re-run: it only creates things that do not exist yet.
-- =====================================================================

-- ---------- Staff profiles (one row per login) ----------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  role        text not null default 'instructor'
              check (role in ('instructor', 'coordinator', 'admin')),
  created_at  timestamptz not null default now()
);

-- Create a profile automatically when a staff account is added
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Is the signed-in user a coordinator or admin?
create or replace function public.is_coordinator()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and role in ('coordinator', 'admin'));
$$;

-- ---------- Students (keep identifying data to a minimum) ----------
create table if not exists public.students (
  id            uuid primary key default gen_random_uuid(),
  student_code  text unique not null,          -- e.g. RS-014
  first_name    text not null,
  date_of_birth date,
  active        boolean not null default true,
  created_at    timestamptz not null default now()
);

-- Which instructor works with which student
create table if not exists public.student_instructors (
  student_id     uuid references public.students(id) on delete cascade,
  instructor_id  uuid references public.profiles(id) on delete cascade,
  primary key (student_id, instructor_id)
);

create or replace function public.is_assigned(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.student_instructors
                 where student_id = sid and instructor_id = auth.uid());
$$;

-- IEP goals per student
create table if not exists public.iep_goals (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.students(id) on delete cascade,
  area        text not null,                  -- Communication, Fine motor, Behaviour...
  goal_text   text not null,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ---------- Session notes ----------
create table if not exists public.session_notes (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid not null references public.students(id) on delete restrict,
  instructor_id      uuid not null references public.profiles(id) default auth.uid(),
  session_date       date not null default current_date,
  therapy            text not null,
  duration_min       int  not null default 45,
  attendance         text not null default 'present'
                     check (attendance in ('present', 'late', 'absent', 'cancelled')),
  engagement         text check (engagement in ('low', 'okay', 'good', 'excellent')),
  goal_ratings       jsonb not null default '[]'::jsonb,  -- [{goal_id, area, goal_text, rating 1-5}]
  activities         text,
  observations       text,
  home_practice      text,
  next_plan          text,
  share_with_parents boolean not null default true,
  flag_coordinator   boolean not null default false,
  status             text not null default 'draft'
                     check (status in ('draft', 'submitted', 'approved', 'returned')),
  reviewer_comment   text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists session_notes_student_date on public.session_notes (student_id, session_date);

-- ---------- Course proposals ----------
create table if not exists public.course_proposals (
  id                uuid primary key default gen_random_uuid(),
  instructor_id     uuid not null references public.profiles(id) default auth.uid(),
  title             text not null,
  track             text not null check (track in ('child', 'parent', 'school')),
  audience          text,
  duration          text,
  fee_pkr           int,
  outcomes          text,
  materials         text,
  status            text not null default 'draft'
                    check (status in ('draft', 'submitted', 'approved', 'returned')),
  reviewer_comment  text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- Keep updated_at current
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists touch_session_notes on public.session_notes;
create trigger touch_session_notes before update on public.session_notes
  for each row execute function public.touch_updated_at();
drop trigger if exists touch_course_proposals on public.course_proposals;
create trigger touch_course_proposals before update on public.course_proposals
  for each row execute function public.touch_updated_at();

-- =====================================================================
-- Row Level Security: nobody sees anything unless a rule below allows it
-- =====================================================================
alter table public.profiles            enable row level security;
alter table public.students            enable row level security;
alter table public.student_instructors enable row level security;
alter table public.iep_goals           enable row level security;
alter table public.session_notes       enable row level security;
alter table public.course_proposals    enable row level security;

-- Profiles: everyone sees their own; coordinators see all and can change roles
drop policy if exists "profiles read" on public.profiles;
create policy "profiles read" on public.profiles for select
  using (id = auth.uid() or public.is_coordinator());
drop policy if exists "profiles manage" on public.profiles;
create policy "profiles manage" on public.profiles for update
  using (public.is_coordinator());

-- Students: instructors see only their assigned students; coordinators manage all
drop policy if exists "students read" on public.students;
create policy "students read" on public.students for select
  using (public.is_coordinator() or public.is_assigned(id));
drop policy if exists "students manage" on public.students;
create policy "students manage" on public.students for all
  using (public.is_coordinator()) with check (public.is_coordinator());

drop policy if exists "assignments read" on public.student_instructors;
create policy "assignments read" on public.student_instructors for select
  using (instructor_id = auth.uid() or public.is_coordinator());
drop policy if exists "assignments manage" on public.student_instructors;
create policy "assignments manage" on public.student_instructors for all
  using (public.is_coordinator()) with check (public.is_coordinator());

drop policy if exists "goals read" on public.iep_goals;
create policy "goals read" on public.iep_goals for select
  using (public.is_coordinator() or public.is_assigned(student_id));
drop policy if exists "goals manage" on public.iep_goals;
create policy "goals manage" on public.iep_goals for all
  using (public.is_coordinator() or public.is_assigned(student_id))
  with check (public.is_coordinator() or public.is_assigned(student_id));

-- Session notes: instructors write notes only for their students, and edit
-- them only while draft/returned. Coordinators read and review all notes.
drop policy if exists "notes read" on public.session_notes;
create policy "notes read" on public.session_notes for select
  using (instructor_id = auth.uid() or public.is_coordinator());
drop policy if exists "notes insert" on public.session_notes;
create policy "notes insert" on public.session_notes for insert
  with check (instructor_id = auth.uid() and public.is_assigned(student_id)
              and status in ('draft', 'submitted'));
drop policy if exists "notes edit own" on public.session_notes;
create policy "notes edit own" on public.session_notes for update
  using (instructor_id = auth.uid() and status in ('draft', 'returned'))
  with check (instructor_id = auth.uid() and status in ('draft', 'submitted'));
drop policy if exists "notes review" on public.session_notes;
create policy "notes review" on public.session_notes for update
  using (public.is_coordinator()) with check (public.is_coordinator());

-- Course proposals: same pattern
drop policy if exists "proposals read" on public.course_proposals;
create policy "proposals read" on public.course_proposals for select
  using (instructor_id = auth.uid() or public.is_coordinator());
drop policy if exists "proposals insert" on public.course_proposals;
create policy "proposals insert" on public.course_proposals for insert
  with check (instructor_id = auth.uid() and status in ('draft', 'submitted'));
drop policy if exists "proposals edit own" on public.course_proposals;
create policy "proposals edit own" on public.course_proposals for update
  using (instructor_id = auth.uid() and status in ('draft', 'returned'))
  with check (instructor_id = auth.uid() and status in ('draft', 'submitted'));
drop policy if exists "proposals review" on public.course_proposals;
create policy "proposals review" on public.course_proposals for update
  using (public.is_coordinator()) with check (public.is_coordinator());

-- Nothing is ever deleted from the portal: no delete policies on notes or proposals.

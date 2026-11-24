# Rising Stars staff portal — setup guide

The staff portal lives at **https://risingstarsen.org/portal/**.
Instructors sign in, write session notes, propose courses and print progress reports.
Coordinators also review submissions and manage students, IEP goals and staff roles.

Everything is saved in a **Supabase** database (free to start). The website itself stays on GitHub Pages.

| Page | What it does |
|---|---|
| `portal/index.html` | Staff login (and "forgot password") |
| `portal/dashboard.html` | My notes, my proposals, items awaiting review (coordinators) |
| `portal/note.html` | Session note template — saves to the database, submit for review |
| `portal/proposal.html` | Course proposal template |
| `portal/report.html` | Progress report for a student over a date range — print or save as PDF |
| `portal/students.html` | Coordinators: add students, assign instructors, IEP goals, staff roles |
| `portal/reset.html` | Set a password (from an invite or reset email) |
| `supabase/schema.sql` | Creates the database tables and the security rules |

---

## Step 1 — Create the Supabase project (10 minutes)

1. Go to **https://supabase.com** → **Start your project** → sign in with your GitHub account.
2. **New project**
   - Name: `rising-stars`
   - Database password: click **Generate**, then save it somewhere safe (password manager)
   - Region: **South Asia (Mumbai)** — closest to Karachi
   - Plan: Free
3. Wait 1–2 minutes until the project is ready.

## Step 2 — Create the tables

1. Left menu → **SQL Editor** → **New query**.
2. Open `D:\Rising Star\website\supabase\schema.sql` in VS Code, select all (`Ctrl + A`), copy.
3. Paste into Supabase and press **Run**. You should see *"Success. No rows returned"*.
4. Check: left menu → **Table Editor** shows `profiles`, `students`, `student_instructors`, `iep_goals`, `session_notes`, `course_proposals`.

## Step 3 — Login settings

1. **Authentication → Sign In / Providers → Email**: keep Email enabled, and turn **OFF "Allow new users to sign up"**.
   Only people you invite can get an account.
2. **Authentication → URL Configuration**
   - **Site URL:** `https://risingstarsen.org/portal/reset.html`
   - **Redirect URLs** → Add: `https://risingstarsen.org/portal/reset.html` and `http://localhost:8000/portal/reset.html`
   - Save.

## Step 4 — Connect the website to the database

1. **Project Settings → API Keys** (or **Data API**). Copy:
   - **Project URL** — looks like `https://abcdxyz.supabase.co`
   - The **anon / publishable** key (public). **Never** use the `service_role` / secret key.
2. Open `portal\config.js` in VS Code and paste both values:

```js
window.RS_CONFIG = {
  SUPABASE_URL: 'https://abcdxyz.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...or sb_publishable_...'
};
```

The public key is meant to be in website code — the security rules in `schema.sql`
decide who can see what (each instructor sees only their assigned students).

## Step 5 — Create your own admin account

1. **Authentication → Users → Add user → Create new user**
   - Your email, a strong password, tick **Auto Confirm User** → Create.
2. **SQL Editor → New query**, paste (change the email and name), **Run**:

```sql
update public.profiles
set role = 'admin', full_name = 'Ertiza Abbas'
where id = (select id from auth.users where email = 'your-email@example.com');
```

3. Do the same later for Mrs. Sarwat Zehra and the coordinator (role `admin` or `coordinator`).

## Step 6 — Test on your computer

In the VS Code terminal (with `rising-stars` active):

```bat
python -m http.server 8000
```

Open **http://localhost:8000/portal/** → sign in → you should see the Dashboard.
Go to **Students & goals**, add a test student (e.g. `RS-TEST`), assign yourself, add a goal,
then write a session note and generate a progress report.

## Step 7 — Publish

```bat
git add -A
git commit -m "Add staff portal"
git push
```

After 1–2 minutes the portal is live at **https://risingstarsen.org/portal/**
(the **Staff login** link at the top of every page goes there).

## Step 8 — Invite the instructors

For each instructor:

1. Supabase → **Authentication → Users → Add user → Send invitation** → their email.
2. They receive an email → click the link → choose their password on the Rising Stars page → done.
3. Their name shows as the first part of their email. To fix it: **Table Editor → profiles** → double-click `full_name` → type the real name.
4. In the portal → **Students & goals** → open each student → tap the instructor's name to assign them.

The built-in Supabase email allows only a few emails per hour — invite people in small batches.
(For many invites, connect your own email service later under Authentication → Emails → SMTP.)

---

## Roles

| Role | Can do |
|---|---|
| **instructor** | Sees only students assigned to them. Writes session notes and course proposals; edits them while in Draft or Returned. Progress reports from their own notes. |
| **coordinator** | Everything above for all students, plus: approve / return notes and proposals, add students, assign instructors, edit IEP goals, change staff roles. |
| **admin** | Same as coordinator (use for Mrs. Sarwat Zehra and yourself). |

Notes and proposals are never deleted from the portal. A submitted note is locked; a coordinator can return it for changes.

## Important — keep the data safe

- **Free projects pause after 7 days with no activity.** Daily use keeps it awake; if it pauses, open the Supabase dashboard and click **Restore**. Nothing is lost.
- **Backups:** the free plan does not keep downloadable daily backups. Once the portal is in daily use, upgrade to **Pro (US$25/month)** for automatic daily backups and no pausing — recommended for children's records. Until then, once a month: Table Editor → each table → **Export → CSV**, and keep the files in a secure folder.
- Keep student records minimal (code + first name). Do not type diagnoses or medical details into free-text boxes.
- Each staff member uses their own login — never share passwords. Remove leavers: Authentication → Users → ⋯ → Delete user.

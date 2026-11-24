# Rising Stars website — risingstarsen.org

Static website for Rising Stars School for Special Needs & Rehabilitation Center, Karachi.
Plain HTML/CSS/JS — no build step. Hosted on GitHub Pages, domain on Namecheap.

## Folder contents

| File | Page |
|---|---|
| `index.html` | Home (landing page) |
| `events.html` | Events & News |
| `team.html` | Our Team |
| `projects.html` | Projects |
| `contact.html` | Contact (with Google Map) |
| `staff.html` | Old address — forwards to the staff portal |
| `portal/` | Staff portal: login, session notes, course proposals, progress reports (see `PORTAL-SETUP.md`) |
| `supabase/schema.sql` | Database tables and security rules for the portal |
| `404.html` | Page-not-found |
| `assets/img/` | Logo, photos, team portraits |
| `assets/css/site.css` | Header, footer, mobile layout |
| `assets/js/site.js` | Forms send the enquiry to Rising Stars on WhatsApp (0333 3447861) |
| `CNAME` | Tells GitHub Pages to serve the site on risingstarsen.org |

## 1. Put the files in place (Windows)

1. Download `rising-stars-website.zip`.
2. Right-click it → **Extract All…** → choose `D:\Rising Star\website`.
3. Open `D:\Rising Star\website` and check you see `index.html` directly inside it
   (not inside another sub-folder). If there is an extra folder level, move its contents up one level.

## 2. Open in VS Code and create the `rising-stars` environment

1. VS Code → **File → Open Folder…** → `D:\Rising Star\website`.
2. Open a terminal: **Terminal → New Terminal** (PowerShell).
3. Create and activate the virtual environment:

```powershell
python -m venv rising-stars
.\rising-stars\Scripts\Activate.ps1
```

If PowerShell blocks the activate script, run this once, then activate again:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

4. Preview the site locally:

```powershell
python -m http.server 8000
```

Open http://localhost:8000 in your browser. Press `Ctrl + C` in the terminal to stop.

(The `rising-stars` folder is listed in `.gitignore`, so it is never uploaded to GitHub.)

## 3. Push to GitHub

First time only — tell Git who you are:

```powershell
git config --global user.name "Ertiza Abbas"
git config --global user.email "you@example.com"
```

Then, inside `D:\Rising Star\website`:

```powershell
git init
git branch -M main
git add .
git commit -m "Launch Rising Stars website"
git remote add origin https://github.com/ErtizaAbbas/rising_stars.git
git push -u origin main
```

A browser window may ask you to sign in to GitHub — approve it.

If the push is rejected because the repo already has a file (e.g. a README):

```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## 4. Turn on GitHub Pages

1. Open https://github.com/ErtizaAbbas/rising_stars → **Settings → Pages**.
2. **Source:** Deploy from a branch. **Branch:** `main`, folder `/ (root)` → **Save**.
3. **Custom domain:** it should already show `risingstarsen.org` (from the `CNAME` file). If not, type it and **Save**.

Note: free GitHub Pages needs the repository to be **Public**
(Settings → General → Danger Zone → Change visibility). The site files contain nothing private.

## 5. Point the domain at GitHub (Namecheap)

1. Namecheap → **Domain List** → `risingstarsen.org` → **Manage**.
2. Make sure **Nameservers** is set to **Namecheap BasicDNS**.
3. Open **Advanced DNS**. Delete the default parking records
   (the `CNAME www → parkingpage.namecheap.com` and any `URL Redirect` record).
4. Add these records (TTL: Automatic):

| Type | Host | Value |
|---|---|---|
| A Record | `@` | `185.199.108.153` |
| A Record | `@` | `185.199.109.153` |
| A Record | `@` | `185.199.110.153` |
| A Record | `@` | `185.199.111.153` |
| CNAME Record | `www` | `ertizaabbas.github.io.` |

5. Save. DNS usually updates within 30 minutes (can take up to 24 hours).
6. Back in GitHub **Settings → Pages**, wait for the green "DNS check successful",
   then tick **Enforce HTTPS** (it may take up to an hour to become available).

The site is then live at **https://risingstarsen.org**.

## 6. Updating the site later

Edit files in VS Code, then:

```powershell
git add .
git commit -m "Describe what changed"
git push
```

GitHub Pages republishes automatically within a minute or two.

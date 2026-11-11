# STS Entry Portal

A free website where schools register and enter students, judges register and score projects, and STAWA staff run everything from an admin area.

**How it is put together**
| Part | What it does | Where it lives |
|---|---|---|
| Website (`index.html`) | Every screen: schools, judges, admin | GitHub Pages (holds no data) |
| Database and logins | Schools, entries, judges, assignments, scores, dates | Supabase (free plan) |
| Uploaded files | Projects and reports | Google Drive (stawaadmin@gmail.com) |
| Automatic emails | School, judge and entry emails from admin@stawa.net | Google Apps Script, sending through Microsoft 365 |

**Files in this folder**
- `index.html`: the website.
- `schema.sql`, then `update-2-judging.sql` to `update-7-email.sql`: database setup, to be run in that order.
- `apps-script/Code.gs` and `apps-script/appsscript.json`: the Google script for Drive uploads and emails.
- `GOOGLE-SETUP.md`: step-by-step guide for Drive, Microsoft and the emails.

## Setting up from scratch
**1. Supabase project.** Sign up at https://supabase.com, click **New project**, name it `sts`, save the database password, and choose the region closest to Perth (Sydney or Singapore).

**2. Database.** In **SQL Editor**, run each file in this order (new query, paste, **Run**): `schema.sql`, `update-2-judging.sql`, `update-3-cutoff.sql`, `update-4-lock-edits.sql`, `update-5-scoring.sql`, `update-6-dates.sql`, `update-7-email.sql`. Each is safe to run twice.

**3. Admin login.** In **Authentication**, **Users**, **Add user**: email `admin@stawa.net`, a password of your choice, and tick **Auto Confirm User**. Then, in the sign-in settings, turn **off** "Allow new users to sign up". `schema.sql` already lists admin@stawa.net as an admin. To add another staff member, create their user the same way and run `insert into admins (email) values ('their@email');`.

**4. Connect the website.** In `index.html`, near the top of the script, set:
- `SUPABASE_URL` and `SUPABASE_KEY`: from **Project Settings**, **API Keys**. Use the project URL (without `/rest/v1/`) and the **publishable** key. Never use the secret or service_role key.
- `DRIVE_URL`: the Apps Script web app address from `GOOGLE-SETUP.md`. If you leave it unset, uploads fall back to Supabase storage (1 GB, 50 MB per file).

**5. Google Drive and emails.** Follow `GOOGLE-SETUP.md`.

**6. Put the website online.** Create a public GitHub repository, upload `index.html` (the other files are optional), then **Settings**, **Pages**, deploy from branch `main` and folder `/ (root)`. Your address will be `https://YOURNAME.github.io/REPOSITORY/`. Put that address in `SITE` in `Code.gs`.

**7. Test everything** (see `GOOGLE-SETUP.md`, Part 5), then delete the test rows in Admin, using each row's **Delete** button, before opening for real.

## Running the competition
1. **Admin, Opening and closing dates:** set when school registration, submissions and judge registration open and close (Perth time). Blank means no limit.
2. **School registration and entries:** schools register for a 4-digit code and log in with the code and their email. Judges register for a 3-digit number.
3. **After submissions close:** schools can no longer add or edit entries. Admin still can (**Edit** and **Delete** on the master list).
4. **Judge assignments tab, Assign projects:** each project goes to two judges, avoiding conflicts and balancing workloads. Projects flagged ⚠ move to the top of the master list for you to check. Change a judge by typing another judge number next to the project.
5. **Judging:** judges log in with their number and email, click **Judge**, and enter marks. The judge's number turns green on the master list once they have judged.
6. **Download judging results Excel:** all scores, the two judges' totals and the average. Orange rows have totals more than 6 apart, and yellow marks the top 5 averages in each category and age division.
7. **Download Excel** (master list): every school, judge, entry and category sheet.

## Good to know
- **Supabase free plan:** 500 MB database, and projects pause after a week of no activity. Click **Restore** in the dashboard before opening each year. There are no automatic backups, so download the Excel files regularly.
- **Google Drive:** files use the Google account's storage (15 GB on a free Gmail account). Deleting an entry or school in Admin moves its Drive files to the Drive bin.
- **Privacy of files:** uploaded files are only reachable through their long link. Judges only see the projects assigned to them, with no student or school names, but anyone given a link could pass it on.
- **Emails:** the Microsoft secret expires (6 to 24 months). Set a reminder to create a new one, or emails will stop.
- **A new year:** delete last year's schools, entries, judges, assignments and scores (or use the Delete buttons), then reset the dates in Admin. The `admins` and `settings` tables stay as they are.
- **Logo and colours** are inside `index.html`.

## Updating an existing install
1. Run any `update-N` SQL files you haven't run yet, in order.
2. Upload the new `index.html` to GitHub (**Add file**, **Upload files**, **Commit changes**) and wait a few minutes.
3. If `Code.gs` changed, paste it into the Apps Script and deploy a **New version** (**Deploy**, **Manage deployments**, pencil icon).

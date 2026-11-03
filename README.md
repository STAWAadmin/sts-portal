# STS Entry Portal: setup guide

About 20 minutes, no coding, and **free**: Supabase (free plan) stores the data and files, and any free static host serves the page. There is nothing to install.

You will end up with one website where schools register and enter students, judges register, and STAWA staff log in to the admin area, see the master list and category sheets, copy private judge links and download everything as Excel.

## Step 1. Create the free Supabase project
1. Go to https://supabase.com and sign up (free, no card needed).
2. Click **New project**. Name it `sts`, choose a database password (save it somewhere, you won't need it day to day), and pick the region closest to Perth (Singapore or Sydney).
3. Wait about two minutes while it sets up.

## Step 2. Create the database
1. In the left menu click **SQL Editor** and **New query**.
2. Open `schema.sql` from this folder, copy everything, paste it in, and click **Run**.
3. You should see "Success". This creates the tables, security rules, the file storage bucket and the functions the website uses.

## Step 3. Create the admin login
1. Left menu: **Authentication**, then **Users**, then **Add user**, then **Create new user**.
2. Email: `admin@stawa.net`. Password: the staff password you chose. Tick **Auto Confirm User**, then create.
3. Still in Authentication, open the sign-in settings (Sign In / Providers) and turn **off** "Allow new users to sign up". Nobody else can then create accounts.
4. `schema.sql` already registered admin@stawa.net as an admin. To add another staff member, create their user the same way, then run `insert into admins (email) values ('their@email');` in the SQL Editor.

## Step 4. Connect the website to Supabase
1. In Supabase, open **Project Settings**, then **API** (or **Data API**).
2. Copy the **Project URL** and the **anon public** key. Never use the `service_role` key.
3. Open `index.html` in any text editor, find the two lines near the top of the script that say `PASTE_YOUR_...`, paste the values between the quotes, and save.

## Step 5. Put it online (free)
Pick one. All three are free and you only upload `index.html`:
- **Cloudflare Pages**: Workers & Pages, Create, Pages, **Upload assets**, drag in the folder.
- **Netlify Drop**: https://app.netlify.com/drop, drag the folder in.
- **GitHub Pages**: upload `index.html` to a repository and turn on Pages.

You get a web address straight away. Share that with schools and judges, and optionally point a STAWA address at it later.

## Step 6. Test it
1. Register a test school, note the 4-digit code, log in with the code and email, and submit a test entry with a YouTube link and one with a small file.
2. Go to **Admin**, log in, and check the entry appears. Try **Copy link**, open it in a private window to see the judge view, then **Download Excel**.
3. Delete test rows in Supabase under **Table Editor** before the competition opens.

## Good to know (free plan)
- **Limits:** 500 MB database, 1 GB file storage, 50 MB per file, 5 GB of downloads a month. Text entries are tiny, so storage is the one to watch. Ask schools to put videos on YouTube or Vimeo and paste the link. Check current limits at https://supabase.com/pricing.
- **Pausing:** free projects pause after a week with no activity. Out of season, click **Restore** in the Supabase dashboard before you open entries.
- **Backups:** the free plan has no automatic backups, so click **Download Excel** in Admin regularly. It includes every school, judge, entry and all 30 category sheets in your existing layout.
- **Privacy of files:** uploaded files sit at long random web addresses that are not listed anywhere. Only judges you give a link to can open them, but anyone who is given a link could pass it on.
- **No automatic emails yet:** the school code is shown on screen after registering and is visible in Admin, so you can resend it. Sending emails automatically is a possible next step.
- **Logo and colours** are inside `index.html` if you ever want to change them.

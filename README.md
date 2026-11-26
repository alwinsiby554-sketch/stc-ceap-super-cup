# STC CEAP Super Cup 2026 — Website Package

A responsive public football tournament website and administrator dashboard for the 14-team STC CEAP Super Cup 2026. It is designed for mobile use and can be deployed as a static site. Cloud persistence, shared public viewing, admin sign-in and image uploads are provided through Supabase.

## Included

- Public home page, fixtures/results, team directory, player directory, knockout bracket, goal/assist leaders, awards and sponsors.
- Admin login using Supabase Auth; public visitors do not need an account.
- Multiple authorised admins (grant each person's Supabase Auth user ID in `admin_users`).
- Add/edit/delete teams, coaches, players, fixtures and sponsors.
- Team history, coach details/photos, player photos/profiles and sponsor logos/details.
- Manual fixture creation and a random 14-team draw. The bracket is six opening matches, two byes, four quarter-finals, two semi-finals, final and third-place match.
- Match dates/times, 15/20-minute (or custom) halves, status, scores, penalty shootout scores, match report and event entry for goals, own goals and cards.
- Knockout winners feed forward to later rounds when a match is marked Completed and has a valid winner.
- Public live refresh when the cloud row changes (Realtime must be enabled for the project).
- Player goal/assist tables, tournament awards, audit activity, CSV statistics export, JSON backup/restore and browser print-to-PDF.
- Supabase Storage upload support for team/player/coach/sponsor images.
- Local preview mode for trying the public interface before cloud configuration.

## Important limitations to understand

- The website is a source package, not a website that is already published. It has no public URL until you deploy it.
- Cloud mode is required for permanent cross-device data. Local preview mode stores data only in that browser and is not shared.
- The tournament data is stored as one JSON document in a single database row. It is suitable for a small college tournament, but simultaneous edits by multiple admins can overwrite one another. Coordinate edits so two admins do not save at exactly the same time. A larger production system should use separate relational tables and transactional match updates.
- The event editor accepts one event per line in the format `minute | event type | scorer player ID | assist player ID`. The player IDs are displayed in the match editor for reference. Use `Goal`, `Own Goal`, `Yellow Card` or `Red Card`. Goal/assist leaderboards are derived from recorded events; the match score is entered separately and should be checked against the event list.
- The match clock controls are a basic elapsed-time helper, not an official referee clock or a server-synchronised clock. Record the official score and match status manually.
- Admin accounts currently have the same permission level. Granular roles (owner, scorekeeper, team manager) are not implemented.
- Backup downloads are manual. Supabase project-level backup/restore policies are separate and should also be configured by the project owner.
- The 14-team bracket is generated automatically, but the exact team/bye assignments and kick-off schedule must be checked by the tournament organiser. Ten matches on Day 1 may be too many depending on ground availability; confirm timings before publishing fixtures.
- The site does not automatically record real-world match events. An admin must enter scores, scorers, assists, cards and match status.

## Step 1 — Configure Supabase cloud database (required for permanent data)

Do this before publishing if you want public visitors on different phones to see the same updates.

1. Open [Supabase](https://supabase.com/) in your phone browser and create/sign in to an account.
2. Create a new project. Save the database password somewhere safe. Wait until the project is ready.
3. Open **SQL Editor → New query**. Open `supabase/schema.sql` from this ZIP, copy all its contents, paste into SQL Editor and tap **Run**. This creates the public read-only tournament data row, admin access rules and public media bucket with admin-only upload permissions.
4. Open **Project Settings → API**. Copy the Project URL and the publishable/anon key. Do not copy a `service_role` or secret key.
5. Open `config.js` in a text editor and paste the values between the quotes:

   ```js
   export const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
   export const SUPABASE_ANON_KEY = 'YOUR-PUBLISHABLE-OR-ANON-KEY';
   ```

6. Create your first administrator in **Authentication → Users → Add user**. Set the email and password. Confirm the user if Supabase asks you to.
7. Open that user's details and copy the user UUID. In **SQL Editor**, run the statement below after replacing the placeholder:

   ```sql
   insert into public.admin_users(user_id)
   values ('PASTE-AUTH-USER-UUID-HERE')
   on conflict (user_id) do nothing;
   ```

8. Repeat steps 6–7 for every additional administrator. Never share the database password or service-role key.

## Step 2 — Publish using a phone

The simplest phone-first route is Vercel Drop:

1. Extract the ZIP on your phone only if your browser's upload picker cannot select the ZIP directly. Vercel Drop accepts a website project upload; use the project folder contents, not a ZIP that contains an extra parent folder level.
2. Open [Vercel Drop](https://vercel.com/drop) and sign in/create a Vercel account.
3. Upload the project folder (or its ZIP if the Drop page accepts it), then follow the deployment prompts.
4. Wait for Vercel to finish. It will provide a public `*.vercel.app` link. Open that link on another phone or in a private browser to confirm the public view works.
5. If you change website files later, deploy the updated project again. For ongoing development, connecting a GitHub repository to Vercel is more convenient because pushes can trigger deployments automatically.

Official deployment references: [Vercel Drop](https://vercel.com/drop) · [Vercel Git deployment guide](https://vercel.com/docs/git).

## Step 3 — Connect your custom domain (optional)

1. First confirm whether `stcceapsupercup.com` is registered to you. A domain being registered does not prove you own it; sign in to the registrar account where it was purchased.
2. In Vercel, open the deployed project → **Settings → Domains** → add `stcceapsupercup.com` (and optionally `www.stcceapsupercup.com`).
3. Vercel will show the exact DNS records required. Sign in to your domain registrar and add those records exactly as shown. DNS changes can take time to propagate.
4. Wait until Vercel verifies the domain and provisions HTTPS. Keep the Vercel deployment URL as a fallback.

If you have not purchased the domain, purchase it through a registrar first. Do not enter DNS records copied from another website or guessed from a tutorial; use the exact values Vercel displays for your project.

## Step 4 — First-use checklist

- Sign in through **Admin Login**.
- Add the 14 real teams and their coaches. Do not add dummy teams.
- Create the bracket. If using the automatic draw, review the two byes and all pairings before publishing.
- Edit fixtures to assign the correct dates, kick-off times and bye teams.
- Add each team's players before recording match events so their player IDs are available in the event editor.
- Test one fixture and one goal event, then open the public site on a second device to confirm that the data syncs.
- Download a JSON backup before the tournament and after each match day.
- Confirm the final schedule with ground availability. The sample date allocation is not a confirmed timetable.

## Preview without cloud setup

The site can be opened through a local static server for a visual preview. Without Supabase credentials, local edits stay in that browser's local storage and are not shared. Do not use local preview mode for the live tournament.

## Security

Only the Supabase publishable/anon key belongs in `config.js`. Never put a service-role key, database password, or private API key in browser files or upload them to GitHub/Vercel. RLS rules in `supabase/schema.sql` make tournament data publicly readable and restrict edits/uploads to user IDs granted in `admin_users`.

# Pokédex Daily App

A Pokémon-themed family reward app for Mason, with five daily missions, weekly Gym Badges, and savings toward adventures.

**Live app:** https://mason-trainer-adventure.vercel.app

## Rewards

- Each complete mission earns one point: up to 5 per day and 35 per week.
- 25 weekly points unlock a small Target toy and a Gym Badge. This does not spend bank points.
- Adventure rewards cost 100, 200, or 300 bank points.
- Earned points never expire or get removed.

## Features

- Detailed morning, learning, unpacking, home-care, and bedtime checklists.
- Shorter routines for weekends and school breaks.
- Parent dashboard with daily/weekly scores, a 14-day mission breakdown, and reward history.
- Family sync using Supabase password or email-link sign-in and row-level security.
- Local backup export/import and offline changes queued for sync.

## Run locally

No build step or npm install is needed. Use Python 3:

```sh
python3 -m http.server 3000 --directory dist
```

Open http://localhost:3000. Device-only tracking works without signing in. The hosted app uses the configured production return URL for email sign-in.

## Project layout

- `dist/index.html`: app shell
- `dist/app.js`: daily missions, points, badges, and rewards
- `dist/cloud.js`: Supabase authentication, family sync, and Parent dashboard
- `dist/style.css`: responsive styles
- `dist/supabase-2.49.8.js`: pinned browser library
- `database/mason_trainer_shared_progress.sql`: initial schema, policies, and scoring triggers
- `tests/points.cjs`: core scoring checks
- `vercel.json`: static hosting configuration

## Supabase

The existing `educational-materials` project is reused; no additional database was provisioned. The five `mason_trainer_*` tables are isolated from the project's existing application tables.

The browser uses a **publishable** key, intended to be public. Authorization is enforced by row-level security, with each signed-in user restricted to their own family records. Never add service-role keys, database passwords, session tokens, or private backups to this repository.

For another Supabase project, apply the initial SQL once to a project without these tables, then replace the project URL and publishable key in `dist/cloud.js`. Do not reapply the initial schema to the configured project; it is already installed.

In Authentication → URL Configuration, add the exact redirect URL:

```
https://mason-trainer-adventure.vercel.app/
```

`AUTH_RETURN_URL` in `cloud.js` must match this allowed URL. The app explicitly requests it, so the shared project's default Site URL does not need to change. Email links are single-use: request a fresh email if a link expires or was already opened.

Use the same parent email on both devices. Parent and Trainer views currently share family access; this is not a separate child account or a protected parent role.

## Vercel

Import this repository using the **Other** framework preset, no build command, and `dist` as the output directory. `vercel.json` also declares the static output directory. The current live project was deployed through the Vercel API; pushing to this repository alone does not enable automatic deployments until its Git integration is connected.

## Checks

```sh
node --check dist/app.js
node --check dist/cloud.js
node tests/points.cjs
```

Database checks verified per-user isolation, blocked cross-family writes, and rejected overspending. The email sign-in flow requires a real inbox to complete end-to-end.

## Credits

Pokémon names and imagery are used for a personal fan project. The repository's application license does not grant rights to Pokémon trademarks or third-party assets. Supabase JS retains its upstream MIT license in `THIRD_PARTY_NOTICES.md`.

## Connecting an iPad when email sending is limited

On a device already signed in to the app, open **Family connection → Set or change account password**. Choose and confirm a password yourself. On the iPad, use **Set up family sync → Sign in with password** with the same parent email. Existing account passwords also work. This changes the Auth account password for any apps sharing that account in this Supabase project; it does not change the dashboard password. No password is stored in app data or this repository.

Email rate-limit responses pause the app’s email button for one hour on that browser as a conservative backoff. This is not a guaranteed server reset time. Password sign-in remains available, and the original email limit is not changed. If no device is signed in and no password is set, wait for email delivery to recover before completing initial sign-in.

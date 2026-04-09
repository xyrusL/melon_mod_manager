# Melon Mod Manager Website

This folder contains the website for Melon Mod Manager.

The website is here to support the desktop app. It gives people a simple place to learn what the app does, check its features, and find download or project links.

## What Melon Mod Manager Is

Melon Mod Manager is a desktop app for Minecraft players.

It helps people manage:

- mods
- shader packs
- resource packs

The app is built to make setup easier. You can browse content, install files, track updates, and keep your Minecraft folders tidy without doing everything by hand.

## What This Website Is For

The website is the public face of the project.

It is meant to:

- show what the app does
- explain why people may want to use it
- guide visitors to downloads and project links
- give the project a cleaner home on the web

## Project Structure

This repository has two parts:

- repo root: the Flutter desktop app
- `web/`: the Next.js website

They live in one repo, but they are deployed separately.

## Run The Website Locally

```bash
cd web
npm install
npm run dev
```

Use Node 20 or Node 22 LTS for local work.

Node 25 can break this app at startup with a `localStorage.getItem is not a function` error.

## Build The Website

```bash
cd web
npm run build
npm run start
```

## Deploy On Vercel

Set the Vercel project Root Directory to `web`.

Use these settings:

- Framework Preset: `Next.js`
- Root Directory: `web`
- Install Command: `npm install`
- Build Command: `npm run build`
- Output Directory: leave empty

If Vercel says `Could not identify Next.js version` or `No Next.js version detected`, it is usually looking at the repo root instead of `web`.

Do not use the repository root as the deploy target for the website. The repo root is the Flutter desktop app. The only supported Vercel setup for the website is to point the project Root Directory to `web`.

## Troubleshooting

Because this repository contains two separate apps, most deployment problems happen when the host reads the wrong one:

- repo root: Flutter desktop app
- `web/`: Next.js website

If local development works with `cd web` and `npm run dev`, but the deployed site fails, check the points below.

### Common Problems

#### Vercel shows `404: NOT_FOUND`

This usually means Vercel is not serving the Next.js site from `web/`.

Check these first:

- the Vercel project is connected to the correct repository
- the project Root Directory is `web`
- the latest deployment is the active production deployment
- the domain is attached to the correct Vercel project

If you imported the repository from the repo root, change the Root Directory to `web` in the Vercel dashboard and redeploy.

#### Vercel says it cannot detect Next.js

That usually means Vercel is reading the Flutter app at the repo root instead of the website in `web/`.

Fix:

- set Framework Preset to `Next.js`
- set Root Directory to `web`
- keep Output Directory empty
- redeploy

#### Local works but production build fails

Run the production build from inside `web`:

```bash
cd web
npm run build
```

If that fails locally, fix that error first before redeploying.

If it succeeds locally but fails on Vercel, compare:

- Node version used locally and on Vercel
- Vercel Root Directory
- install and build commands

#### Node version issues

Use Node 20 or Node 22 LTS.

Node 25 may break startup with:

```text
localStorage.getItem is not a function
```

### Quick Deployment Checklist

Before deploying, verify:

- you are deploying the website, not the Flutter desktop app
- the Vercel Root Directory is `web`
- `web/package.json` is the package file Vercel is using
- `npm run build` works inside `web`
- the production domain points to the correct Vercel project

### Helpful Commands

Local development:

```bash
cd web
npm run dev
```

Production check:

```bash
cd web
npm run build
npm run start
```

## Why The Website Is Separate

The desktop app and the website do different jobs.

Keeping them separate makes it easier to:

- deploy the website on Vercel
- keep desktop-only code out of the website
- shape the site for product info, downloads, and search visibility

## Quick Links

- Main project repo: [melon_mod_manager](https://github.com/xyrusL/melon_mod_manager)
- Releases: [GitHub Releases](https://github.com/xyrusL/melon_mod_manager/releases)
- Issues: [GitHub Issues](https://github.com/xyrusL/melon_mod_manager/issues)
- Modrinth: [modrinth.com](https://modrinth.com)

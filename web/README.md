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

# Melon Mod Manager Website

🌐 Marketing site for **Melon Mod Manager**, the desktop app for managing Minecraft mods, shader packs, and resource packs.

## ✨ What This Folder Is

- `web/` contains the Next.js website
- repo root contains the Flutter desktop app
- both live in one repository, but they deploy separately

## 🍉 What The Site Covers

- app overview and screenshots
- feature highlights
- download and project links
- search-friendly public landing page for the product

## 🛠 Run Locally

```bash
cd web
npm install
npm run dev
```

Use Node `20` or `22` LTS.

Avoid Node `25`. It can fail at startup with:

```text
localStorage.getItem is not a function
```

## 📦 Build For Production

```bash
cd web
npm run build
npm run start
```

## 🚀 Deploy On Vercel

Set the Vercel project **Root Directory** to `web`.

Recommended settings:

- Framework Preset: `Next.js`
- Root Directory: `web`
- Install Command: `npm install`
- Build Command: `npm run build`
- Output Directory: leave empty

If Vercel says it cannot detect Next.js, it is usually reading the repo root instead of `web/`.

## ✅ Quick Deployment Check

- deploy the website from `web`, not the Flutter app root
- confirm Vercel Root Directory is `web`
- confirm `web/package.json` is the file Vercel uses
- run `npm run build` inside `web` before redeploying
- make sure the production domain points to the correct Vercel project

## 🧯 Troubleshooting

If local works but production fails, compare:

- Node version
- Vercel Root Directory
- install and build commands

If Vercel shows `404: NOT_FOUND`, the project is usually serving the wrong folder or the wrong deployment.

## 🔗 Quick Links

- GitHub repo: [melon_mod_manager](https://github.com/xyrusL/melon_mod_manager)
- Releases: [GitHub Releases](https://github.com/xyrusL/melon_mod_manager/releases)
- Issues: [GitHub Issues](https://github.com/xyrusL/melon_mod_manager/issues)
- Modrinth: [modrinth.com](https://modrinth.com)

# Website

This folder contains the public website for Melon Mod Manager.

## Why It Lives Here

The desktop app and the website share one repository, but they are deployed separately:

- repo root: Flutter desktop application
- `web/`: Next.js website for Vercel or other web hosts

## Local Development

```bash
cd web
npm install
npm run dev
```

Use Node 20 or Node 22 LTS for local development. Node 25 currently breaks this Next.js app at startup with a `localStorage.getItem is not a function` error.

If `nvm use 22.22.0` still shows Node 25 when you run `node -v`, your PATH is prioritizing `C:\Program Files\nodejs` over nvm. This project scripts already pass a valid `--localstorage-file` option to avoid the crash, but fixing PATH order is still recommended.

## Hosting

### Vercel

The repo root includes `vercel.json`, so Vercel installs and builds only `web/`.

### Other Hosts

If a host needs manual commands:

- install: `cd web && npm install`
- build: `cd web && npm run build`
- start: `cd web && npm run start`

## Why Not Reuse The Flutter App Directly

You can build a Flutter web target, but for a public product site this setup is usually cleaner:

- better Vercel support
- clearer separation from desktop-only Flutter code
- easier marketing and SEO customization

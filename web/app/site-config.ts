export const siteName = "Melon Mod Manager";
export const siteTagline = "Desktop Minecraft Mod Manager";
export const siteDescription =
  "Manage Minecraft mods, shaders, and resource packs from one desktop app with Modrinth search, dependency-aware installs, updates, and bundle tools.";

export const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const siteLinks = {
  home: "/",
  image: "/download_mod.png",
  icon: "/favicon.ico",
  svgIcon: "/melon_logo.svg",
} as const;

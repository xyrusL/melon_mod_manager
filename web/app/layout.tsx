import type { Metadata } from "next";
import "./globals.css";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000");

export const metadata: Metadata = {
  title: "Melon Mod Manager | Desktop Minecraft Mod Manager",
  description:
    "Manage Minecraft mods, shaders, and resource packs from one desktop app with Modrinth search, dependency-aware installs, updates, and bundle tools.",
  metadataBase: new URL(siteUrl),
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/melon_logo.svg", type: "image/svg+xml" },
    ],
    shortcut: ["/favicon.ico"],
    apple: ["/melon_logo.svg"],
  },
  openGraph: {
    title: "Melon Mod Manager",
    description:
      "Desktop mod management for Minecraft with Modrinth search, updates, dependency handling, and content import/export.",
    images: ["/download_mod.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}

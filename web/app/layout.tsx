import type { Metadata } from "next";
import "./globals.css";
import {
  siteDescription,
  siteLinks,
  siteName,
  siteTagline,
  siteUrl,
} from "./site-config";

export const metadata: Metadata = {
  title: {
    default: `${siteName} | ${siteTagline}`,
    template: `%s | ${siteName}`,
  },
  description: siteDescription,
  metadataBase: new URL(siteUrl),
  applicationName: siteName,
  alternates: {
    canonical: "/",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  icons: {
    icon: [
      { url: siteLinks.icon, sizes: "any" },
      { url: siteLinks.svgIcon, type: "image/svg+xml" },
    ],
    shortcut: [siteLinks.icon],
    apple: [siteLinks.svgIcon],
  },
  manifest: "/manifest.webmanifest",
  openGraph: {
    type: "website",
    url: "/",
    siteName,
    title: `${siteName} | ${siteTagline}`,
    description: siteDescription,
    images: [
      {
        url: siteLinks.image,
        alt: `${siteName} app preview`,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: `${siteName} | ${siteTagline}`,
    description: siteDescription,
    images: [siteLinks.image],
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

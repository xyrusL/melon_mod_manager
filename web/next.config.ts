import type { NextConfig } from "next";
import { getWebsiteSchemaCspHash } from "./app/structured-data";

const allowedDevOrigins = [
  "localhost",
  "127.0.0.1",
  "192.168.1.61",
];

const isDevelopment = process.env.NODE_ENV !== "production";

const contentSecurityPolicy = [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "frame-ancestors 'none'",
  "form-action 'self'",
  "img-src 'self' data: https:",
  "font-src 'self' data:",
  `script-src 'self' 'sha256-${getWebsiteSchemaCspHash()}'${isDevelopment ? " 'unsafe-eval'" : ""}`,
  "style-src 'self' 'unsafe-inline'",
  "connect-src 'self'",
  "manifest-src 'self'",
  "worker-src 'self' blob:",
  "upgrade-insecure-requests",
].join("; ");

if (process.env.ALLOWED_DEV_ORIGIN) {
  allowedDevOrigins.push(process.env.ALLOWED_DEV_ORIGIN);
}

const nextConfig = (): NextConfig => ({
  reactStrictMode: true,
  allowedDevOrigins,
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [
          {
            key: "Content-Security-Policy",
            value: contentSecurityPolicy,
          },
          {
            key: "Permissions-Policy",
            value:
              "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()",
          },
          {
            key: "Referrer-Policy",
            value: "strict-origin-when-cross-origin",
          },
          {
            key: "X-Content-Type-Options",
            value: "nosniff",
          },
          {
            key: "X-Frame-Options",
            value: "DENY",
          },
        ],
      },
    ];
  },
  // Keep dev and production artifacts separate so restarts do not reuse
  // stale chunk/runtime output across `next dev` and `next build`.
  distDir: process.env.NODE_ENV === "development" ? ".next-dev" : ".next",
});

export default nextConfig;

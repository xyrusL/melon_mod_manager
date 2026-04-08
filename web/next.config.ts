import type { NextConfig } from "next";

const allowedDevOrigins = [
  "localhost",
  "127.0.0.1",
  "192.168.1.61",
];

if (process.env.ALLOWED_DEV_ORIGIN) {
  allowedDevOrigins.push(process.env.ALLOWED_DEV_ORIGIN);
}

const nextConfig = (): NextConfig => ({
  reactStrictMode: true,
  allowedDevOrigins,
  // Keep dev and production artifacts separate so restarts do not reuse
  // stale chunk/runtime output across `next dev` and `next build`.
  distDir: process.env.NODE_ENV === "development" ? ".next-dev" : ".next",
});

export default nextConfig;

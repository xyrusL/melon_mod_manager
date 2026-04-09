import type { MetadataRoute } from "next";
import { siteDescription, siteName } from "./site-config";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: siteName,
    short_name: "Melon",
    description: siteDescription,
    start_url: "/",
    display: "standalone",
    background_color: "#101512",
    theme_color: "#9de06f",
    icons: [
      {
        src: "/favicon.ico",
        sizes: "48x48",
        type: "image/x-icon",
      },
      {
        src: "/melon_logo.svg",
        sizes: "any",
        type: "image/svg+xml",
      },
    ],
  };
}

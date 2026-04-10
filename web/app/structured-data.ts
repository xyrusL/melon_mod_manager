import { createHash } from "node:crypto";
import { siteDescription, siteName, siteUrl } from "./site-config";

export function getWebsiteSchemaJsonLd() {
  return JSON.stringify({
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: siteName,
    alternateName: "Melon",
    url: siteUrl,
    description: siteDescription,
  });
}

export function getWebsiteSchemaCspHash() {
  return createHash("sha256")
    .update(getWebsiteSchemaJsonLd())
    .digest("base64");
}

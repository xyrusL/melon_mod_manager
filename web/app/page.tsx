import Image from "next/image";
import type { LucideIcon } from "lucide-react";
import {
  ArrowUpRight,
  Archive,
  Boxes,
  Download,
  FolderInput,
  PackageSearch,
  RefreshCw,
  Search,
  ShieldCheck,
  Sparkles,
  Upload,
} from "lucide-react";

type IconType = LucideIcon;

type AccentCard = {
  toneClassName: string;
  iconClassName: string;
};

type QuickLink = {
  label: string;
  href: string;
  icon: IconType;
  blurb: string;
  cardClassName: string;
  iconClassName: string;
};

const quickStats = [
  { value: "4", label: "loaders supported" },
  { value: "3", label: "content types in one library" },
  { value: "2", label: "desktop platforms supported" },
];

const heroSignals = [
  "Modrinth search inside the app",
  "Drag-and-drop `.jar` and `.zip` installs",
  "Tracked updates for Modrinth-backed content",
  "Import, export, and rebuild local metadata",
];

const contentTypes: Array<{
  title: string;
  subtitle: string;
  text: string;
  points: string[];
  icon: IconType;
} & AccentCard> = [
  {
    title: "Mods",
    subtitle: ".jar files and Modrinth projects",
    text: "Search Modrinth, add local jars, preview required dependencies, and keep tracked mod installs easier to review later.",
    points: [
      "Loader-aware install context",
      "Dependency preview before install",
      "Tracked and external items in one list",
    ],
    icon: Boxes,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(124,233,181,0.12),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#69d1a4]/28 bg-[#69d1a4]/12 text-[#97ebc4]",
  },
  {
    title: "Shader packs",
    subtitle: ".zip packs in the correct folder",
    text: "Download compatible shader packs from Modrinth or drop local zip files straight into the app without juggling folders by hand.",
    points: [
      "Search and install from Modrinth",
      "Local zip import by drag-and-drop",
      "Update checks for tracked items",
    ],
    icon: Sparkles,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(110,198,255,0.12),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#6ebef4]/28 bg-[#6ebef4]/12 text-[#a4d9ff]",
  },
  {
    title: "Resource packs",
    subtitle: "Managed alongside the rest of your setup",
    text: "Keep resource packs in the same flow as mods and shaders instead of bouncing between launchers and file explorers.",
    points: [
      "Shared library and update flow",
      "Bundle import and export support",
      "Metadata rebuild when local data drifts",
    ],
    icon: Archive,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(245,196,108,0.14),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#f1bd67]/28 bg-[#f1bd67]/12 text-[#ffd88f]",
  },
];

const workflowSteps: Array<{
  step: string;
  title: string;
  text: string;
  icon: IconType;
} & AccentCard> = [
  {
    step: "01",
    title: "Detect the setup you already use",
    text: "Point Melon at your Minecraft folder and it helps detect a supported loader, game version, and the right content path before you start changing files.",
    icon: Search,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(124,233,181,0.1),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#69d1a4]/28 bg-[#69d1a4]/12 text-[#97ebc4]",
  },
  {
    step: "02",
    title: "Browse Modrinth or add local files",
    text: "Use the built-in Modrinth dialog for downloads or drag local `.jar` and `.zip` files into the app with the correct destination already in context.",
    icon: PackageSearch,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(110,198,255,0.1),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#6ebef4]/28 bg-[#6ebef4]/12 text-[#a4d9ff]",
  },
  {
    step: "03",
    title: "Review updates and install with more context",
    text: "Check tracked content for compatible updates, preview dependency requirements, and keep a clearer split between Modrinth installs and manually added files.",
    icon: Download,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(245,196,108,0.1),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#f1bd67]/28 bg-[#f1bd67]/12 text-[#ffd88f]",
  },
  {
    step: "04",
    title: "Import, export, and recover the library",
    text: "Package content into zip bundles, import packs back in, rebuild local metadata, and export error details when you need to troubleshoot.",
    icon: Upload,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(184,142,255,0.12),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#b28cff]/28 bg-[#b28cff]/12 text-[#d6c1ff]",
  },
];

const toolkitCards: Array<{
  title: string;
  text: string;
  icon: IconType;
} & AccentCard> = [
  {
    title: "Dependency-aware installs",
    text: "Preview and resolve required Modrinth dependencies before they turn into broken setups.",
    icon: Boxes,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(124,233,181,0.11),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#69d1a4]/28 bg-[#69d1a4]/12 text-[#97ebc4]",
  },
  {
    title: "Local file intake",
    text: "Add `.jar` and `.zip` files with drag-and-drop or the file picker instead of sorting folders manually.",
    icon: FolderInput,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(110,198,255,0.11),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#6ebef4]/28 bg-[#6ebef4]/12 text-[#a4d9ff]",
  },
  {
    title: "Tracked vs external visibility",
    text: "See what came from Modrinth, what was added manually, and what can be updated.",
    icon: ShieldCheck,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(255,193,110,0.12),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#f1bd67]/28 bg-[#f1bd67]/12 text-[#ffd88f]",
  },
  {
    title: "Content update review",
    text: "Check compatible updates for mods, shader packs, and resource packs from the same app workflow.",
    icon: RefreshCw,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(182,142,255,0.12),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#b28cff]/28 bg-[#b28cff]/12 text-[#d6c1ff]",
  },
  {
    title: "Bundle import and export",
    text: "Create zip bundles for backup, migration, or sharing, then import them back into the right content area.",
    icon: Archive,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(245,118,184,0.11),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#f08cc2]/28 bg-[#f08cc2]/12 text-[#ffc2e0]",
  },
  {
    title: "Metadata rebuild tools",
    text: "Refresh local caches and rebuild metadata when you need to clean up a library or recover from stale local state.",
    icon: Sparkles,
    toneClassName:
      "bg-[linear-gradient(180deg,rgba(111,229,219,0.11),rgba(255,255,255,0.02))]",
    iconClassName:
      "border-[#71d7cf]/28 bg-[#71d7cf]/12 text-[#9af1eb]",
  },
];

const trustFacts = [
  "Windows 10/11 (64-bit) and Linux (x64)",
  "Fabric, Quilt, Forge, and NeoForge support",
  "Internet required for Modrinth browsing and downloads",
  "Open-source code and release downloads on GitHub",
];

const quickLinks: QuickLink[] = [
  {
    label: "Download releases",
    href: "https://github.com/xyrusL/melon_mod_manager/releases",
    icon: Download,
    blurb: "Grab the latest build and changelog.",
    cardClassName:
      "bg-[linear-gradient(180deg,rgba(139,217,183,0.12),rgba(255,255,255,0.02))] hover:border-[#69d1a4]/45",
    iconClassName:
      "border-[#69d1a4]/30 bg-[#69d1a4]/12 text-[#8be2b8]",
  },
  {
    label: "View repository",
    href: "https://github.com/xyrusL/melon_mod_manager",
    icon: ArrowUpRight,
    blurb: "Look through the code or build it yourself.",
    cardClassName:
      "bg-[linear-gradient(180deg,rgba(120,192,255,0.12),rgba(255,255,255,0.02))] hover:border-[#73b7f6]/45",
    iconClassName:
      "border-[#73b7f6]/30 bg-[#73b7f6]/12 text-[#9aceff]",
  },
  {
    label: "Report an issue",
    href: "https://github.com/xyrusL/melon_mod_manager/issues",
    icon: ArrowUpRight,
    blurb: "Share a bug or suggest an improvement.",
    cardClassName:
      "bg-[linear-gradient(180deg,rgba(255,193,110,0.14),rgba(255,255,255,0.02))] hover:border-[#f1bd67]/45",
    iconClassName:
      "border-[#f1bd67]/30 bg-[#f1bd67]/12 text-[#ffd48a]",
  },
  {
    label: "Browse Modrinth",
    href: "https://modrinth.com",
    icon: PackageSearch,
    blurb: "See what packs and mods are available.",
    cardClassName:
      "bg-[linear-gradient(180deg,rgba(182,142,255,0.14),rgba(255,255,255,0.02))] hover:border-[#b28cff]/45",
    iconClassName:
      "border-[#b28cff]/30 bg-[#b28cff]/12 text-[#d0b7ff]",
  },
];

function SectionEyebrow({ children }: { children: React.ReactNode }) {
  return (
    <p className="font-body text-[0.72rem] font-bold uppercase tracking-[0.22em] text-app-rind">
      {children}
    </p>
  );
}

function ExternalLink({
  href,
  className,
  children,
}: {
  href: string;
  className: string;
  children: React.ReactNode;
}) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className={className}
    >
      {children}
    </a>
  );
}

function SectionHeader({
  eyebrow,
  title,
  copy,
}: {
  eyebrow: string;
  title: string;
  copy?: string;
}) {
  return (
    <div className="grid gap-4 xl:grid-cols-[minmax(0,0.82fr)_minmax(0,0.95fr)] xl:items-end">
      <div className="grid gap-4">
        <SectionEyebrow>{eyebrow}</SectionEyebrow>
        <h2 className="max-w-[18ch] font-body text-[clamp(1.5rem,2.25vw,2.2rem)] font-semibold leading-[1.08] tracking-[-0.03em] text-app-text">
          {title}
        </h2>
      </div>
      {copy ? (
        <p className="max-w-[34rem] font-body text-[0.98rem] leading-7 text-app-muted lg:justify-self-end">
          {copy}
        </p>
      ) : null}
    </div>
  );
}

export default function Home() {
  return (
    <main className="relative mx-auto flex w-[min(1440px,calc(100%-28px))] flex-col gap-5 px-1 py-5 sm:w-[min(1440px,calc(100%-40px))] sm:px-2 md:w-[min(1440px,calc(100%-72px))] md:px-3 md:py-7 xl:w-[min(1440px,calc(100%-96px))]">
      <section className="glass-panel reveal reveal-delay-1 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <div className="grid items-start gap-5 xl:grid-cols-[minmax(0,0.9fr)_minmax(560px,1.1fr)] 2xl:grid-cols-[minmax(0,0.92fr)_minmax(700px,1.08fr)]">
          <div>
            <div className="inline-flex items-center gap-3 rounded-full border border-app-line bg-white/5 px-4 py-2.5 font-body text-[0.92rem] font-bold tracking-[0.04em] text-app-text shadow-[0_0_0_1px_var(--color-app-rind-soft)]">
              <Image
                src="/melon_logo.svg"
                alt="Melon Mod Manager logo"
                width={38}
                height={38}
                priority
              />
              <span>Melon Mod Manager</span>
            </div>

            <div className="mt-6 grid gap-4">
              <SectionEyebrow>Desktop manager for Minecraft content</SectionEyebrow>
              <h1 className="max-w-[10.4ch] font-body text-[clamp(2.35rem,4vw,4.05rem)] font-semibold leading-[0.92] tracking-[-0.055em] text-app-text">
                Manage mods, shaders, and packs without the folder mess.
              </h1>
              <p className="max-w-[33rem] font-body text-[1rem] leading-7 text-app-muted">
                Melon helps you find the right content path, browse Modrinth,
                add local `.jar` and `.zip` files, review updates, and keep
                bundle archives tidy in one place.
              </p>
            </div>

            <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              <ExternalLink
                className="cta-pulse inline-flex min-h-14 items-center justify-center gap-2 rounded-full bg-[linear-gradient(135deg,var(--accent),var(--color-app-rind),#d7f38f)] px-6 font-body text-[0.98rem] font-bold text-[#0c1f19] transition-transform duration-150 hover:-translate-y-0.5"
                href="https://github.com/xyrusL/melon_mod_manager/releases"
              >
                <Download className="h-4 w-4" />
                Download the app
              </ExternalLink>
              <ExternalLink
                className="inline-flex min-h-14 items-center justify-center gap-2 rounded-full border border-app-line bg-white/4 px-6 font-body text-[0.98rem] font-bold text-app-text transition-transform duration-150 hover:-translate-y-0.5"
                href="https://github.com/xyrusL/melon_mod_manager"
              >
                <ArrowUpRight className="h-4 w-4" />
                View repository
              </ExternalLink>
            </div>
          </div>

          <div className="grid gap-4">
            <div className="inline-flex w-fit rounded-full border border-[var(--color-app-accent-soft)] bg-[linear-gradient(135deg,var(--color-app-accent-soft),var(--color-app-rind-soft))] px-3 py-2 font-body text-[0.76rem] font-bold uppercase tracking-[0.16em] text-app-sand">
              Made for modded Minecraft setups
            </div>

            <div className="overflow-hidden rounded-[24px] border border-app-line-strong bg-app-bg-soft shadow-[0_16px_44px_rgba(0,0,0,0.24)]">
              <div className="aspect-[1.65/1] xl:aspect-[1.56/1]">
                <Image
                  src="/download_mod.png"
                  alt="Melon Mod Manager screenshot showing the Modrinth download dialog"
                  width={1096}
                  height={730}
                  priority
                  className="h-full w-full object-cover object-top"
                />
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-3">
              <div className="rounded-[20px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(139,217,183,0.08))] p-4">
                <SectionEyebrow>Detect setup</SectionEyebrow>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  Loader-aware path detection helps point installs to the right
                  folder first.
                </p>
              </div>
              <div className="rounded-[20px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(157,224,111,0.05))] p-4">
                <SectionEyebrow>Track sources</SectionEyebrow>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  Keep Modrinth installs and manually added files in one
                  library view.
                </p>
              </div>
              <div className="rounded-[20px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(239,249,216,0.08))] p-4">
                <SectionEyebrow>Repair local data</SectionEyebrow>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  Rebuild metadata and refresh caches when local state gets
                  messy.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {heroSignals.map((signal) => (
            <div
              key={signal}
              className="rounded-[18px] border border-app-line bg-white/[0.045] px-4 py-3 font-body text-[0.95rem] leading-6 text-app-sand"
            >
              {signal}
            </div>
          ))}
        </div>

        <div className="mt-3 grid gap-3 sm:grid-cols-3" aria-label="Melon Mod Manager summary">
          {quickStats.map((stat) => (
            <article
              key={stat.label}
              className="rounded-[20px] border border-app-line bg-white/[0.045] px-5 py-4"
            >
              <div className="flex items-baseline gap-3">
                <strong className="text-[clamp(1.45rem,2.2vw,2rem)] leading-none text-app-sand">
                  {stat.value}
                </strong>
                <span className="font-body text-[0.98rem] leading-6 text-app-muted">
                  {stat.label}
                </span>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="glass-panel reveal reveal-delay-2 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <SectionHeader
          eyebrow="What Melon manages"
          title="Manage mods, shader packs, and resource packs in one place."
          copy="Keep your library together so installs, updates, and clean-up feel simple instead of scattered across different folders and launchers."
        />

        <div className="mt-6 grid gap-4 xl:grid-cols-3">
          {contentTypes.map((type) => {
            const Icon = type.icon;

            return (
              <article
                key={type.title}
                className={`glass-panel flex h-full flex-col rounded-[26px] border border-app-line p-6 ${type.toneClassName}`}
              >
                <div className="flex items-start justify-between gap-4">
                  <div className={`inline-flex rounded-2xl border p-3 ${type.iconClassName}`}>
                    <Icon className="h-5 w-5" />
                  </div>
                  <span className="rounded-full border border-app-line bg-white/4 px-3 py-1.5 font-body text-[0.72rem] uppercase tracking-[0.14em] text-app-muted">
                    {type.subtitle}
                  </span>
                </div>

                <h3 className="mt-5 font-body text-[clamp(1.55rem,2.2vw,2rem)] font-semibold leading-[1.02] text-app-text">
                  {type.title}
                </h3>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  {type.text}
                </p>

                <div className="mt-5 grid gap-2">
                  {type.points.map((point) => (
                    <div
                      key={point}
                      className="rounded-[16px] border border-app-line bg-white/[0.045] px-4 py-3 font-body text-[0.95rem] leading-6 text-app-sand"
                    >
                      {point}
                    </div>
                  ))}
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="glass-panel reveal reveal-delay-3 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <SectionHeader
          eyebrow="Why people keep it installed"
          title="Helpful desktop tools for everyday mod setup."
          copy="Downloads, imports, updates, and clean-up tools stay together, so managing a library feels easier from day one."
        />

        <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {toolkitCards.map((card) => {
            const Icon = card.icon;

            return (
              <article
                key={card.title}
                className={`rounded-[24px] border border-app-line p-5 ${card.toneClassName}`}
              >
                <div className={`inline-flex rounded-2xl border p-3 ${card.iconClassName}`}>
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="mt-4 font-body text-[1.45rem] font-semibold leading-[1.08] text-app-text">
                  {card.title}
                </h3>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  {card.text}
                </p>
              </article>
            );
          })}
        </div>
      </section>

      <section className="glass-panel reveal reveal-delay-2 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <SectionHeader
          eyebrow="How the app works"
          title="Four steps from setup to maintenance."
          copy="Start by finding your game folder, add what you want, then come back later for updates, exports, and quick fixes."
        />

        <div className="mt-6 grid gap-4 xl:grid-cols-2">
          {workflowSteps.map((step) => {
            const Icon = step.icon;

            return (
              <article
                key={step.step}
                className={`glass-panel flex h-full flex-col rounded-[28px] border border-app-line p-6 ${step.toneClassName}`}
              >
                <div className="flex items-start justify-between gap-4">
                  <span className={`inline-flex h-14 w-14 items-center justify-center rounded-full border font-body text-[0.88rem] font-bold tracking-[0.12em] ${step.iconClassName}`}>
                    {step.step}
                  </span>
                  <div className={`rounded-2xl border p-3 ${step.iconClassName}`}>
                    <Icon className="h-5 w-5" />
                  </div>
                </div>
                <h3 className="mt-5 max-w-[18ch] font-body text-[clamp(1.5rem,2.4vw,2.1rem)] font-semibold leading-[1.04] text-app-text">
                  {step.title}
                </h3>
                <p className="mt-3 font-body leading-7 text-app-muted">
                  {step.text}
                </p>
              </article>
            );
          })}
        </div>
      </section>

      <section className="glass-panel reveal reveal-delay-3 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <SectionHeader
          eyebrow="Compatibility and trust"
          title="Built for common setups and easy to verify."
          copy="Melon is open source, with releases on GitHub. You can read the code, build it yourself, or compare release files before installing."
        />

        <div className="mt-6 grid gap-5 xl:grid-cols-[minmax(0,0.92fr)_minmax(0,1.08fr)]">
          <div className="grid gap-4">
            <div className="rounded-[24px] border border-app-line bg-white/[0.04] p-5">
              <h3 className="font-body text-[1.5rem] font-semibold leading-[1.08] text-app-text">
                Why antivirus warnings may appear
              </h3>
              <p className="mt-3 font-body leading-7 text-app-muted">
                Small unsigned desktop apps can sometimes trigger false
                positives. That is why it helps to keep the source code and
                release files easy to inspect.
              </p>
            </div>

            <div className="rounded-[24px] border border-app-line bg-white/[0.04] p-5">
              <h3 className="font-body text-[1.5rem] font-semibold leading-[1.08] text-app-text">
                What Melon focuses on
              </h3>
              <p className="mt-3 font-body leading-7 text-app-muted">
                Loader-aware Java mod workflows, support for shader packs and
                resource packs, and straightforward GitHub-based releases.
              </p>
            </div>
          </div>

          <div className="grid gap-3" aria-label="Compatibility summary">
            {trustFacts.map((item) => (
              <div
                key={item}
                className="rounded-[20px] border border-app-line bg-white/[0.04] px-5 py-4"
              >
                <div className="flex items-start gap-3">
                  <span className="mt-1.5 h-3 w-3 rounded-full bg-[radial-gradient(circle_at_35%_35%,#fff5ef,var(--accent)_56%,var(--color-app-rind-strong)_100%)] shadow-[0_0_20px_var(--accent-shadow)]" />
                  <p className="font-body leading-7 text-app-muted">{item}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="glass-panel reveal reveal-delay-3 rounded-[34px] border border-app-line px-6 py-7 md:px-8 md:py-8">
        <SectionHeader
          eyebrow="Get started"
          title="Download Melon and start organizing the library."
          copy="Pick what you want to do next: download the app, check the code, report a bug, or browse content on Modrinth."
        />

        <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {quickLinks.map((link) => {
            const Icon = link.icon;

            return (
              <ExternalLink
                key={link.label}
                href={link.href}
                className={`group flex min-h-[170px] flex-col justify-between rounded-[22px] border border-app-line p-5 transition duration-150 hover:-translate-y-0.5 ${link.cardClassName}`}
              >
                <div className="flex items-start justify-between gap-4">
                  <span className="font-body text-sm font-semibold uppercase tracking-[0.12em] text-app-sand">
                    {link.label}
                  </span>
                  <div className={`rounded-xl border p-2 transition-transform duration-150 group-hover:translate-x-0.5 ${link.iconClassName}`}>
                    <Icon className="h-4 w-4" />
                  </div>
                </div>
                <p className="max-w-[22ch] font-body text-[1rem] leading-7 text-app-muted">
                  {link.blurb}
                </p>
              </ExternalLink>
            );
          })}
        </div>
      </section>
    </main>
  );
}

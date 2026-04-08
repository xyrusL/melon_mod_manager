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
}> = [
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
  },
  {
    title: "Resource packs",
    subtitle: "Managed alongside the rest of your setup",
    text: "Keep resource packs in the same desktop workflow as mods and shaders instead of splitting work across launchers and file explorers.",
    points: [
      "Shared library and update flow",
      "Bundle import and export support",
      "Metadata rebuild when local data drifts",
    ],
    icon: Archive,
  },
];

const workflowSteps: Array<{
  step: string;
  title: string;
  text: string;
  icon: IconType;
}> = [
  {
    step: "01",
    title: "Detect the setup you already use",
    text: "Point Melon at your Minecraft folder and it helps detect a supported loader, game version, and the right content path before you start changing files.",
    icon: Search,
  },
  {
    step: "02",
    title: "Browse Modrinth or add local files",
    text: "Use the built-in Modrinth dialog for downloads or drag local `.jar` and `.zip` files into the app with the correct destination already in context.",
    icon: PackageSearch,
  },
  {
    step: "03",
    title: "Review updates and install with more context",
    text: "Check tracked content for compatible updates, preview dependency requirements, and keep a clearer split between Modrinth installs and manually added files.",
    icon: Download,
  },
  {
    step: "04",
    title: "Import, export, and recover the library",
    text: "Package content into zip bundles, import packs back in, rebuild local metadata, and export error details when you need to troubleshoot.",
    icon: Upload,
  },
];

const toolkitCards: Array<{
  title: string;
  text: string;
  icon: IconType;
}> = [
  {
    title: "Dependency-aware installs",
    text: "Preview and resolve required Modrinth dependencies before they turn into broken setups.",
    icon: Boxes,
  },
  {
    title: "Local file intake",
    text: "Add `.jar` and `.zip` files with drag-and-drop or the file picker instead of sorting folders manually.",
    icon: FolderInput,
  },
  {
    title: "Tracked vs external visibility",
    text: "See what came from Modrinth, what was added manually, and what can be updated.",
    icon: ShieldCheck,
  },
  {
    title: "Content update review",
    text: "Check compatible updates for mods, shader packs, and resource packs from the same app workflow.",
    icon: RefreshCw,
  },
  {
    title: "Bundle import and export",
    text: "Create zip bundles for backup, migration, or sharing, then import them back into the right content area.",
    icon: Archive,
  },
  {
    title: "Metadata rebuild tools",
    text: "Refresh local caches and rebuild metadata when you need to clean up a library or recover from stale local state.",
    icon: Sparkles,
  },
];

const trustFacts = [
  "Windows 10/11 (64-bit) and Linux (x64)",
  "Fabric, Quilt, Forge, and NeoForge support",
  "Internet required for Modrinth browsing and downloads",
  "Open-source code and release downloads on GitHub",
];

const quickLinks: Array<{
  label: string;
  href: string;
  icon: IconType;
}> = [
  {
    label: "Download releases",
    href: "https://github.com/xyrusL/melon_mod_manager/releases",
    icon: Download,
  },
  {
    label: "View repository",
    href: "https://github.com/xyrusL/melon_mod_manager",
    icon: ArrowUpRight,
  },
  {
    label: "Report an issue",
    href: "https://github.com/xyrusL/melon_mod_manager/issues",
    icon: ArrowUpRight,
  },
  {
    label: "Browse Modrinth",
    href: "https://modrinth.com",
    icon: PackageSearch,
  },
];

function SectionEyebrow({ children }: { children: React.ReactNode }) {
  return (
    <p className="font-body text-[0.72rem] font-bold uppercase tracking-[0.22em] text-app-rind">
      {children}
    </p>
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
              <h1 className="max-w-[10.4ch] text-[clamp(2.35rem,4vw,4.05rem)] leading-[0.92] tracking-[-0.055em] text-app-text">
                Manage mods, shaders, and packs without the folder mess.
              </h1>
              <p className="max-w-[33rem] font-body text-[1rem] leading-7 text-app-muted">
                Melon helps detect the right content path, browse Modrinth, add
                local `.jar` and `.zip` files, review updates, and move bundle
                archives through one app instead of several scattered tools.
              </p>
            </div>

            <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              <a
                className="inline-flex min-h-14 items-center justify-center gap-2 rounded-full bg-[linear-gradient(135deg,var(--accent),#ff8f7b)] px-6 font-body text-[0.98rem] font-bold text-[#2b1012] shadow-[0_18px_38px_var(--accent-shadow)] transition-transform duration-150 hover:-translate-y-0.5"
                href="https://github.com/xyrusL/melon_mod_manager/releases"
              >
                <Download className="h-4 w-4" />
                Download the app
              </a>
              <a
                className="inline-flex min-h-14 items-center justify-center gap-2 rounded-full border border-app-line bg-white/4 px-6 font-body text-[0.98rem] font-bold text-app-text transition-transform duration-150 hover:-translate-y-0.5"
                href="https://github.com/xyrusL/melon_mod_manager"
              >
                <ArrowUpRight className="h-4 w-4" />
                View repository
              </a>
            </div>
          </div>

          <div className="grid gap-4">
            <div className="inline-flex w-fit rounded-full border border-[var(--color-app-accent-soft)] bg-[linear-gradient(135deg,var(--color-app-accent-soft),var(--color-app-rind-soft))] px-3 py-2 font-body text-[0.76rem] font-bold uppercase tracking-[0.16em] text-app-sand">
              Watermelon desktop workflow
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
              <div className="rounded-[20px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(255,98,120,0.05))] p-4">
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
              <div className="rounded-[20px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(255,168,102,0.05))] p-4">
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
          copy="Melon treats mods, shader packs, and resource packs as first-class content. The job is not only downloading. It is keeping the whole library easier to install, scan, update, and move over time."
        />

        <div className="mt-6 grid gap-4 xl:grid-cols-3">
          {contentTypes.map((type) => {
            const Icon = type.icon;

            return (
              <article
                key={type.title}
                className="glass-panel flex h-full flex-col rounded-[26px] border border-app-line bg-[linear-gradient(180deg,rgba(255,255,255,0.04),rgba(255,255,255,0.02))] p-6"
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="inline-flex rounded-2xl border border-[var(--color-app-rind-soft)] bg-[linear-gradient(135deg,var(--color-app-accent-soft),var(--color-app-rind-soft))] p-3 text-app-sand">
                    <Icon className="h-5 w-5" />
                  </div>
                  <span className="rounded-full border border-app-line bg-white/4 px-3 py-1.5 font-body text-[0.72rem] uppercase tracking-[0.14em] text-app-muted">
                    {type.subtitle}
                  </span>
                </div>

                <h3 className="mt-5 text-[clamp(1.55rem,2.2vw,2rem)] leading-[1.02] text-app-text">
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
          title="Useful desktop tools, not just a download screen."
          copy="Melon already handles dependency review, local file intake, tracked updates, bundle tools, and metadata rebuild. This section stays compact and puts those tools directly into cards."
        />

        <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {toolkitCards.map((card) => {
            const Icon = card.icon;

            return (
              <article
                key={card.title}
                className="rounded-[24px] border border-app-line bg-white/[0.04] p-5"
              >
                <div className="inline-flex rounded-2xl border border-[var(--color-app-rind-soft)] bg-[linear-gradient(135deg,var(--color-app-accent-soft),var(--color-app-rind-soft))] p-3 text-app-sand">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="mt-4 text-[1.45rem] leading-[1.08] text-app-text">
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
          copy="Melon is strongest when the page shows the sequence clearly: detect the instance, find content, install with context, then maintain the library later."
        />

        <div className="mt-6 grid gap-4 xl:grid-cols-2">
          {workflowSteps.map((step) => {
            const Icon = step.icon;

            return (
              <article
                key={step.step}
                className="glass-panel flex h-full flex-col rounded-[28px] border border-app-line p-6"
              >
                <div className="flex items-start justify-between gap-4">
                  <span className="inline-flex h-14 w-14 items-center justify-center rounded-full border border-[var(--color-app-rind-soft)] bg-[linear-gradient(135deg,var(--color-app-accent-soft),rgba(255,255,255,0.02))] font-body text-[0.88rem] font-bold tracking-[0.12em] text-app-sand">
                    {step.step}
                  </span>
                  <div className="rounded-2xl border border-app-line bg-white/4 p-3 text-app-muted">
                    <Icon className="h-5 w-5" />
                  </div>
                </div>
                <h3 className="mt-5 max-w-[18ch] text-[clamp(1.5rem,2.4vw,2.1rem)] leading-[1.04] text-app-text">
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
          title="Compatibility facts and a clear trust path."
          copy="Melon is a personal open-source desktop app. The trust path is simple: review the source, build it yourself, or compare release files with the published checksums."
        />

        <div className="mt-6 grid gap-5 xl:grid-cols-[minmax(0,0.92fr)_minmax(0,1.08fr)]">
          <div className="grid gap-4">
            <div className="rounded-[24px] border border-app-line bg-white/[0.04] p-5">
              <h3 className="text-[1.5rem] leading-[1.08] text-app-text">
                Why antivirus warnings can happen
              </h3>
              <p className="mt-3 font-body leading-7 text-app-muted">
                Small unsigned desktop apps can trigger false positives. That
                does not replace verification. It just means the intended trust
                path should stay visible on the site.
              </p>
            </div>

            <div className="rounded-[24px] border border-app-line bg-white/[0.04] p-5">
              <h3 className="text-[1.5rem] leading-[1.08] text-app-text">
                What the site should promise clearly
              </h3>
              <p className="mt-3 font-body leading-7 text-app-muted">
                Loader-aware Java mod workflows, support for shader packs and
                resource packs, and GitHub-based releases. Nothing vague, and
                nothing beyond what the app already supports.
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
          copy="The website should close with clear next actions, not another oversized empty section. Keep the links practical: releases, repository, issues, and Modrinth."
        />

        <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {quickLinks.map((link) => {
            const Icon = link.icon;

            return (
              <a
                key={link.label}
                href={link.href}
                className="glass-panel group rounded-[22px] border border-app-line p-5 transition duration-150 hover:-translate-y-0.5 hover:border-[var(--color-app-accent-soft)] hover:bg-white/6"
              >
                <div className="flex items-start justify-between gap-4">
                  <span className="font-body text-sm uppercase tracking-[0.12em] text-app-muted">
                    {link.label}
                  </span>
                  <div className="rounded-xl border border-app-line bg-white/4 p-2 text-app-accent transition-transform duration-150 group-hover:translate-x-0.5">
                    <Icon className="h-4 w-4" />
                  </div>
                </div>
                <strong className="mt-8 block text-[1.15rem] text-app-sand">
                  Open
                </strong>
              </a>
            );
          })}
        </div>
      </section>
    </main>
  );
}

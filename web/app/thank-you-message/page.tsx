import type { Metadata } from "next";
import Link from "next/link";
import { BackToTopButton } from "../components/back-to-top-button";
import { ScrollReveal } from "../components/scroll-reveal";
import { siteName, siteUrl } from "../site-config";

export const metadata: Metadata = {
  title: `See You Around | ${siteName}`,
  description:
    "A warm farewell page for Melon Mod Manager with a heartfelt thank-you and a simple path back if someone wants to return.",
  alternates: {
    canonical: "/thank-you-message",
  },
  openGraph: {
    title: `See You Around | ${siteName}`,
    description:
      "A warm farewell page for Melon Mod Manager with a heartfelt thank-you and a simple path back if someone wants to return.",
    url: `${siteUrl}/thank-you-message`,
  },
  twitter: {
    title: `See You Around | ${siteName}`,
    description:
      "A warm farewell page for Melon Mod Manager with a heartfelt thank-you and a simple path back if someone wants to return.",
  },
};

function FarewellMark() {
  return (
    <div className="relative flex h-28 w-28 items-center justify-center sm:h-32 sm:w-32 md:h-36 md:w-36">
      <div className="absolute inset-0 rounded-[2rem] border border-white/8 bg-[radial-gradient(circle_at_30%_30%,rgba(176,230,187,0.16),transparent_58%),linear-gradient(180deg,rgba(255,255,255,0.05),rgba(255,255,255,0.015))] shadow-[0_28px_60px_rgba(0,0,0,0.3)]" />
      <div className="absolute inset-4 rounded-[1.6rem] border border-white/6 bg-[linear-gradient(180deg,rgba(7,17,14,0.28),rgba(7,17,14,0.04))]" />
      <svg
        viewBox="0 0 96 96"
        aria-hidden="true"
        className="relative h-12 w-12 text-[#d8f1de] sm:h-[3.4rem] sm:w-[3.4rem] md:h-[3.7rem] md:w-[3.7rem]"
        fill="none"
      >
        <path
          d="M29 52V30c0-3 2-5 4.6-5s4.8 2 4.8 5v16"
          stroke="currentColor"
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M38.4 46V24.5c0-3 2.1-5.2 4.9-5.2 2.7 0 4.8 2.2 4.8 5.2V46"
          stroke="currentColor"
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M48 44V27.5c0-2.9 2-5 4.6-5s4.6 2.1 4.6 5V46"
          stroke="currentColor"
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M57.2 48v-13c0-2.8 1.9-4.8 4.4-4.8S66 32.2 66 35v22.5c0 9.7-7.8 17.5-17.5 17.5h-3C35.3 75 27 66.7 27 56.5V42.8c0-2.8 1.9-4.8 4.5-4.8s4.5 2 4.5 4.8V54"
          stroke="currentColor"
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M69.5 23.5c3.8 2.2 6.5 6 7.3 10.5"
          stroke="#8fd5aa"
          strokeWidth="3.2"
          strokeLinecap="round"
        />
        <path
          d="M72 15.5c6.4 3.4 10.9 9.6 12 16.9"
          stroke="#8fd5aa"
          strokeWidth="2.8"
          strokeLinecap="round"
          opacity="0.72"
        />
      </svg>
      <div className="absolute -bottom-3 left-1/2 flex h-14 w-14 -translate-x-1/2 items-center justify-center rounded-full border border-white/10 bg-[radial-gradient(circle_at_30%_30%,rgba(136,242,168,0.95),rgba(62,205,142,0.92)_38%,rgba(33,164,148,0.95)_72%,rgba(19,86,96,0.96)_100%)] shadow-[0_18px_44px_rgba(63,201,154,0.28)] sm:h-[3.8rem] sm:w-[3.8rem]">
        <span
          aria-hidden="true"
          className="text-[1.9rem] leading-none text-white/96 sm:text-[2.05rem]"
        >
          ♥
        </span>
      </div>
    </div>
  );
}

export default function ThankYouMessagePage() {
  return (
    <main className="relative mx-auto flex min-h-[100svh] w-[min(1120px,calc(100%-20px))] flex-col px-1 py-3 sm:w-[min(1120px,calc(100%-32px))] sm:px-2 sm:py-4 md:w-[min(1120px,calc(100%-56px))] md:px-3 md:py-6">
      <BackToTopButton />

      <ScrollReveal
        as="section"
        className="relative flex min-h-[calc(100svh-1.5rem)] items-center justify-center overflow-hidden rounded-[32px] border border-app-line px-6 py-8 sm:min-h-[calc(100svh-2rem)] sm:px-8 sm:py-10 md:min-h-[calc(100svh-3rem)] md:rounded-[40px] md:px-12 md:py-12"
      >
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(7,18,14,0.9),rgba(4,10,8,0.96))]" />
        <div className="ambient-float absolute left-1/2 top-[12%] h-64 w-64 -translate-x-1/2 rounded-full bg-[radial-gradient(circle,rgba(113,177,138,0.14),transparent_68%)] blur-3xl" />
        <div className="ambient-float ambient-float-delay absolute bottom-[-4rem] left-[18%] h-56 w-56 rounded-full bg-[radial-gradient(circle,rgba(93,144,118,0.1),transparent_72%)] blur-3xl" />
        <div className="ambient-float ambient-float-slow absolute right-[14%] top-[24%] h-52 w-52 rounded-full bg-[radial-gradient(circle,rgba(162,205,150,0.08),transparent_74%)] blur-3xl" />

        <div className="relative mx-auto flex w-full max-w-[42rem] flex-col items-center text-center">
          <ScrollReveal delay={0.08}>
            <FarewellMark />
          </ScrollReveal>

          <ScrollReveal delay={0.16} className="mt-6 sm:mt-7 md:mt-8">
            <h1 className="font-body text-[clamp(2.7rem,5.9vw,4.85rem)] font-semibold leading-[0.9] tracking-[-0.065em] text-app-text">
              Thank you for using Melon Mod Manager
            </h1>
          </ScrollReveal>

          <ScrollReveal delay={0.24} className="mt-4 sm:mt-5">
            <p className="mx-auto max-w-[33rem] font-body text-[0.96rem] leading-7 text-app-muted sm:text-[1rem] sm:leading-7">
              Your time with Melon Mod Manager truly meant something to us. Thanks for installing it, making it part of your setup, and giving it a place in your world. If you ever want to come back, we&apos;ll be here waiting for you on the site anytime. ✨
            </p>
          </ScrollReveal>

          <ScrollReveal delay={0.34} className="mt-7 sm:mt-8 md:mt-9">
            <Link
              href="/"
              className="cta-pulse inline-flex min-h-[3.25rem] min-w-[17rem] items-center justify-center rounded-full bg-[linear-gradient(135deg,var(--accent),rgba(177,228,158,0.96),#d6eaa9)] px-7 font-body text-[0.97rem] font-bold text-[#0c1f19] transition-transform duration-150 hover:-translate-y-0.5"
            >
              Visit the site and download Melon again
            </Link>
          </ScrollReveal>
        </div>
      </ScrollReveal>
    </main>
  );
}

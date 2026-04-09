"use client";

import { ArrowUp } from "lucide-react";
import { animate, motion, useMotionValueEvent, useReducedMotion, useScroll } from "motion/react";
import { useEffect, useState } from "react";

const SHOW_AFTER_SCROLL = 420;

export function BackToTopButton() {
  const shouldReduceMotion = useReducedMotion();
  const { scrollY } = useScroll();
  const [isVisible, setIsVisible] = useState(false);

  useMotionValueEvent(scrollY, "change", (latest) => {
    setIsVisible(latest > SHOW_AFTER_SCROLL);
  });

  useEffect(() => {
    setIsVisible(window.scrollY > SHOW_AFTER_SCROLL);
  }, []);

  const scrollToTop = () => {
    if (shouldReduceMotion) {
      window.scrollTo(0, 0);
      return;
    }

    animate(window.scrollY, 0, {
      duration: 0.55,
      ease: [0.2, 0.7, 0.2, 1],
      onUpdate: (latest) => window.scrollTo(0, latest),
    });
  };

  return (
    <motion.button
      type="button"
      aria-label="Back to top"
      onClick={scrollToTop}
      className="fixed right-8 bottom-8 z-50 hidden h-12 w-12 items-center justify-center rounded-full border border-[var(--color-app-accent-soft)] bg-[linear-gradient(135deg,rgba(14,30,25,0.94),rgba(8,18,15,0.98))] text-app-sand shadow-[0_18px_44px_rgba(0,0,0,0.3)] backdrop-blur-xl transition-colors duration-150 hover:border-[#69d1a4]/45 hover:text-app-text xl:inline-flex"
      initial={false}
      animate={
        isVisible
          ? { opacity: 1, y: 0, pointerEvents: "auto" }
          : { opacity: 0, y: 18, pointerEvents: "none" }
      }
      transition={{
        duration: shouldReduceMotion ? 0 : 0.24,
        ease: [0.2, 0.7, 0.2, 1],
      }}
    >
      <ArrowUp className="h-4 w-4" />
    </motion.button>
  );
}

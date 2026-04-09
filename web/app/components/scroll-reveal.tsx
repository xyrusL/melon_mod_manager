"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";

type RevealDirection = "up" | "down" | "left" | "right";
type ScrollRevealTag = "article" | "div" | "section";

type ScrollRevealProps = {
  as?: ScrollRevealTag;
  children: ReactNode;
  className?: string;
  delay?: number;
  duration?: number;
  distance?: number;
  direction?: RevealDirection;
  amount?: number;
  id?: string;
};

function getHiddenOffset(direction: RevealDirection, distance: number) {
  switch (direction) {
    case "down":
      return { x: 0, y: -distance };
    case "left":
      return { x: distance, y: 0 };
    case "right":
      return { x: -distance, y: 0 };
    case "up":
    default:
      return { x: 0, y: distance };
  }
}

export function ScrollReveal({
  as,
  children,
  className,
  delay = 0,
  duration = 0.72,
  distance = 26,
  direction = "up",
  amount = 0.22,
  id,
}: ScrollRevealProps) {
  const shouldReduceMotion = useReducedMotion();
  const MotionComponent = motion.create(as ?? "div");
  const hiddenOffset = getHiddenOffset(direction, distance);

  return (
    <MotionComponent
      id={id}
      className={className}
      initial={
        shouldReduceMotion
          ? false
          : { opacity: 0, ...hiddenOffset }
      }
      whileInView={
        shouldReduceMotion
          ? undefined
          : { opacity: 1, x: 0, y: 0 }
      }
      animate={shouldReduceMotion ? { opacity: 1, x: 0, y: 0 } : undefined}
      viewport={{ once: true, amount }}
      transition={{
        duration: shouldReduceMotion ? 0 : duration,
        delay: shouldReduceMotion ? 0 : delay,
        ease: [0.2, 0.7, 0.2, 1],
      }}
    >
      {children}
    </MotionComponent>
  );
}

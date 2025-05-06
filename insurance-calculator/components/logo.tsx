"use client"

import { motion } from "framer-motion"

interface LogoProps {
  size?: "sm" | "md" | "lg"
  showText?: boolean
  className?: string
}

export function Logo({ size = "md", showText = true, className = "" }: LogoProps) {
  const sizeClasses = {
    sm: "h-12", // Increased size for small
    md: "h-16", // Increased size for medium
    lg: "h-24", // Increased size for large
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className={`flex items-center gap-4 ${className}`}>
      <div className={`relative ${sizeClasses[size]}`}>
        <img
          src="/logo.png" // Replace with the correct path to the provided image
          alt="Logo"
          className="w-full h-full object-contain"
        />
      </div>
      {showText && (
        <div className="font-bold text-white">
          <span className={size === "lg" ? "text-4xl" : size === "md" ? "text-2xl" : "text-xl"}>InsuraCore</span>
          <span
            className={`block -mt-1 ${
              size === "lg" ? "text-lg" : size === "md" ? "text-sm" : "text-xs"
            } text-white font-normal tracking-wider`}
          >
          </span>
        </div>
      )}
    </motion.div>
  )
}
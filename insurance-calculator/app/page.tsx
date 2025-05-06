"use client"

import Link from "next/link"
import { ArrowRight } from "lucide-react"
import { UiButton } from "@/components/ui-button"
import { Logo } from "@/components/logo"
import { BackgroundGrid } from "@/components/background-grid"
import { motion } from "framer-motion"

export default function LandingPage() {
  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-white">
      <BackgroundGrid />

      <header className="absolute top-0 left-0 py-6 px-6 md:px-10">
        <div className="max-w-7xl mx-auto">
          <Logo size="md" />
        </div>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center p-6 md:p-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="max-w-4xl mx-auto text-center space-y-8"
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, duration: 0.5 }}
            className="mx-auto mb-10"
          >
            {/* <Logo size="lg" /> */}
          </motion.div>

          <h1 className="text-5xl md:text-7xl font-bold leading-tight">
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400">
              Next-Gen Auto Insurance
            </span>
            <span className="block text-white mt-2">in Seconds</span>
          </h1>

          <p className="text-xl text-slate-300 max-w-2xl mx-auto mt-6">
          Accurate insurance quotes based on how and where you drive..
          </p>

          <div className="mt-12">
            <Link href="/calculate">
              <UiButton size="lg">
                <span className="flex items-center gap-2">
                  Calculate Your Premium
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </span>
              </UiButton>
            </Link>
          </div>
        </motion.div>
      </main>

      <footer className="w-full py-6 text-center text-slate-500 text-sm">
        <p>© 2025 InsuraCore. All rights reserved.</p>
      </footer>
    </div>
  )
}

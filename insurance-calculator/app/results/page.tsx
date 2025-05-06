"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { UiButton } from "@/components/ui-button"
import { ArrowLeft } from "lucide-react"
import { NeonCard } from "@/components/neon-card"
import { ScoreCard } from "@/components/score-card"
import { Logo } from "@/components/logo"
import { BackgroundGrid } from "@/components/background-grid"
import Link from "next/link"

interface PremiumResults {
  base_premium: number
  driver_score: {
    age_factor: number
    drug_factor: number
    total: number
  }
  vehicle_score: {
    value_factor: number
    age_factor: number
    total: number
  }
  region_score: {
    severity_factor: number
    weather_factor: number
    total: number
  }
  safety_discount: {
    percent: number
    amount: number
  }
}

export default function ResultsPage() {
  const router = useRouter()
  const [results, setResults] = useState<PremiumResults | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get results from localStorage
    const storedResults = localStorage.getItem("premiumResults")

    if (storedResults) {
      const parsedResults = JSON.parse(storedResults)
      setResults({
        base_premium: parsedResults.base_premium,
        driver_score: {
          age_factor: parsedResults.driver_age_ratio,
          drug_factor: parsedResults.driver_drug_ratio,
          total: parsedResults.driver_score,
        },
        vehicle_score: {
          value_factor: parsedResults.car_value,
          age_factor: 0, // Assuming no equivalent in the new JSON
          total: parsedResults.vehicle_score,
        },
        region_score: {
          severity_factor: parsedResults.region_severity_score,
          weather_factor: parsedResults.region_weather_score,
          total: parsedResults.region_score,
        },
        safety_discount: {
          percent: parsedResults.safety_pct,
          amount: parsedResults.safety_discount,
        },
      })
    } else {
      // If no results, use mock data
      setResults({
        base_premium: 2807.17,
        driver_score: {
          age_factor: 0,
          drug_factor: 0,
          total: 0,
        },
        vehicle_score: {
          value_factor: 25000.0,
          age_factor: 0,
          total: 0.54,
        },
        region_score: {
          severity_factor: 80.86,
          weather_factor: 34.21,
          total: 115.07,
        },
        safety_discount: {
          percent: 15.54,
          amount: 3885.0,
        },
      })
    }

    setLoading(false)
  }, [])

  const handleRecalculate = () => {
    router.push("/calculate")
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 text-white flex items-center justify-center">
        <div className="text-2xl text-purple-400">Loading results...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <BackgroundGrid />

      <header className="w-full py-6 px-6 md:px-10">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <Logo size="md" />
          <Link href="/calculate">
            <UiButton variant="ghost" size="sm">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Calculator
            </UiButton>
          </Link>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
          <h1 className="text-3xl md:text-4xl font-bold text-center mb-8 bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 to-purple-500">
            Your Premium Results
          </h1>

          {results && (
            <div className="space-y-8">
              {/* Premium Display */}
              <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.2, duration: 0.5 }}
              >
                <NeonCard className="backdrop-blur-md border-purple-500/30 overflow-hidden">
                  <div className="p-8 text-center relative">
                    <h2 className="text-xl text-slate-300 mb-2">Your Base Premium</h2>
                    <div className="text-5xl md:text-6xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 via-purple-500 to-pink-500 animate-pulse">
                      ${results.base_premium.toFixed(2)}
                    </div>
                    <div className="text-sm text-slate-400 mt-2">
                      After safety discount: ${(results.base_premium - results.safety_discount.amount).toFixed(2)}
                    </div>

                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-cyan-500 via-purple-500 to-pink-500"></div>
                  </div>
                </NeonCard>
              </motion.div>

              {/* Score Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <motion.div
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.3, duration: 0.5 }}
                >
                  <ScoreCard
                    title="Driver Score"
                    score={results.driver_score.total}
                    color="cyan"
                    factors={[
                      { name: "Age Factor", value: results.driver_score.age_factor },
                      { name: "Drug Factor", value: results.driver_score.drug_factor },
                    ]}
                  />
                </motion.div>

                <motion.div
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.4, duration: 0.5 }}
                >
                  <ScoreCard
                    title="Vehicle Score"
                    score={results.vehicle_score.total}
                    color="purple"
                    factors={[
                      { name: "Value Factor", value: results.vehicle_score.value_factor },
                      { name: "Age Factor", value: results.vehicle_score.age_factor },
                    ]}
                  />
                </motion.div>

                <motion.div
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.5, duration: 0.5 }}
                >
                  <ScoreCard
                    title="Region Score"
                    score={results.region_score.total}
                    color="pink"
                    factors={[
                      { name: "Severity Factor", value: results.region_score.severity_factor },
                      { name: "Weather Factor", value: results.region_score.weather_factor },
                    ]}
                  />
                </motion.div>

                <motion.div
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.6, duration: 0.5 }}
                >
                  <ScoreCard
                    title="Safety Discount"
                    score={results.safety_discount.percent / 100}
                    color="green"
                    isPercentage={true}
                    factors={[{ name: "Discount Amount", value: results.safety_discount.amount, isCurrency: true }]}
                  />
                </motion.div>
              </div>

              {/* Recalculate Button */}
              <div className="flex justify-center mt-8">
                <UiButton onClick={handleRecalculate} size="lg">
                  <span className="flex items-center gap-2">
                    <ArrowLeft className="w-5 h-5 mr-1" />
                    Recalculate Premium
                  </span>
                </UiButton>
              </div>
            </div>
          )}
        </motion.div>
      </main>

      <footer className="w-full py-6 text-center text-slate-500 text-sm">
      <p>© 2025 InsuraCore. All rights reserved.</p>
      </footer>
    </div>
  )
}
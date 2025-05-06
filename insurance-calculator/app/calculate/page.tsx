"use client"

import type React from "react"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { UiButton } from "@/components/ui-button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Loader2, ArrowLeft } from "lucide-react"
import { NeonCard } from "@/components/neon-card"
import { Logo } from "@/components/logo"
import { BackgroundGrid } from "@/components/background-grid"
import Link from "next/link"

const STATES = [
  "California",
  "Texas",
  "Florida",
  "New York",
  "Pennsylvania",
  "Georgia",
  "Ohio",
  "North Carolina",
  "Illinois",
  "Michigan",
]

const DRUGS = ["None", "Cannabinoid", "Opioid", "Stimulant", "Depressant"]

const CAR_MAKES = ["Toyota", "Honda", "Ford", "Chevrolet", "BMW", "Mercedes", "Audi", "Tesla", "Nissan", "Hyundai"]

const COUNTIES = [
  "KERN (29)",
  "SAN JOAQUIN (77)",
  "KINGS (31)",
  "RIVERSIDE (65)",
  "TULARE (107)",
  "SANTA CLARA (85)",
  "MADERA (39)",
  "SAN BENITO (69)",
  "EL DORADO (17)",
  "TRINITY (105)",
  "CONTRA COSTA (13)",
  "GLENN (21)",
  "SOLANO (95)",
  "ALAMEDA (1)",
  "LASSEN (35)",
  "SONOMA (97)",
  "LOS ANGELES (37)",
]

export default function CalculatePage() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const [formData, setFormData] = useState({
    car_value: 25000,
    state: "CA",
    age: 35,
    drug: "Cannabinoid",
    make: "Chevrolet",
    model: "Camaro",
    year: 1972,
    county: "SANTA CLARA (43)",
  })

  const handleChange = (field: string, value: any) => {
    setFormData((prev) => ({ ...prev, [field]: value }))

    // Clear error for this field if it exists
    if (errors[field]) {
      setErrors((prev) => {
        const newErrors = { ...prev }
        delete newErrors[field]
        return newErrors
      })
    }
  }

  const validateForm = () => {
    const newErrors: Record<string, string> = {}

    if (!formData.car_value || formData.car_value <= 0) {
      newErrors.car_value = "Car value must be greater than 0"
    }

    if (!STATES.includes(formData.state)) {
      newErrors.state = "Please select a valid state"
    }

    if (!formData.age || formData.age < 16 || formData.age > 100) {
      newErrors.age = "Age must be between 16 and 100"
    }

    if (!formData.make) {
      newErrors.make = "Car make is required"
    }

    if (!formData.model) {
      newErrors.model = "Car model is required"
    }

    if (!formData.year || formData.year < 1900 || formData.year > new Date().getFullYear() + 1) {
      newErrors.year = `Year must be between 1900 and ${new Date().getFullYear() + 1}`
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!validateForm()) {
      return
    }

    setLoading(true)

    try {
      // Try to fetch from the API
      const response = await fetch("http://localhost:5000/premium", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      })

      if (response.ok) {
        const data = await response.json()
        // Store the result in localStorage to access it on the results page
        localStorage.setItem("premiumResults", JSON.stringify(data))
      } else {
        // If API call fails, use mock data
        const mockData = {
          base_premium: 1250.75,
          driver_score: {
            age_factor: 0.85,
            drug_factor: 1.2,
            total: 1.02,
          },
          vehicle_score: {
            value_factor: 1.15,
            age_factor: 1.3,
            total: 1.49,
          },
          region_score: {
            severity_factor: 1.1,
            weather_factor: 0.95,
            total: 1.05,
          },
          safety_discount: {
            percent: 15,
            amount: 187.61,
          },
        }
        localStorage.setItem("premiumResults", JSON.stringify(mockData))
      }

      // Navigate to results page
      router.push("/results")
    } catch (error) {
      console.error("Error calculating premium:", error)
      // Use mock data as fallback
      const mockData = {
        base_premium: 1250.75,
        driver_score: {
          age_factor: 0.85,
          drug_factor: 1.2,
          total: 1.02,
        },
        vehicle_score: {
          value_factor: 1.15,
          age_factor: 1.3,
          total: 1.49,
        },
        region_score: {
          severity_factor: 1.1,
          weather_factor: 0.95,
          total: 1.05,
        },
        safety_discount: {
          percent: 15,
          amount: 187.61,
        },
      }
      localStorage.setItem("premiumResults", JSON.stringify(mockData))
      router.push("/results")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      <BackgroundGrid />

      <header className="w-full py-6 px-6 md:px-10">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <Logo size="md" />
          <Link href="/">
            <UiButton variant="ghost" size="sm">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Home
            </UiButton>
          </Link>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
          <h1 className="text-3xl md:text-4xl font-bold text-center mb-8 bg-clip-text text-transparent bg-gradient-to-r from-cyan-400 to-purple-500">
            Calculate Your Premium
          </h1>

          <NeonCard className="backdrop-blur-md">
            <form onSubmit={handleSubmit} className="space-y-8 p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Car Value */}
                <div className="space-y-2">
                  <Label htmlFor="car_value" className="text-sm font-medium text-slate-300">
                    Car Value ($)
                  </Label>
                  <Input
                    id="car_value"
                    type="number"
                    value={formData.car_value}
                    onChange={(e) => handleChange("car_value", Number(e.target.value))}
                    className={`bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20 ${
                      errors.car_value ? "border-red-500" : ""
                    }`}
                  />
                  {errors.car_value && <p className="text-red-500 text-xs mt-1">{errors.car_value}</p>}
                </div>

                {/* State */}
                <div className="space-y-2">
                  <Label htmlFor="state" className="text-sm font-medium text-slate-300">
                    State
                  </Label>
                  <Select value={formData.state} onValueChange={(value) => handleChange("state", value)}>
                    <SelectTrigger
                      className={`bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20 ${
                        errors.state ? "border-red-500" : ""
                      }`}
                    >
                      <SelectValue placeholder="Select state" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-900 border-slate-700">
                      {STATES.map((state) => (
                        <SelectItem key={state} value={state}>
                          {state}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {errors.state && <p className="text-red-500 text-xs mt-1">{errors.state}</p>}
                </div>

                {/* Age */}
                <div className="space-y-4">
                  <div className="flex justify-between">
                    <Label htmlFor="age" className="text-sm font-medium text-slate-300">
                      Age
                    </Label>
                    <span className="text-sm text-purple-400">{formData.age} years</span>
                  </div>
                  <Slider
                    id="age"
                    min={16}
                    max={100}
                    step={1}
                    value={[formData.age]}
                    onValueChange={(value) => handleChange("age", value[0])}
                    className={errors.age ? "border-red-500" : ""}
                  />
                  {errors.age && <p className="text-red-500 text-xs mt-1">{errors.age}</p>}
                </div>

                {/* Drug */}
                <div className="space-y-2">
                  <Label htmlFor="drug" className="text-sm font-medium text-slate-300">
                    Drug Usage
                  </Label>
                  <Select value={formData.drug} onValueChange={(value) => handleChange("drug", value)}>
                    <SelectTrigger className="bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20">
                      <SelectValue placeholder="Select drug usage" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-900 border-slate-700">
                      {DRUGS.map((drug) => (
                        <SelectItem key={drug} value={drug}>
                          {drug}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Make */}
                <div className="space-y-2">
                  <Label htmlFor="make" className="text-sm font-medium text-slate-300">
                    Car Make
                  </Label>
                  <Select value={formData.make} onValueChange={(value) => handleChange("make", value)}>
                    <SelectTrigger
                      className={`bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20 ${
                        errors.make ? "border-red-500" : ""
                      }`}
                    >
                      <SelectValue placeholder="Select car make" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-900 border-slate-700">
                      {CAR_MAKES.map((make) => (
                        <SelectItem key={make} value={make}>
                          {make}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {errors.make && <p className="text-red-500 text-xs mt-1">{errors.make}</p>}
                </div>

                {/* Model */}
                <div className="space-y-2">
                  <Label htmlFor="model" className="text-sm font-medium text-slate-300">
                    Car Model
                  </Label>
                  <Input
                    id="model"
                    value={formData.model}
                    onChange={(e) => handleChange("model", e.target.value)}
                    className={`bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20 ${
                      errors.model ? "border-red-500" : ""
                    }`}
                  />
                  {errors.model && <p className="text-red-500 text-xs mt-1">{errors.model}</p>}
                </div>

                {/* Year */}
                <div className="space-y-2">
                  <Label htmlFor="year" className="text-sm font-medium text-slate-300">
                    Car Year
                  </Label>
                  <Input
                    id="year"
                    type="number"
                    value={formData.year}
                    onChange={(e) => handleChange("year", Number(e.target.value))}
                    className={`bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20 ${
                      errors.year ? "border-red-500" : ""
                    }`}
                  />
                  {errors.year && <p className="text-red-500 text-xs mt-1">{errors.year}</p>}
                </div>

                {/* County */}
                <div className="space-y-2">
                  <Label htmlFor="county" className="text-sm font-medium text-slate-300">
                    County
                  </Label>
                  <Select value={formData.county} onValueChange={(value) => handleChange("county", value)}>
                    <SelectTrigger className="bg-slate-900/50 border-slate-700 focus:border-purple-500 focus:ring-purple-500/20">
                      <SelectValue placeholder="Select county" />
                    </SelectTrigger>
                    <SelectContent className="bg-slate-900 border-slate-700 max-h-[200px]">
                      {COUNTIES.map((county) => (
                        <SelectItem key={county} value={county}>
                          {county}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex justify-center pt-4">
                <UiButton type="submit" disabled={loading} size="lg">
                  {loading ? (
                    <span className="flex items-center gap-2">
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Calculating...
                    </span>
                  ) : (
                    <span className="flex items-center gap-2">Calculate Premium</span>
                  )}
                </UiButton>
              </div>
            </form>
          </NeonCard>
        </motion.div>
      </main>

      <footer className="w-full py-6 text-center text-slate-500 text-sm">
        <p>© 2025 InsuraCore. All rights reserved.</p>
      </footer>
    </div>
  )
}

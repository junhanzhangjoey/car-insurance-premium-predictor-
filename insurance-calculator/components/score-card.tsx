import { NeonCard } from "@/components/neon-card"

interface ScoreCardProps {
  title: string
  score: number
  color: "purple" | "cyan" | "pink" | "green"
  isPercentage?: boolean
  factors: {
    name: string
    value: number
    isCurrency?: boolean
  }[]
}

export function ScoreCard({ title, score, color, isPercentage = false, factors }: ScoreCardProps) {
  // Format the score as a percentage or decimal
  const formattedScore = isPercentage ? `${(score * 100).toFixed(0)}%` : score.toFixed(2)

  // Determine if the score is good, neutral, or bad
  const getScoreColor = () => {
    if (isPercentage) {
      return score >= 0.15 ? "text-emerald-400" : "text-amber-400"
    } else {
      return score <= 0.9 ? "text-emerald-400" : score <= 1.1 ? "text-amber-400" : "text-pink-400"
    }
  }

  return (
    <NeonCard glowColor={color} className="h-full">
      <div className="p-6 space-y-4">
        <h3 className="text-xl font-semibold text-slate-200">{title}</h3>

        <div className="flex justify-between items-center">
          <div className="text-sm text-slate-400">Total Score</div>
          <div className={`text-2xl font-bold ${getScoreColor()}`}>{formattedScore}</div>
        </div>

        <div className="space-y-2 pt-2">
          {factors.map((factor, index) => (
            <div key={index} className="flex justify-between items-center text-sm">
              <div className="text-slate-400">{factor.name}</div>
              <div className="text-slate-300">
                {factor.isCurrency ? `$${factor.value.toFixed(2)}` : factor.value.toFixed(2)}
              </div>
            </div>
          ))}
        </div>

        {/* Score Gauge */}
        <div className="pt-2">
          <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
            <div
              className={`h-full ${
                color === "purple"
                  ? "bg-purple-500"
                  : color === "cyan"
                    ? "bg-cyan-500"
                    : color === "pink"
                      ? "bg-pink-500"
                      : "bg-emerald-500"
              }`}
              style={{
                width: isPercentage ? `${Math.min(score * 100, 100)}%` : `${Math.min(score * 50, 100)}%`,
              }}
            />
          </div>
        </div>
      </div>
    </NeonCard>
  )
}

import { cn } from "@/lib/utils"
import { Card, type CardProps } from "@/components/ui/card"

interface NeonCardProps extends CardProps {
  glowColor?: string
}

export function NeonCard({ className, glowColor = "purple", children, ...props }: NeonCardProps) {
  const glowMap = {
    purple: "before:from-purple-500/0 before:via-purple-500/10 before:to-purple-500/0",
    cyan: "before:from-cyan-500/0 before:via-cyan-500/10 before:to-cyan-500/0",
    pink: "before:from-pink-500/0 before:via-pink-500/10 before:to-pink-500/0",
    green: "before:from-emerald-500/0 before:via-emerald-500/10 before:to-emerald-500/0",
  }

  return (
    <Card
      className={cn(
        "relative bg-black/30 border-slate-800/50 backdrop-blur-md overflow-hidden",
        "before:absolute before:inset-0 before:-z-10 before:bg-gradient-to-r before:opacity-70",
        glowMap[glowColor as keyof typeof glowMap] || glowMap.purple,
        className,
      )}
      {...props}
    >
      {children}
    </Card>
  )
}

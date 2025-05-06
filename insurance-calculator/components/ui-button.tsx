import { forwardRef } from "react"
import { cn } from "@/lib/utils"
import { Button as ShadcnButton, type ButtonProps as ShadcnButtonProps } from "@/components/ui/button"

interface ButtonProps extends ShadcnButtonProps {
  glowColor?: "cyan" | "purple" | "pink" | "gradient"
  size?: "default" | "sm" | "lg" | "icon"
  variant?: "default" | "outline" | "ghost"
}

export const UiButton = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, glowColor = "gradient", size = "default", variant = "default", children, ...props }, ref) => {
    const glowClasses = {
      cyan: "from-cyan-600 to-cyan-600",
      purple: "from-purple-600 to-purple-600",
      pink: "from-pink-600 to-pink-600",
      gradient: "from-cyan-600 via-purple-600 to-pink-600",
    }

    const hoverTextClasses = {
      cyan: "group-hover:text-cyan-600",
      purple: "group-hover:text-purple-600",
      pink: "group-hover:text-pink-600",
      gradient: "group-hover:text-purple-600",
    }

    const sizeClasses = {
      default: "px-6 py-3 text-sm",
      sm: "px-4 py-2 text-xs",
      lg: "px-8 py-4 text-base",
      icon: "p-2",
    }

    const variantClasses = {
      default: "bg-black/50 border border-slate-700/50 text-white",
      outline: "bg-transparent border border-slate-700/50 text-white",
      ghost: "bg-transparent border-none text-white hover:bg-white/5",
    }

    return (
      <div className="relative group">
        {/* Glow effect */}
        <div
          className={`absolute -inset-0.5 rounded-xl bg-gradient-to-r ${
            glowClasses[glowColor]
          } opacity-0 group-hover:opacity-70 blur-md transition-all duration-300`}
        ></div>

        <ShadcnButton
          ref={ref}
          className={cn(
            "relative rounded-xl font-medium transition-all duration-300",
            "hover:scale-[1.02] active:scale-[0.98]",
            "flex items-center justify-center gap-2 group",
            "shadow-lg shadow-slate-900/20",
            "hover:bg-white",
            variantClasses[variant],
            sizeClasses[size],
            className,
          )}
          {...props}
        >
          <span className={`transition-colors duration-300 ${hoverTextClasses[glowColor]}`}>{children}</span>
        </ShadcnButton>
      </div>
    )
  },
)

UiButton.displayName = "UiButton"

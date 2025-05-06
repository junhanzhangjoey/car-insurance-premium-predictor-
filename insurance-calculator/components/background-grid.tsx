export function BackgroundGrid() {
  return (
    <div className="absolute inset-0 -z-10 overflow-hidden">
      <div
        className="absolute inset-0 bg-slate-950"
        style={{
          backgroundImage: `radial-gradient(circle at 1px 1px, rgba(255, 255, 255, 0.05) 1px, transparent 0)`,
          backgroundSize: "40px 40px",
        }}
      ></div>
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-500/5 rounded-full filter blur-3xl"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-cyan-500/5 rounded-full filter blur-3xl"></div>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-radial from-purple-500/5 to-transparent rounded-full"></div>
    </div>
  )
}

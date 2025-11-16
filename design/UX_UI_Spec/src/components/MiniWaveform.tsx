interface MiniWaveformProps {
  bars?: number;
  progress?: number;
}

export function MiniWaveform({ bars = 40, progress = 0 }: MiniWaveformProps) {
  const heights = Array.from({ length: bars }, () => Math.random() * 100);

  return (
    <div className="flex items-center gap-[2px] h-[36px] w-full">
      {heights.map((height, idx) => {
        const isPlayed = (idx / bars) * 100 <= progress;
        return (
          <div
            key={idx}
            className="flex-1 rounded-full transition-colors duration-200"
            style={{
              height: `${Math.max(height, 20)}%`,
              backgroundColor: isPlayed 
                ? 'var(--accent-primary)' 
                : 'rgba(255, 255, 255, 0.1)',
            }}
          />
        );
      })}
    </div>
  );
}

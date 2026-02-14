import { clsx } from 'clsx';

interface ProgressBarProps {
  value: number;
  className?: string;
}

export function ProgressBar({ value, className }: ProgressBarProps) {
  const clamped = Math.min(100, Math.max(0, value));
  const color = clamped >= 90 ? 'bg-danger' : clamped >= 70 ? 'bg-warning' : 'bg-success';

  return (
    <div className={clsx('h-2 w-full overflow-hidden rounded-full bg-[hsl(var(--muted))]', className)}>
      <div
        className={clsx('h-full rounded-full transition-all duration-500', color)}
        style={{ width: `${clamped}%` }}
      />
    </div>
  );
}

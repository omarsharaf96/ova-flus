import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { HTMLAttributes } from 'react';

export function Card({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={twMerge(
        clsx(
          'rounded-xl border border-[hsl(var(--border))] bg-[hsl(var(--card))] p-5 shadow-sm',
          className
        )
      )}
      {...props}
    >
      {children}
    </div>
  );
}

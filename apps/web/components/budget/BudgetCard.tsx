import Link from 'next/link';
import { Card } from '@/components/ui/Card';
import { ProgressBar } from '@/components/ui/ProgressBar';

interface BudgetCardProps {
  budget: {
    id: string;
    name: string;
    spent: number;
    limit: number;
    period: 'monthly' | 'yearly';
  };
}

export function BudgetCard({ budget }: BudgetCardProps) {
  const percentage = (budget.spent / budget.limit) * 100;

  return (
    <Link href={`/budgets/${budget.id}`}>
      <Card className="transition-shadow hover:shadow-md">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="font-semibold">{budget.name}</h3>
          <span className="rounded-full bg-[hsl(var(--muted))] px-2 py-0.5 text-xs capitalize text-[hsl(var(--muted-foreground))]">
            {budget.period}
          </span>
        </div>
        <ProgressBar value={percentage} />
        <div className="mt-2 flex justify-between text-sm">
          <span className="text-[hsl(var(--muted-foreground))]">
            ${budget.spent} / ${budget.limit}
          </span>
          <span className="text-[hsl(var(--muted-foreground))]">
            {percentage.toFixed(0)}%
          </span>
        </div>
      </Card>
    </Link>
  );
}

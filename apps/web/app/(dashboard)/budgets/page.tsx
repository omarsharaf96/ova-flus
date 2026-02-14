'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { BudgetCard } from '@/components/budget/BudgetCard';

const mockBudgets = [
  { id: '1', name: 'Groceries', spent: 320, limit: 500, period: 'monthly' as const },
  { id: '2', name: 'Entertainment', spent: 180, limit: 200, period: 'monthly' as const },
  { id: '3', name: 'Transport', spent: 90, limit: 150, period: 'monthly' as const },
  { id: '4', name: 'Dining Out', spent: 250, limit: 300, period: 'monthly' as const },
  { id: '5', name: 'Vacation Fund', spent: 1200, limit: 3000, period: 'yearly' as const },
];

type Period = 'all' | 'monthly' | 'yearly';

export default function BudgetsPage() {
  const [filter, setFilter] = useState<Period>('all');

  const filtered = filter === 'all' ? mockBudgets : mockBudgets.filter((b) => b.period === filter);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Budgets</h1>
        <Button>Add Budget</Button>
      </div>

      <div className="flex gap-2">
        {(['all', 'monthly', 'yearly'] as Period[]).map((p) => (
          <button
            key={p}
            onClick={() => setFilter(p)}
            className={`rounded-full px-3 py-1 text-sm capitalize ${
              filter === p
                ? 'bg-brand-600 text-white'
                : 'bg-[hsl(var(--muted))] text-[hsl(var(--muted-foreground))]'
            }`}
          >
            {p}
          </button>
        ))}
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {filtered.map((budget) => (
          <BudgetCard key={budget.id} budget={budget} />
        ))}
      </div>
    </div>
  );
}

'use client';

import { Card } from '@/components/ui/Card';
import { ProgressBar } from '@/components/ui/ProgressBar';
import { BudgetBarChart } from '@/components/charts/BudgetBarChart';

const mockBudget = {
  id: '1',
  name: 'Groceries',
  spent: 320,
  limit: 500,
  categories: [
    { name: 'Supermarket', spent: 200 },
    { name: 'Farmers Market', spent: 80 },
    { name: 'Online Delivery', spent: 40 },
  ],
};

const mockTransactions = [
  { id: '1', description: 'Whole Foods', amount: -67.43, date: '2024-02-14' },
  { id: '2', description: 'Trader Joes', amount: -52.10, date: '2024-02-12' },
  { id: '3', description: 'Farmers Market', amount: -28.00, date: '2024-02-10' },
];

export default function BudgetDetailPage() {
  const percentage = (mockBudget.spent / mockBudget.limit) * 100;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{mockBudget.name}</h1>

      <Card>
        <div className="mb-2 flex justify-between">
          <span className="text-sm text-[hsl(var(--muted-foreground))]">Spending Progress</span>
          <span className="text-sm font-medium">
            ${mockBudget.spent} / ${mockBudget.limit}
          </span>
        </div>
        <ProgressBar value={percentage} />
        <p className="mt-2 text-xs text-[hsl(var(--muted-foreground))]">
          ${mockBudget.limit - mockBudget.spent} remaining
        </p>
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Category Breakdown</h2>
        <BudgetBarChart
          data={mockBudget.categories.map((c) => ({
            name: c.name,
            actual: c.spent,
            budget: mockBudget.limit / mockBudget.categories.length,
          }))}
        />
      </Card>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Transactions</h2>
        <div className="divide-y divide-[hsl(var(--border))]">
          {mockTransactions.map((tx) => (
            <div key={tx.id} className="flex items-center justify-between py-3">
              <div>
                <p className="font-medium">{tx.description}</p>
                <p className="text-xs text-[hsl(var(--muted-foreground))]">{tx.date}</p>
              </div>
              <p className="text-danger">-${Math.abs(tx.amount).toFixed(2)}</p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

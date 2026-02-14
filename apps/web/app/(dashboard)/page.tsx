'use client';

import { Card } from '@/components/ui/Card';
import { SpendingPieChart } from '@/components/charts/SpendingPieChart';
import { ProgressBar } from '@/components/ui/ProgressBar';

const mockBudgets = [
  { name: 'Groceries', spent: 320, limit: 500 },
  { name: 'Entertainment', spent: 180, limit: 200 },
  { name: 'Transport', spent: 90, limit: 150 },
];

const mockTransactions = [
  { id: '1', description: 'Whole Foods', amount: -67.43, date: '2024-02-14', category: 'Groceries' },
  { id: '2', description: 'Netflix', amount: -15.99, date: '2024-02-13', category: 'Entertainment' },
  { id: '3', description: 'Salary', amount: 5200.0, date: '2024-02-12', category: 'Income' },
  { id: '4', description: 'Gas Station', amount: -42.0, date: '2024-02-11', category: 'Transport' },
];

export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      {/* Summary Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Net Worth</p>
          <p className="text-2xl font-bold">$48,230.00</p>
          <p className="text-xs text-success">+2.4% this month</p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Portfolio Value</p>
          <p className="text-2xl font-bold">$12,450.00</p>
          <p className="text-xs text-success">+$340.20 today</p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Monthly Spending</p>
          <p className="text-2xl font-bold">$1,230.42</p>
          <p className="text-xs text-danger">68% of budget</p>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Budget Overview */}
        <Card>
          <h2 className="mb-4 text-lg font-semibold">Budget Overview</h2>
          <div className="space-y-4">
            {mockBudgets.map((budget) => (
              <div key={budget.name}>
                <div className="mb-1 flex justify-between text-sm">
                  <span>{budget.name}</span>
                  <span className="text-[hsl(var(--muted-foreground))]">
                    ${budget.spent} / ${budget.limit}
                  </span>
                </div>
                <ProgressBar value={(budget.spent / budget.limit) * 100} />
              </div>
            ))}
          </div>
        </Card>

        {/* Spending Breakdown */}
        <Card>
          <h2 className="mb-4 text-lg font-semibold">Spending Breakdown</h2>
          <SpendingPieChart
            data={mockBudgets.map((b) => ({ name: b.name, value: b.spent }))}
          />
        </Card>
      </div>

      {/* Recent Transactions */}
      <Card>
        <h2 className="mb-4 text-lg font-semibold">Recent Transactions</h2>
        <div className="divide-y divide-[hsl(var(--border))]">
          {mockTransactions.map((tx) => (
            <div key={tx.id} className="flex items-center justify-between py-3">
              <div>
                <p className="font-medium">{tx.description}</p>
                <p className="text-xs text-[hsl(var(--muted-foreground))]">
                  {tx.category} &middot; {tx.date}
                </p>
              </div>
              <p className={tx.amount < 0 ? 'text-danger' : 'text-success'}>
                {tx.amount < 0 ? '-' : '+'}${Math.abs(tx.amount).toFixed(2)}
              </p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

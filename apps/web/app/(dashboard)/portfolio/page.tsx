'use client';

import Link from 'next/link';
import { Card } from '@/components/ui/Card';
import { SpendingPieChart } from '@/components/charts/SpendingPieChart';
import { HoldingRow } from '@/components/portfolio/HoldingRow';

const mockHoldings = [
  { id: '1', symbol: 'AAPL', name: 'Apple Inc.', shares: 10, price: 185.42, change: 2.15, changePercent: 1.17, value: 1854.20 },
  { id: '2', symbol: 'GOOGL', name: 'Alphabet Inc.', shares: 5, price: 141.80, change: -0.95, changePercent: -0.67, value: 709.00 },
  { id: '3', symbol: 'MSFT', name: 'Microsoft Corp.', shares: 8, price: 410.34, change: 3.22, changePercent: 0.79, value: 3282.72 },
  { id: '4', symbol: 'AMZN', name: 'Amazon.com Inc.', shares: 12, price: 172.45, change: 1.50, changePercent: 0.88, value: 2069.40 },
];

export default function PortfolioPage() {
  const totalValue = mockHoldings.reduce((sum, h) => sum + h.value, 0);
  const totalChange = mockHoldings.reduce((sum, h) => sum + h.change * h.shares, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Portfolio</h1>

      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Total Value</p>
          <p className="text-2xl font-bold">${totalValue.toFixed(2)}</p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Day P&L</p>
          <p className={`text-2xl font-bold ${totalChange >= 0 ? 'text-success' : 'text-danger'}`}>
            {totalChange >= 0 ? '+' : ''}${totalChange.toFixed(2)}
          </p>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Card>
            <h2 className="mb-4 text-lg font-semibold">Holdings</h2>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-[hsl(var(--border))] text-[hsl(var(--muted-foreground))]">
                    <th className="pb-2">Symbol</th>
                    <th className="pb-2">Shares</th>
                    <th className="pb-2">Price</th>
                    <th className="pb-2">Change</th>
                    <th className="pb-2 text-right">Value</th>
                  </tr>
                </thead>
                <tbody>
                  {mockHoldings.map((holding) => (
                    <Link key={holding.id} href={`/portfolio/${holding.id}`} className="contents">
                      <HoldingRow holding={holding} />
                    </Link>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>

        <Card>
          <h2 className="mb-4 text-lg font-semibold">Allocation</h2>
          <SpendingPieChart
            data={mockHoldings.map((h) => ({ name: h.symbol, value: h.value }))}
          />
        </Card>
      </div>
    </div>
  );
}

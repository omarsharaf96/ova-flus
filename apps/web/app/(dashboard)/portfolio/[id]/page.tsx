'use client';

import { Card } from '@/components/ui/Card';
import { PortfolioLineChart } from '@/components/charts/PortfolioLineChart';

const mockHolding = {
  symbol: 'AAPL',
  name: 'Apple Inc.',
  shares: 10,
  avgCost: 172.50,
  currentPrice: 185.42,
  dayChange: 2.15,
  dayChangePercent: 1.17,
  totalGain: 129.20,
  totalGainPercent: 7.49,
};

const mockPerformance = [
  { date: '2024-01-01', value: 172.50 },
  { date: '2024-01-15', value: 175.20 },
  { date: '2024-01-29', value: 178.90 },
  { date: '2024-02-05', value: 180.10 },
  { date: '2024-02-12', value: 183.27 },
  { date: '2024-02-14', value: 185.42 },
];

export default function PortfolioDetailPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{mockHolding.symbol}</h1>
        <p className="text-[hsl(var(--muted-foreground))]">{mockHolding.name}</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Current Price</p>
          <p className="text-xl font-bold">${mockHolding.currentPrice}</p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Day Change</p>
          <p className={`text-xl font-bold ${mockHolding.dayChange >= 0 ? 'text-success' : 'text-danger'}`}>
            {mockHolding.dayChange >= 0 ? '+' : ''}${mockHolding.dayChange} ({mockHolding.dayChangePercent}%)
          </p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Total Gain/Loss</p>
          <p className={`text-xl font-bold ${mockHolding.totalGain >= 0 ? 'text-success' : 'text-danger'}`}>
            {mockHolding.totalGain >= 0 ? '+' : ''}${mockHolding.totalGain} ({mockHolding.totalGainPercent}%)
          </p>
        </Card>
        <Card>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">Shares</p>
          <p className="text-xl font-bold">{mockHolding.shares}</p>
          <p className="text-xs text-[hsl(var(--muted-foreground))]">Avg. cost: ${mockHolding.avgCost}</p>
        </Card>
      </div>

      <Card>
        <h2 className="mb-4 text-lg font-semibold">Performance</h2>
        <PortfolioLineChart data={mockPerformance} />
      </Card>
    </div>
  );
}

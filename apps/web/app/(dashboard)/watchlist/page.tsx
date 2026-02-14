'use client';

import { StockQuoteCard } from '@/components/portfolio/StockQuoteCard';
import { Button } from '@/components/ui/Button';

const mockWatchlist = [
  { symbol: 'TSLA', name: 'Tesla Inc.', price: 193.57, change: -4.23, changePercent: -2.14 },
  { symbol: 'NVDA', name: 'NVIDIA Corp.', price: 722.48, change: 12.35, changePercent: 1.74 },
  { symbol: 'META', name: 'Meta Platforms', price: 473.28, change: 5.67, changePercent: 1.21 },
  { symbol: 'JPM', name: 'JPMorgan Chase', price: 183.21, change: -1.05, changePercent: -0.57 },
  { symbol: 'V', name: 'Visa Inc.', price: 279.55, change: 0.82, changePercent: 0.29 },
];

export default function WatchlistPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Watchlist</h1>
        <Button>Add Ticker</Button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {mockWatchlist.map((stock) => (
          <StockQuoteCard key={stock.symbol} stock={stock} />
        ))}
      </div>
    </div>
  );
}

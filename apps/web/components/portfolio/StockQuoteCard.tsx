import { Card } from '@/components/ui/Card';

interface StockQuoteCardProps {
  stock: {
    symbol: string;
    name: string;
    price: number;
    change: number;
    changePercent: number;
  };
}

export function StockQuoteCard({ stock }: StockQuoteCardProps) {
  const isPositive = stock.change >= 0;

  return (
    <Card className="transition-shadow hover:shadow-md">
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-lg font-bold">{stock.symbol}</h3>
          <p className="text-sm text-[hsl(var(--muted-foreground))]">{stock.name}</p>
        </div>
        <div className="text-right">
          <p className="text-lg font-bold">${stock.price.toFixed(2)}</p>
          <p className={`text-sm font-medium ${isPositive ? 'text-success' : 'text-danger'}`}>
            {isPositive ? '+' : ''}{stock.change.toFixed(2)} ({stock.changePercent.toFixed(2)}%)
          </p>
        </div>
      </div>
    </Card>
  );
}

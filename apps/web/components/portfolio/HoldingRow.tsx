interface HoldingRowProps {
  holding: {
    symbol: string;
    shares: number;
    price: number;
    change: number;
    changePercent: number;
    value: number;
  };
}

export function HoldingRow({ holding }: HoldingRowProps) {
  return (
    <tr className="border-b border-[hsl(var(--border))] hover:bg-[hsl(var(--muted))] cursor-pointer">
      <td className="py-3 font-medium">{holding.symbol}</td>
      <td className="py-3">{holding.shares}</td>
      <td className="py-3">${holding.price.toFixed(2)}</td>
      <td className={`py-3 ${holding.change >= 0 ? 'text-success' : 'text-danger'}`}>
        {holding.change >= 0 ? '+' : ''}{holding.change.toFixed(2)} ({holding.changePercent.toFixed(2)}%)
      </td>
      <td className="py-3 text-right font-medium">${holding.value.toFixed(2)}</td>
    </tr>
  );
}

'use client';

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface PortfolioLineChartProps {
  data: { date: string; value: number }[];
}

export function PortfolioLineChart({ data }: PortfolioLineChartProps) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
        <XAxis dataKey="date" tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 12 }} domain={['auto', 'auto']} />
        <Tooltip formatter={(value: number) => `$${value.toFixed(2)}`} />
        <Line
          type="monotone"
          dataKey="value"
          stroke="#0c8ce9"
          strokeWidth={2}
          dot={false}
          activeDot={{ r: 4 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

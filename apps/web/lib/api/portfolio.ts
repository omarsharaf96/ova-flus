import { apiClient } from './client';

export interface Portfolio {
  id: string;
  name: string;
  totalValue: number;
  dayChange: number;
  dayChangePercent: number;
  holdings: Holding[];
}

export interface Holding {
  id: string;
  symbol: string;
  name: string;
  shares: number;
  avgCost: number;
  currentPrice: number;
  value: number;
  change: number;
  changePercent: number;
}

export function getPortfolios() {
  return apiClient<Portfolio[]>('/portfolios');
}

export function getPortfolio(id: string) {
  return apiClient<Portfolio>(`/portfolios/${id}`);
}

export function getPortfolioPerformance(id: string, period: string = '1M') {
  return apiClient<{ date: string; value: number }[]>(
    `/portfolios/${id}/performance?period=${period}`
  );
}

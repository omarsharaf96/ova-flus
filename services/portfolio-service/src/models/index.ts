export interface Portfolio {
  id: string;
  userId: string;
  name: string;
  description: string;
  totalValue: number;
  totalCost: number;
  totalGainLoss: number;
  totalGainLossPercent: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface Holding {
  id: string;
  portfolioId: string;
  symbol: string;
  companyName: string;
  shares: number;
  averageCost: number;
  currentPrice: number;
  marketValue: number;
  gainLoss: number;
  gainLossPercent: number;
  purchaseDate: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface PortfolioPerformance {
  portfolioId: string;
  timeframe: string;
  totalReturn: number;
  totalReturnPercent: number;
  dailyChange: number;
  dailyChangePercent: number;
  history: { date: string; value: number }[];
}

export interface AssetAllocation {
  portfolioId: string;
  allocations: {
    sector: string;
    value: number;
    percentage: number;
    holdings: string[];
  }[];
}

export interface Watchlist {
  id: string;
  userId: string;
  name: string;
  items: WatchlistItem[];
  createdAt: Date;
  updatedAt: Date;
}

export interface WatchlistItem {
  symbol: string;
  companyName: string;
  currentPrice: number;
  dailyChange: number;
  dailyChangePercent: number;
  addedAt: Date;
}

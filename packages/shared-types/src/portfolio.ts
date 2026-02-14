import type { TimeFrame } from './market';

export enum AssetType {
  STOCK = 'STOCK',
  ETF = 'ETF',
  MUTUAL_FUND = 'MUTUAL_FUND',
  BOND = 'BOND',
  CRYPTO = 'CRYPTO',
}

export interface Portfolio {
  id: string;
  userId: string;
  name: string;
  type: 'retirement' | 'personal' | 'taxable' | 'other';
  totalValue: number;
  totalCost: number;
  totalGain: number;
  totalGainPercent: number;
  dayChange: number;
  dayChangePercent: number;
  holdings: Holding[];
  currency: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Holding {
  id: string;
  portfolioId: string;
  symbol: string;
  name: string;
  assetType: AssetType;
  quantity: number;
  averageCost: number;
  currentPrice: number;
  totalValue: number;
  totalCost: number;
  gain: number;
  gainPercent: number;
  dayChange: number;
  dayChangePercent: number;
  taxLots: TaxLot[];
  addedAt: Date;
}

export interface TaxLot {
  id: string;
  holdingId: string;
  quantity: number;
  purchasePrice: number;
  purchaseDate: Date;
  gainLoss: number;
  gainLossPercent: number;
  holdingPeriod: 'short' | 'long';
}

export interface Watchlist {
  id: string;
  userId: string;
  name: string;
  items: WatchlistItem[];
}

export interface WatchlistItem {
  id: string;
  watchlistId: string;
  symbol: string;
  name: string;
  assetType: AssetType;
  currentPrice: number;
  dayChange: number;
  dayChangePercent: number;
  targetPrice?: number;
  alertEnabled: boolean;
  addedAt: Date;
}

export interface PortfolioAllocation {
  sector: string;
  value: number;
  percentage: number;
}

export interface PortfolioPerformance {
  portfolioId: string;
  period: TimeFrame;
  startValue: number;
  endValue: number;
  return: number;
  returnPercent: number;
  benchmark?: BenchmarkComparison;
}

export interface BenchmarkComparison {
  name: string;
  return: number;
  returnPercent: number;
}

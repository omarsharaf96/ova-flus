export interface StockQuote {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  marketCap: number;
  peRatio?: number;
  dividendYield?: number;
  high52w: number;
  low52w: number;
  exchange: string;
  timestamp: Date;
}

export interface HistoricalPrice {
  symbol: string;
  date: Date;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
  adjustedClose: number;
}

export enum TimeFrame {
  ONE_DAY = '1D',
  ONE_WEEK = '1W',
  ONE_MONTH = '1M',
  THREE_MONTHS = '3M',
  ONE_YEAR = '1Y',
  FIVE_YEARS = '5Y',
  ALL = 'ALL',
}

export interface MarketNews {
  id: string;
  headline: string;
  summary: string;
  url: string;
  source: string;
  publishedAt: Date;
  relatedSymbols: string[];
}

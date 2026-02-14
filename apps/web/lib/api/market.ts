import { apiClient } from './client';

export interface StockQuote {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  marketCap: number;
}

export function getQuote(symbol: string) {
  return apiClient<StockQuote>(`/market/quote/${symbol}`);
}

export function getQuotes(symbols: string[]) {
  return apiClient<StockQuote[]>(`/market/quotes?symbols=${symbols.join(',')}`);
}

export function searchStocks(query: string) {
  return apiClient<{ symbol: string; name: string }[]>(`/market/search?q=${encodeURIComponent(query)}`);
}

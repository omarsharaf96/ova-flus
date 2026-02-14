import { useQuery } from '@tanstack/react-query';
import { getPortfolios, getPortfolio, getPortfolioPerformance } from '@/lib/api/portfolio';

export function usePortfolios() {
  return useQuery({ queryKey: ['portfolios'], queryFn: getPortfolios });
}

export function usePortfolio(id: string) {
  return useQuery({ queryKey: ['portfolios', id], queryFn: () => getPortfolio(id) });
}

export function usePortfolioPerformance(id: string, period: string = '1M') {
  return useQuery({
    queryKey: ['portfolios', id, 'performance', period],
    queryFn: () => getPortfolioPerformance(id, period),
  });
}

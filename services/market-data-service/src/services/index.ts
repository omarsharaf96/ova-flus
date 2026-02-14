import yahooFinance from 'yahoo-finance2';

// Timeframe → Yahoo Finance period mapping
const timeframeToPeriod: Record<string, { period1: string; interval: string }> = {
  '1D': { period1: new Date(Date.now() - 86400000).toISOString().split('T')[0], interval: '5m' },
  '1W': { period1: new Date(Date.now() - 7 * 86400000).toISOString().split('T')[0], interval: '1h' },
  '1M': { period1: new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0], interval: '1d' },
  '3M': { period1: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0], interval: '1d' },
  '1Y': { period1: new Date(Date.now() - 365 * 86400000).toISOString().split('T')[0], interval: '1wk' },
  '5Y': { period1: new Date(Date.now() - 5 * 365 * 86400000).toISOString().split('T')[0], interval: '1mo' },
  'ALL': { period1: '2000-01-01', interval: '1mo' },
};

export const marketDataService = {
  async getQuote(symbol: string) {
    const result = await yahooFinance.quote(symbol);
    return {
      symbol: result.symbol,
      name: result.longName ?? result.shortName ?? symbol,
      price: result.regularMarketPrice ?? 0,
      change: result.regularMarketChange ?? 0,
      changePercent: result.regularMarketChangePercent ?? 0,
      volume: result.regularMarketVolume ?? 0,
      marketCap: result.marketCap ?? 0,
      peRatio: result.trailingPE ?? null,
      dividendYield: result.dividendYield ?? null,
      high52w: result.fiftyTwoWeekHigh ?? 0,
      low52w: result.fiftyTwoWeekLow ?? 0,
      open: result.regularMarketOpen ?? 0,
      high: result.regularMarketDayHigh ?? 0,
      low: result.regularMarketDayLow ?? 0,
      exchange: result.exchange ?? '',
      preMarketPrice: result.preMarketPrice ?? null,
      postMarketPrice: result.postMarketPrice ?? null,
      timestamp: new Date().toISOString(),
    };
  },

  async getHistory(symbol: string, timeframe: string) {
    const mapping = timeframeToPeriod[timeframe] ?? timeframeToPeriod['1M'];
    const result = await yahooFinance.chart(symbol, {
      period1: mapping.period1,
      interval: mapping.interval as any,
    });

    return (result.quotes ?? []).map((q: any) => ({
      date: new Date(q.date).toISOString(),
      open: q.open ?? 0,
      high: q.high ?? 0,
      low: q.low ?? 0,
      close: q.close ?? 0,
      volume: q.volume ?? 0,
      adjustedClose: q.adjclose ?? q.close ?? 0,
    }));
  },

  async search(query: string) {
    const result = await yahooFinance.search(query);
    return (result.quotes ?? [])
      .filter((q: any) => q.quoteType === 'EQUITY' || q.quoteType === 'ETF')
      .slice(0, 10)
      .map((q: any) => ({
        symbol: q.symbol,
        name: q.longname ?? q.shortname ?? q.symbol,
        exchange: q.exchDisp ?? '',
        type: q.quoteType ?? '',
      }));
  },

  async getNews(symbol: string) {
    const result = await yahooFinance.search(symbol, { newsCount: 10, quotesCount: 0 });
    return (result.news ?? []).map((article: any) => ({
      id: article.uuid,
      headline: article.title,
      summary: article.summary ?? '',
      url: article.link,
      source: article.publisher,
      publishedAt: new Date(article.providerPublishTime * 1000).toISOString(),
      relatedSymbols: article.relatedTickers ?? [],
    }));
  },
};

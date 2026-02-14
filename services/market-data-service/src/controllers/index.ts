import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { marketDataService } from '../services';

export const marketDataController = {
  async getQuote(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const quote = await marketDataService.getQuote(req.params.symbol);
      res.json(quote);
    } catch (error) {
      next(error);
    }
  },

  async getHistory(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { timeframe } = req.query;
      const history = await marketDataService.getHistory(
        req.params.symbol,
        (timeframe as string) || '1M',
      );
      res.json(history);
    } catch (error) {
      next(error);
    }
  },

  async search(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { q } = req.query;
      const results = await marketDataService.search(q as string);
      res.json(results);
    } catch (error) {
      next(error);
    }
  },

  async getNews(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const news = await marketDataService.getNews(req.params.symbol);
      res.json(news);
    } catch (error) {
      next(error);
    }
  },
};

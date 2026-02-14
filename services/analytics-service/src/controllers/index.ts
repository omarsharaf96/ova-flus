import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { analyticsService } from '../services';

export const analyticsController = {
  async getSpendingSummary(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { period, startDate, endDate } = req.query;
      const summary = await analyticsService.getSpendingSummary(req.userId!, {
        period: period as string,
        startDate: startDate as string,
        endDate: endDate as string,
      });
      res.json(summary);
    } catch (error) {
      next(error);
    }
  },

  async getBudgetVsActual(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { budgetId, period } = req.query;
      const comparison = await analyticsService.getBudgetVsActual(req.userId!, {
        budgetId: budgetId as string,
        period: period as string,
      });
      res.json(comparison);
    } catch (error) {
      next(error);
    }
  },

  async getTrends(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { type, months } = req.query;
      const trends = await analyticsService.getTrends(req.userId!, {
        type: type as string,
        months: Number(months) || 6,
      });
      res.json(trends);
    } catch (error) {
      next(error);
    }
  },

  async getPortfolioPerformance(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { portfolioId, timeframe } = req.query;
      const performance = await analyticsService.getPortfolioPerformance(req.userId!, {
        portfolioId: portfolioId as string,
        timeframe: timeframe as string,
      });
      res.json(performance);
    } catch (error) {
      next(error);
    }
  },

  async generateReport(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { type, format, startDate, endDate } = req.body;
      const report = await analyticsService.generateReport(req.userId!, {
        type,
        format,
        startDate,
        endDate,
      });
      res.json(report);
    } catch (error) {
      next(error);
    }
  },
};

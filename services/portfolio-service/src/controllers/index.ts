import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { portfolioService } from '../services';

export const portfolioController = {
  async list(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const portfolios = await portfolioService.list(req.userId!);
      res.json(portfolios);
    } catch (error) {
      next(error);
    }
  },

  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const portfolio = await portfolioService.create(req.userId!, req.body);
      res.status(201).json(portfolio);
    } catch (error) {
      next(error);
    }
  },

  async getById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const portfolio = await portfolioService.getById(req.userId!, req.params.id);
      res.json(portfolio);
    } catch (error) {
      next(error);
    }
  },

  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const portfolio = await portfolioService.update(req.userId!, req.params.id, req.body);
      res.json(portfolio);
    } catch (error) {
      next(error);
    }
  },

  async remove(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await portfolioService.remove(req.userId!, req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async listHoldings(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const holdings = await portfolioService.listHoldings(req.userId!, req.params.id);
      res.json(holdings);
    } catch (error) {
      next(error);
    }
  },

  async addHolding(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const holding = await portfolioService.addHolding(req.userId!, req.params.id, req.body);
      res.status(201).json(holding);
    } catch (error) {
      next(error);
    }
  },

  async updateHolding(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const holding = await portfolioService.updateHolding(
        req.userId!,
        req.params.id,
        req.params.holdingId,
        req.body,
      );
      res.json(holding);
    } catch (error) {
      next(error);
    }
  },

  async removeHolding(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await portfolioService.removeHolding(req.userId!, req.params.id, req.params.holdingId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async getPerformance(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { timeframe } = req.query;
      const performance = await portfolioService.getPerformance(
        req.userId!,
        req.params.id,
        timeframe as string,
      );
      res.json(performance);
    } catch (error) {
      next(error);
    }
  },

  async getAllocation(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const allocation = await portfolioService.getAllocation(req.userId!, req.params.id);
      res.json(allocation);
    } catch (error) {
      next(error);
    }
  },

  async listWatchlists(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const watchlists = await portfolioService.listWatchlists(req.userId!);
      res.json(watchlists);
    } catch (error) {
      next(error);
    }
  },

  async createWatchlist(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const watchlist = await portfolioService.createWatchlist(req.userId!, req.body);
      res.status(201).json(watchlist);
    } catch (error) {
      next(error);
    }
  },

  async getWatchlist(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const watchlist = await portfolioService.getWatchlist(req.userId!, req.params.id);
      res.json(watchlist);
    } catch (error) {
      next(error);
    }
  },

  async removeWatchlist(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await portfolioService.removeWatchlist(req.userId!, req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async addWatchlistItem(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const item = await portfolioService.addWatchlistItem(req.userId!, req.params.id, req.body);
      res.status(201).json(item);
    } catch (error) {
      next(error);
    }
  },

  async removeWatchlistItem(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await portfolioService.removeWatchlistItem(req.userId!, req.params.id, req.params.symbol);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

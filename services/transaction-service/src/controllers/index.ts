import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { transactionService } from '../services';

export const transactionController = {
  async list(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { page, limit, category, startDate, endDate } = req.query;
      const transactions = await transactionService.list(req.userId!, {
        page: Number(page) || 1,
        limit: Number(limit) || 20,
        category: category as string,
        startDate: startDate as string,
        endDate: endDate as string,
      });
      res.json(transactions);
    } catch (error) {
      next(error);
    }
  },

  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const transaction = await transactionService.create(req.userId!, req.body);
      res.status(201).json(transaction);
    } catch (error) {
      next(error);
    }
  },

  async getById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const transaction = await transactionService.getById(req.userId!, req.params.id);
      res.json(transaction);
    } catch (error) {
      next(error);
    }
  },

  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const transaction = await transactionService.update(req.userId!, req.params.id, req.body);
      res.json(transaction);
    } catch (error) {
      next(error);
    }
  },

  async remove(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await transactionService.remove(req.userId!, req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async listRecurring(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const recurring = await transactionService.listRecurring(req.userId!);
      res.json(recurring);
    } catch (error) {
      next(error);
    }
  },

  async createRecurring(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const recurring = await transactionService.createRecurring(req.userId!, req.body);
      res.status(201).json(recurring);
    } catch (error) {
      next(error);
    }
  },

  async listIncome(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const income = await transactionService.listIncome(req.userId!);
      res.json(income);
    } catch (error) {
      next(error);
    }
  },

  async createIncome(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const income = await transactionService.createIncome(req.userId!, req.body);
      res.status(201).json(income);
    } catch (error) {
      next(error);
    }
  },

  async getSummary(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { startDate, endDate } = req.query;
      const summary = await transactionService.getSummary(
        req.userId!,
        startDate as string,
        endDate as string,
      );
      res.json(summary);
    } catch (error) {
      next(error);
    }
  },

  async importCsv(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      // TODO: Use multer middleware for file upload
      const result = await transactionService.importCsv(req.userId!, req.body);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },
};

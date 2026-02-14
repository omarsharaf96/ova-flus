import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { budgetService } from '../services';

export const budgetController = {
  async list(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budgets = await budgetService.listBudgets(req.userId!);
      res.json(budgets);
    } catch (error) {
      next(error);
    }
  },

  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budget = await budgetService.createBudget(req.userId!, req.body);
      res.status(201).json(budget);
    } catch (error) {
      next(error);
    }
  },

  async getById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budget = await budgetService.getBudget(req.userId!, req.params.id);
      res.json(budget);
    } catch (error) {
      next(error);
    }
  },

  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budget = await budgetService.updateBudget(req.userId!, req.params.id, req.body);
      res.json(budget);
    } catch (error) {
      next(error);
    }
  },

  async remove(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await budgetService.deleteBudget(req.userId!, req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async listCategories(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const categories = await budgetService.listCategories(req.userId!, req.params.id);
      res.json(categories);
    } catch (error) {
      next(error);
    }
  },

  async addCategory(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const category = await budgetService.addCategory(req.userId!, req.params.id, req.body);
      res.status(201).json(category);
    } catch (error) {
      next(error);
    }
  },

  async updateCategory(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const category = await budgetService.updateCategory(
        req.userId!,
        req.params.id,
        req.params.catId,
        req.body,
      );
      res.json(category);
    } catch (error) {
      next(error);
    }
  },

  async removeCategory(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await budgetService.removeCategory(req.userId!, req.params.id, req.params.catId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  async listTemplates(_req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const templates = await budgetService.listTemplates();
      res.json(templates);
    } catch (error) {
      next(error);
    }
  },

  async createFromTemplate(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budget = await budgetService.createFromTemplate(req.userId!, req.body.templateId);
      res.status(201).json(budget);
    } catch (error) {
      next(error);
    }
  },
};

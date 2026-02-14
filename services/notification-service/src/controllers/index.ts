import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { notificationService } from '../services';

export const notificationController = {
  async list(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { page, limit, unreadOnly } = req.query;
      const notifications = await notificationService.list(req.userId!, {
        page: Number(page) || 1,
        limit: Number(limit) || 20,
        unreadOnly: unreadOnly === 'true',
      });
      res.json(notifications);
    } catch (error) {
      next(error);
    }
  },

  async markRead(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await notificationService.markRead(req.userId!, req.params.id);
      res.json({ success: true });
    } catch (error) {
      next(error);
    }
  },

  async markAllRead(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await notificationService.markAllRead(req.userId!);
      res.json({ success: true });
    } catch (error) {
      next(error);
    }
  },

  async getPreferences(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const prefs = await notificationService.getPreferences(req.userId!);
      res.json(prefs);
    } catch (error) {
      next(error);
    }
  },

  async updatePreferences(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const prefs = await notificationService.updatePreferences(req.userId!, req.body);
      res.json(prefs);
    } catch (error) {
      next(error);
    }
  },

  async createBudgetAlert(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const alert = await notificationService.createBudgetAlert(req.userId!, req.body);
      res.status(201).json(alert);
    } catch (error) {
      next(error);
    }
  },

  async createStockPriceAlert(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const alert = await notificationService.createStockPriceAlert(req.userId!, req.body);
      res.status(201).json(alert);
    } catch (error) {
      next(error);
    }
  },

  async listAlerts(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const alerts = await notificationService.listAlerts(req.userId!);
      res.json(alerts);
    } catch (error) {
      next(error);
    }
  },

  async removeAlert(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      await notificationService.removeAlert(req.userId!, req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

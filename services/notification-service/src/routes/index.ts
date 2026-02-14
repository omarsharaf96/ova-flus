import { Router } from 'express';
import { notificationController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Notifications
router.get('/notifications', notificationController.list);
router.put('/notifications/:id/read', notificationController.markRead);
router.put('/notifications/read-all', notificationController.markAllRead);

// Preferences
router.get('/notifications/preferences', notificationController.getPreferences);
router.post('/notifications/preferences', notificationController.updatePreferences);

// Alerts
router.post('/alerts/budget', notificationController.createBudgetAlert);
router.post('/alerts/stock-price', notificationController.createStockPriceAlert);
router.get('/alerts', notificationController.listAlerts);
router.delete('/alerts/:id', notificationController.removeAlert);

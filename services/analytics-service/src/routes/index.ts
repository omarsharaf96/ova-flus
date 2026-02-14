import { Router } from 'express';
import { analyticsController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Analytics endpoints
router.get('/analytics/spending-summary', analyticsController.getSpendingSummary);
router.get('/analytics/budget-vs-actual', analyticsController.getBudgetVsActual);
router.get('/analytics/trends', analyticsController.getTrends);
router.get('/analytics/portfolio-performance', analyticsController.getPortfolioPerformance);

// Report generation
router.post('/reports/generate', analyticsController.generateReport);

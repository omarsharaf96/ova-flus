import { Router } from 'express';
import { portfolioController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Portfolios CRUD
router.get('/portfolios', portfolioController.list);
router.post('/portfolios', portfolioController.create);
router.get('/portfolios/:id', portfolioController.getById);
router.put('/portfolios/:id', portfolioController.update);
router.delete('/portfolios/:id', portfolioController.remove);

// Holdings
router.get('/portfolios/:id/holdings', portfolioController.listHoldings);
router.post('/portfolios/:id/holdings', portfolioController.addHolding);
router.put('/portfolios/:id/holdings/:holdingId', portfolioController.updateHolding);
router.delete('/portfolios/:id/holdings/:holdingId', portfolioController.removeHolding);

// Performance & Allocation
router.get('/portfolios/:id/performance', portfolioController.getPerformance);
router.get('/portfolios/:id/allocation', portfolioController.getAllocation);

// Watchlists
router.get('/watchlists', portfolioController.listWatchlists);
router.post('/watchlists', portfolioController.createWatchlist);
router.get('/watchlists/:id', portfolioController.getWatchlist);
router.delete('/watchlists/:id', portfolioController.removeWatchlist);
router.post('/watchlists/:id/items', portfolioController.addWatchlistItem);
router.delete('/watchlists/:id/items/:symbol', portfolioController.removeWatchlistItem);

import { Router } from 'express';
import { marketDataController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Stock quotes and data
router.get('/stocks/:symbol/quote', marketDataController.getQuote);
router.get('/stocks/:symbol/history', marketDataController.getHistory);
router.get('/stocks/search', marketDataController.search);
router.get('/stocks/:symbol/news', marketDataController.getNews);

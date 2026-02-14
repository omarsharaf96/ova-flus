import { Router } from 'express';
import { transactionController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Transactions CRUD
router.get('/transactions', transactionController.list);
router.post('/transactions', transactionController.create);
router.get('/transactions/:id', transactionController.getById);
router.put('/transactions/:id', transactionController.update);
router.delete('/transactions/:id', transactionController.remove);

// Recurring transactions
router.get('/transactions/recurring', transactionController.listRecurring);
router.post('/transactions/recurring', transactionController.createRecurring);

// Income
router.get('/income', transactionController.listIncome);
router.post('/income', transactionController.createIncome);

// Summary & Import
router.get('/transactions/summary', transactionController.getSummary);
router.post('/transactions/import', transactionController.importCsv);

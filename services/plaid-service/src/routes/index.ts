import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validation';
import { exchangeTokenSchema } from '../models';
import * as controllers from '../controllers';

export const router = Router();

// Webhook route MUST be registered before authenticate middleware
router.post('/plaid/webhooks', controllers.handleWebhook);

// All routes below require authentication
router.use(authenticate);

router.post('/plaid/link-token', controllers.createLinkToken);
router.post('/plaid/exchange-token', validate(exchangeTokenSchema), controllers.exchangeToken);
router.get('/plaid/accounts', controllers.getAccounts);
router.post('/plaid/sync', controllers.syncTransactions);
router.delete('/plaid/accounts/:id', controllers.deleteAccount);

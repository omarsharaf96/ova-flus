import { Router } from 'express';
import { budgetController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

router.use(authenticate);

// Budget CRUD
router.get('/budgets', budgetController.list);
router.post('/budgets', budgetController.create);
router.get('/budgets/:id', budgetController.getById);
router.put('/budgets/:id', budgetController.update);
router.delete('/budgets/:id', budgetController.remove);

// Budget categories
router.get('/budgets/:id/categories', budgetController.listCategories);
router.post('/budgets/:id/categories', budgetController.addCategory);
router.put('/budgets/:id/categories/:catId', budgetController.updateCategory);
router.delete('/budgets/:id/categories/:catId', budgetController.removeCategory);

// Budget templates
router.get('/budgets/templates', budgetController.listTemplates);
router.post('/budgets/templates', budgetController.createFromTemplate);

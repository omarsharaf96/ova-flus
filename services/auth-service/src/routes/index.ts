import { Router } from 'express';
import { authController } from '../controllers';
import { authenticate } from '../middleware/auth';

export const router = Router();

// Public routes
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.post('/auth/refresh', authController.refreshToken);

// Protected routes
router.post('/auth/logout', authenticate, authController.logout);
router.get('/auth/me', authenticate, authController.getProfile);
router.put('/auth/me', authenticate, authController.updateProfile);
router.post('/auth/mfa/setup', authenticate, authController.setupMfa);
router.post('/auth/mfa/verify', authenticate, authController.verifyMfa);

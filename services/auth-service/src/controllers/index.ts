import { Request, Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { authService } from '../services';

export const authController = {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with AWS Cognito signUp
      const { email, password, firstName, lastName } = req.body;
      const result = await authService.register({ email, password, firstName, lastName });
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  },

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with AWS Cognito initiateAuth
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },

  async refreshToken(req: Request, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with Cognito token refresh
      const { refreshToken } = req.body;
      const result = await authService.refreshToken(refreshToken);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },

  async logout(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with Cognito globalSignOut
      await authService.logout(req.userId!);
      res.json({ message: 'Logged out successfully' });
    } catch (error) {
      next(error);
    }
  },

  async getProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await authService.getProfile(req.userId!);
      res.json(profile);
    } catch (error) {
      next(error);
    }
  },

  async updateProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await authService.updateProfile(req.userId!, req.body);
      res.json(profile);
    } catch (error) {
      next(error);
    }
  },

  async setupMfa(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with Cognito MFA setup (TOTP)
      const result = await authService.setupMfa(req.userId!);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },

  async verifyMfa(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      // TODO: Integrate with Cognito MFA verification
      const { code } = req.body;
      const result = await authService.verifyMfa(req.userId!, code);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },
};

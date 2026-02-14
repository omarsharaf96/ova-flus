import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as plaidService from '../services';

interface ApiResponse<T> {
  data: T;
  success: boolean;
  timestamp: Date;
}

function respond<T>(res: Response, data: T, status = 200): void {
  const body: ApiResponse<T> = {
    data,
    success: true,
    timestamp: new Date(),
  };
  res.status(status).json(body);
}

export async function createLinkToken(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const result = await plaidService.createLinkToken(req.userId!);
    respond(res, result);
  } catch (error) {
    next(error);
  }
}

export async function exchangeToken(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const { publicToken, institutionId, institutionName } = req.body;
    const result = await plaidService.exchangeToken(req.userId!, publicToken, institutionId, institutionName);
    respond(res, result, 201);
  } catch (error) {
    next(error);
  }
}

export async function getAccounts(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const accounts = await plaidService.getAccounts(req.userId!);
    respond(res, accounts);
  } catch (error) {
    next(error);
  }
}

export async function syncTransactions(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const accountId = req.query.accountId as string | undefined;
    const result = await plaidService.syncTransactions(req.userId!, accountId);
    respond(res, result);
  } catch (error) {
    next(error);
  }
}

export async function deleteAccount(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    await plaidService.deleteAccount(req.userId!, req.params.id);
    respond(res, { deleted: true });
  } catch (error) {
    next(error);
  }
}

export async function handleWebhook(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    await plaidService.handleWebhook(req.body);
    respond(res, { received: true });
  } catch (error) {
    next(error);
  }
}

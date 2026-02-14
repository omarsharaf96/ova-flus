import { apiClient } from './client';

export interface PlaidItem {
  id: string;
  institutionId: string;
  institutionName: string;
  status: 'active' | 'error' | 'pending';
  createdAt: string;
}

export interface BankAccount {
  id: string;
  plaidItemId: string;
  name: string;
  officialName?: string;
  type: 'checking' | 'savings' | 'credit' | 'investment' | 'other';
  subtype?: string;
  mask?: string;
  currentBalance?: number;
  availableBalance?: number;
  currency: string;
  lastSynced?: string;
}

export interface LinkTokenResponse {
  linkToken: string;
  expiration: string;
}

export interface ExchangeTokenResponse {
  item: PlaidItem;
  accounts: BankAccount[];
}

export interface SyncResult {
  added: number;
  modified: number;
  removed: number;
}

export function createLinkToken() {
  return apiClient<LinkTokenResponse>('/plaid/link-token', { method: 'POST' });
}

export function exchangeToken(publicToken: string, institutionId: string, institutionName: string) {
  return apiClient<ExchangeTokenResponse>('/plaid/exchange-token', {
    method: 'POST',
    body: { publicToken, institutionId, institutionName },
  });
}

export function getLinkedAccounts() {
  return apiClient<BankAccount[]>('/plaid/accounts');
}

export function syncTransactions(accountId?: string) {
  return apiClient<SyncResult>('/plaid/sync', {
    method: 'POST',
    body: accountId ? { accountId } : {},
  });
}

export function unlinkAccount(accountId: string) {
  return apiClient<void>(`/plaid/accounts/${accountId}`, { method: 'DELETE' });
}

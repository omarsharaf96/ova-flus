import { apiClient } from './client';

export interface Transaction {
  id: string;
  description: string;
  amount: number;
  category: string;
  budgetId?: string;
  date: string;
  createdAt: string;
}

export interface CreateTransactionInput {
  description: string;
  amount: number;
  category: string;
  budgetId?: string;
  date: string;
}

export function getTransactions(params?: { budgetId?: string; limit?: number }) {
  const query = new URLSearchParams();
  if (params?.budgetId) query.set('budgetId', params.budgetId);
  if (params?.limit) query.set('limit', String(params.limit));
  const qs = query.toString();
  return apiClient<Transaction[]>(`/transactions${qs ? `?${qs}` : ''}`);
}

export function createTransaction(input: CreateTransactionInput) {
  return apiClient<Transaction>('/transactions', { method: 'POST', body: input });
}

export function deleteTransaction(id: string) {
  return apiClient<void>(`/transactions/${id}`, { method: 'DELETE' });
}

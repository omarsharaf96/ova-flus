import { apiClient } from './client';

export interface Budget {
  id: string;
  name: string;
  limit: number;
  spent: number;
  period: 'monthly' | 'yearly';
  categories: string[];
  createdAt: string;
}

export interface CreateBudgetInput {
  name: string;
  limit: number;
  period: 'monthly' | 'yearly';
  categories: string[];
}

export function getBudgets() {
  return apiClient<Budget[]>('/budgets');
}

export function getBudget(id: string) {
  return apiClient<Budget>(`/budgets/${id}`);
}

export function createBudget(input: CreateBudgetInput) {
  return apiClient<Budget>('/budgets', { method: 'POST', body: input });
}

export function updateBudget(id: string, input: Partial<CreateBudgetInput>) {
  return apiClient<Budget>(`/budgets/${id}`, { method: 'PATCH', body: input });
}

export function deleteBudget(id: string) {
  return apiClient<void>(`/budgets/${id}`, { method: 'DELETE' });
}

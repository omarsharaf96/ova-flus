export interface Transaction {
  id: string;
  userId: string;
  type: 'expense' | 'income';
  amount: number;
  currency: string;
  category: string;
  description: string;
  date: Date;
  merchantName?: string;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface RecurringTransaction {
  id: string;
  userId: string;
  type: 'expense' | 'income';
  amount: number;
  currency: string;
  category: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly';
  nextOccurrence: Date;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface TransactionSummary {
  totalIncome: number;
  totalExpenses: number;
  net: number;
  byCategory: { category: string; amount: number; count: number }[];
  period: { startDate: string; endDate: string };
}

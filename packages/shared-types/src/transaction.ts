export enum TransactionType {
  EXPENSE = 'EXPENSE',
  INCOME = 'INCOME',
  TRANSFER = 'TRANSFER',
}

export interface Transaction {
  id: string;
  userId: string;
  type: TransactionType;
  amount: number;
  currency: string;
  originalAmount?: number;
  originalCurrency?: string;
  exchangeRate?: number;
  categoryId?: string;
  subcategoryId?: string;
  merchantName?: string;
  description: string;
  notes?: string;
  date: Date;
  receiptUrl?: string;
  isRecurring: boolean;
  recurringId?: string;
  tags: string[];
  splitTransactions?: SplitTransaction[];
  createdAt: Date;
  updatedAt: Date;
}

export interface RecurringTransaction {
  id: string;
  userId: string;
  type: TransactionType;
  amount: number;
  currency: string;
  categoryId?: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly';
  startDate: Date;
  endDate?: Date;
  nextDate: Date;
  isActive: boolean;
}

export interface SplitTransaction {
  categoryId: string;
  amount: number;
  notes?: string;
}

export interface IncomeSource {
  id: string;
  userId: string;
  name: string;
  type: 'salary' | 'freelance' | 'investment' | 'rental' | 'other';
  amount: number;
  currency: string;
  frequency: 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly';
  isRecurring: boolean;
  taxRate?: number;
}

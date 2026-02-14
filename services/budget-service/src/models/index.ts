export interface Budget {
  id: string;
  userId: string;
  name: string;
  totalAmount: number;
  period: 'weekly' | 'monthly' | 'yearly';
  startDate: Date;
  endDate: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface BudgetCategory {
  id: string;
  budgetId: string;
  name: string;
  allocatedAmount: number;
  spentAmount: number;
  color: string;
  icon: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface BudgetTemplate {
  id: string;
  name: string;
  description: string;
  categories: { name: string; percentage: number }[];
}

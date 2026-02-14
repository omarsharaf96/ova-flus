export interface Budget {
  id: string;
  userId: string;
  name: string;
  description?: string;
  timeframe: 'weekly' | 'monthly' | 'custom';
  startDate: Date;
  endDate: Date;
  totalLimit: number;
  currency: string;
  categories: BudgetCategory[];
  createdAt: Date;
  updatedAt: Date;
}

export interface BudgetCategory {
  id: string;
  budgetId: string;
  name: string;
  color: string;
  icon: string;
  limit: number;
  spent: number;
  subcategories: BudgetSubcategory[];
}

export interface BudgetSubcategory {
  id: string;
  categoryId: string;
  name: string;
  limit: number;
  spent: number;
}

export interface BudgetAlert {
  id: string;
  budgetId: string;
  categoryId?: string;
  threshold: number; // 0-100
  triggered: boolean;
  triggeredAt?: Date;
}

export interface BudgetTemplate {
  id: string;
  name: string;
  description?: string;
  categories: Omit<BudgetCategory, 'id' | 'budgetId' | 'spent'>[];
}

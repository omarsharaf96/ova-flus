export interface SpendingSummary {
  totalSpent: number;
  totalIncome: number;
  net: number;
  dailyAverage: number;
  byCategory: { category: string; amount: number; percentage: number }[];
  topMerchants: { name: string; amount: number; count: number }[];
  period: { startDate: string; endDate: string };
}

export interface BudgetVsActual {
  budgetId: string;
  budgetName: string;
  totalBudget: number;
  totalSpent: number;
  remaining: number;
  categories: {
    name: string;
    budgeted: number;
    actual: number;
    remaining: number;
    percentUsed: number;
  }[];
}

export interface SpendingTrend {
  months: {
    month: string;
    totalSpent: number;
    totalIncome: number;
    net: number;
  }[];
  averageMonthlySpend: number;
  averageMonthlyIncome: number;
  categoryTrends: {
    category: string;
    monthlyAmounts: { month: string; amount: number }[];
  }[];
}

export interface ReportResult {
  reportId: string;
  type: string;
  format: 'pdf' | 'csv';
  downloadUrl: string;
  generatedAt: string;
}

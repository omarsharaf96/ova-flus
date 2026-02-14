export interface Notification {
  id: string;
  userId: string;
  type: 'budget_alert' | 'price_alert' | 'transaction' | 'system' | 'report';
  title: string;
  body: string;
  read: boolean;
  data?: Record<string, unknown>;
  createdAt: Date;
}

export interface NotificationPreferences {
  userId: string;
  pushEnabled: boolean;
  emailEnabled: boolean;
  quietHoursStart?: string;
  quietHoursEnd?: string;
  budgetAlerts: boolean;
  priceAlerts: boolean;
  transactionAlerts: boolean;
  weeklyDigest: boolean;
}

export interface BudgetAlert {
  id: string;
  userId: string;
  budgetId: string;
  threshold: number;
  isActive: boolean;
  lastTriggered?: Date;
  createdAt: Date;
}

export interface StockPriceAlert {
  id: string;
  userId: string;
  symbol: string;
  targetPrice: number;
  direction: 'above' | 'below';
  isActive: boolean;
  lastTriggered?: Date;
  createdAt: Date;
}

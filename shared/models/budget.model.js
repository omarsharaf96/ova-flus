/**
 * Budget Models
 * Shared data structures for budget tracking across all platforms
 */

class BudgetCategory {
  constructor(id, name, limit, spent, color, icon) {
    this.id = id;
    this.name = name;
    this.limit = limit;
    this.spent = spent || 0;
    this.color = color || '#3498db';
    this.icon = icon || 'category';
  }

  getRemainingBalance() {
    return this.limit - this.spent;
  }

  getSpentPercentage() {
    return (this.spent / this.limit) * 100;
  }

  isOverBudget() {
    return this.spent > this.limit;
  }
}

class Transaction {
  constructor(id, categoryId, amount, description, date, type, userId) {
    this.id = id;
    this.categoryId = categoryId;
    this.amount = amount;
    this.description = description;
    this.date = date || new Date();
    this.type = type; // 'expense' or 'income'
    this.userId = userId;
  }
}

class Budget {
  constructor(id, userId, name, period, categories, totalLimit) {
    this.id = id;
    this.userId = userId;
    this.name = name;
    this.period = period; // 'monthly', 'weekly', 'yearly'
    this.categories = categories || [];
    this.totalLimit = totalLimit;
  }

  getTotalSpent() {
    return this.categories.reduce((sum, cat) => sum + cat.spent, 0);
  }

  getRemainingBudget() {
    return this.totalLimit - this.getTotalSpent();
  }

  getBudgetUtilization() {
    return (this.getTotalSpent() / this.totalLimit) * 100;
  }
}

module.exports = {
  BudgetCategory,
  Transaction,
  Budget
};

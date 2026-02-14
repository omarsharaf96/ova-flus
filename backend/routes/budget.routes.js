const express = require('express');
const router = express.Router();

/**
 * Budget Routes
 * Handles budget tracking and management
 */

// Mock data
let budgets = [
  {
    id: '1',
    userId: '1',
    name: 'Monthly Budget',
    period: 'monthly',
    totalLimit: 5000,
    categories: [
      {
        id: '1',
        name: 'Groceries',
        limit: 800,
        spent: 450,
        color: '#4CAF50',
        icon: 'shopping-cart'
      },
      {
        id: '2',
        name: 'Transportation',
        limit: 400,
        spent: 280,
        color: '#2196F3',
        icon: 'directions-car'
      },
      {
        id: '3',
        name: 'Entertainment',
        limit: 300,
        spent: 185,
        color: '#9C27B0',
        icon: 'movie'
      }
    ]
  }
];

let transactions = [
  {
    id: '1',
    categoryId: '1',
    amount: 85.50,
    description: 'Whole Foods Market',
    date: new Date('2024-02-10'),
    type: 'expense',
    userId: '1'
  }
];

// @route   GET /api/budgets
// @desc    Get all budgets for user
// @access  Private
router.get('/', async (req, res) => {
  try {
    res.json({
      success: true,
      data: budgets
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching budgets',
      error: error.message
    });
  }
});

// @route   GET /api/budgets/:id
// @desc    Get budget by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const budget = budgets.find(b => b.id === req.params.id);
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    res.json({
      success: true,
      data: budget
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching budget',
      error: error.message
    });
  }
});

// @route   POST /api/budgets
// @desc    Create new budget
// @access  Private
router.post('/', async (req, res) => {
  try {
    const newBudget = {
      id: Date.now().toString(),
      userId: '1',
      ...req.body,
      categories: req.body.categories || []
    };
    
    budgets.push(newBudget);
    
    res.status(201).json({
      success: true,
      message: 'Budget created successfully',
      data: newBudget
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating budget',
      error: error.message
    });
  }
});

// @route   PUT /api/budgets/:id
// @desc    Update budget
// @access  Private
router.put('/:id', async (req, res) => {
  try {
    const index = budgets.findIndex(b => b.id === req.params.id);
    
    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    budgets[index] = { ...budgets[index], ...req.body };
    
    res.json({
      success: true,
      message: 'Budget updated successfully',
      data: budgets[index]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating budget',
      error: error.message
    });
  }
});

// @route   DELETE /api/budgets/:id
// @desc    Delete budget
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const index = budgets.findIndex(b => b.id === req.params.id);
    
    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    budgets.splice(index, 1);
    
    res.json({
      success: true,
      message: 'Budget deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting budget',
      error: error.message
    });
  }
});

// @route   GET /api/budgets/:id/transactions
// @desc    Get transactions for a budget
// @access  Private
router.get('/:id/transactions', async (req, res) => {
  try {
    const budget = budgets.find(b => b.id === req.params.id);
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    const budgetTransactions = transactions.filter(t => 
      budget.categories.some(c => c.id === t.categoryId)
    );
    
    res.json({
      success: true,
      data: budgetTransactions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching transactions',
      error: error.message
    });
  }
});

// @route   POST /api/budgets/:id/transactions
// @desc    Add transaction to budget
// @access  Private
router.post('/:id/transactions', async (req, res) => {
  try {
    const newTransaction = {
      id: Date.now().toString(),
      userId: '1',
      ...req.body,
      date: req.body.date || new Date()
    };
    
    transactions.push(newTransaction);
    
    // Update category spent amount
    const budget = budgets.find(b => b.id === req.params.id);
    if (budget) {
      const category = budget.categories.find(c => c.id === newTransaction.categoryId);
      if (category) {
        category.spent = (category.spent || 0) + newTransaction.amount;
      }
    }
    
    res.status(201).json({
      success: true,
      message: 'Transaction added successfully',
      data: newTransaction
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding transaction',
      error: error.message
    });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();

/**
 * Portfolio Routes
 * Handles stock portfolio management
 */

// Mock data
let portfolios = [
  {
    id: '1',
    userId: '1',
    name: 'Main Portfolio',
    cash: 5000,
    holdings: [
      {
        id: '1',
        stockId: 'AAPL',
        symbol: 'AAPL',
        shares: 10,
        avgPurchasePrice: 150.00,
        currentPrice: 175.50
      },
      {
        id: '2',
        stockId: 'GOOGL',
        symbol: 'GOOGL',
        shares: 5,
        avgPurchasePrice: 120.00,
        currentPrice: 138.75
      }
    ]
  }
];

let stockTransactions = [
  {
    id: '1',
    portfolioId: '1',
    stockId: 'AAPL',
    symbol: 'AAPL',
    type: 'buy',
    shares: 10,
    price: 150.00,
    date: new Date('2024-01-15'),
    fees: 5.00
  }
];

// @route   GET /api/portfolios
// @desc    Get all portfolios for user
// @access  Private
router.get('/', async (req, res) => {
  try {
    res.json({
      success: true,
      data: portfolios
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching portfolios',
      error: error.message
    });
  }
});

// @route   GET /api/portfolios/:id
// @desc    Get portfolio by ID
// @access  Private
router.get('/:id', async (req, res) => {
  try {
    const portfolio = portfolios.find(p => p.id === req.params.id);
    
    if (!portfolio) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    res.json({
      success: true,
      data: portfolio
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching portfolio',
      error: error.message
    });
  }
});

// @route   POST /api/portfolios
// @desc    Create new portfolio
// @access  Private
router.post('/', async (req, res) => {
  try {
    const newPortfolio = {
      id: Date.now().toString(),
      userId: '1',
      ...req.body,
      holdings: req.body.holdings || [],
      cash: req.body.cash || 0
    };
    
    portfolios.push(newPortfolio);
    
    res.status(201).json({
      success: true,
      message: 'Portfolio created successfully',
      data: newPortfolio
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating portfolio',
      error: error.message
    });
  }
});

// @route   PUT /api/portfolios/:id
// @desc    Update portfolio
// @access  Private
router.put('/:id', async (req, res) => {
  try {
    const index = portfolios.findIndex(p => p.id === req.params.id);
    
    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    portfolios[index] = { ...portfolios[index], ...req.body };
    
    res.json({
      success: true,
      message: 'Portfolio updated successfully',
      data: portfolios[index]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating portfolio',
      error: error.message
    });
  }
});

// @route   DELETE /api/portfolios/:id
// @desc    Delete portfolio
// @access  Private
router.delete('/:id', async (req, res) => {
  try {
    const index = portfolios.findIndex(p => p.id === req.params.id);
    
    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    portfolios.splice(index, 1);
    
    res.json({
      success: true,
      message: 'Portfolio deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting portfolio',
      error: error.message
    });
  }
});

// @route   GET /api/portfolios/:id/transactions
// @desc    Get transactions for a portfolio
// @access  Private
router.get('/:id/transactions', async (req, res) => {
  try {
    const portfolio = portfolios.find(p => p.id === req.params.id);
    
    if (!portfolio) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    const portfolioTransactions = stockTransactions.filter(t => 
      t.portfolioId === req.params.id
    );
    
    res.json({
      success: true,
      data: portfolioTransactions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching transactions',
      error: error.message
    });
  }
});

// @route   POST /api/portfolios/:id/transactions
// @desc    Add transaction to portfolio (buy/sell stocks)
// @access  Private
router.post('/:id/transactions', async (req, res) => {
  try {
    const portfolio = portfolios.find(p => p.id === req.params.id);
    
    if (!portfolio) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    const newTransaction = {
      id: Date.now().toString(),
      portfolioId: req.params.id,
      ...req.body,
      date: req.body.date || new Date()
    };
    
    stockTransactions.push(newTransaction);
    
    // Update portfolio holdings
    if (newTransaction.type === 'buy') {
      const existingHolding = portfolio.holdings.find(h => h.symbol === newTransaction.symbol);
      
      if (existingHolding) {
        const totalShares = existingHolding.shares + newTransaction.shares;
        const totalCost = (existingHolding.shares * existingHolding.avgPurchasePrice) + 
                         (newTransaction.shares * newTransaction.price);
        existingHolding.avgPurchasePrice = totalCost / totalShares;
        existingHolding.shares = totalShares;
      } else {
        portfolio.holdings.push({
          id: Date.now().toString(),
          stockId: newTransaction.stockId,
          symbol: newTransaction.symbol,
          shares: newTransaction.shares,
          avgPurchasePrice: newTransaction.price,
          currentPrice: newTransaction.price
        });
      }
      
      portfolio.cash -= (newTransaction.shares * newTransaction.price + newTransaction.fees);
    } else if (newTransaction.type === 'sell') {
      const holding = portfolio.holdings.find(h => h.symbol === newTransaction.symbol);
      
      if (holding) {
        holding.shares -= newTransaction.shares;
        if (holding.shares <= 0) {
          portfolio.holdings = portfolio.holdings.filter(h => h.symbol !== newTransaction.symbol);
        }
        portfolio.cash += (newTransaction.shares * newTransaction.price - newTransaction.fees);
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

// @route   GET /api/portfolios/:id/performance
// @desc    Get portfolio performance metrics
// @access  Private
router.get('/:id/performance', async (req, res) => {
  try {
    const portfolio = portfolios.find(p => p.id === req.params.id);
    
    if (!portfolio) {
      return res.status(404).json({
        success: false,
        message: 'Portfolio not found'
      });
    }
    
    let totalValue = portfolio.cash;
    let totalCost = 0;
    let totalProfitLoss = 0;
    
    portfolio.holdings.forEach(holding => {
      const currentValue = holding.shares * holding.currentPrice;
      const cost = holding.shares * holding.avgPurchasePrice;
      totalValue += currentValue;
      totalCost += cost;
      totalProfitLoss += (currentValue - cost);
    });
    
    const returnPercentage = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0;
    
    res.json({
      success: true,
      data: {
        totalValue,
        totalCost,
        cash: portfolio.cash,
        profitLoss: totalProfitLoss,
        returnPercentage,
        holdingsCount: portfolio.holdings.length
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error calculating performance',
      error: error.message
    });
  }
});

module.exports = router;

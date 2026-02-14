const express = require('express');
const router = express.Router();

/**
 * Stock Routes
 * Handles stock market data and quotes
 */

// Mock stock data
const mockStocks = {
  'AAPL': {
    symbol: 'AAPL',
    name: 'Apple Inc.',
    currentPrice: 175.50,
    previousClose: 173.25,
    change: 2.25,
    changePercent: 1.30,
    volume: 52000000,
    marketCap: 2750000000000,
    dayHigh: 176.80,
    dayLow: 173.10,
    fiftyTwoWeekHigh: 199.62,
    fiftyTwoWeekLow: 124.17
  },
  'GOOGL': {
    symbol: 'GOOGL',
    name: 'Alphabet Inc.',
    currentPrice: 138.75,
    previousClose: 137.50,
    change: 1.25,
    changePercent: 0.91,
    volume: 25000000,
    marketCap: 1720000000000,
    dayHigh: 139.50,
    dayLow: 137.20,
    fiftyTwoWeekHigh: 151.55,
    fiftyTwoWeekLow: 83.34
  },
  'MSFT': {
    symbol: 'MSFT',
    name: 'Microsoft Corporation',
    currentPrice: 405.30,
    previousClose: 403.75,
    change: 1.55,
    changePercent: 0.38,
    volume: 22000000,
    marketCap: 3010000000000,
    dayHigh: 407.20,
    dayLow: 402.50,
    fiftyTwoWeekHigh: 420.82,
    fiftyTwoWeekLow: 213.43
  },
  'TSLA': {
    symbol: 'TSLA',
    name: 'Tesla, Inc.',
    currentPrice: 188.25,
    previousClose: 192.50,
    change: -4.25,
    changePercent: -2.21,
    volume: 120000000,
    marketCap: 597000000000,
    dayHigh: 194.75,
    dayLow: 186.50,
    fiftyTwoWeekHigh: 299.29,
    fiftyTwoWeekLow: 101.81
  }
};

// @route   GET /api/stocks/quote/:symbol
// @desc    Get stock quote by symbol
// @access  Public
router.get('/quote/:symbol', async (req, res) => {
  try {
    const symbol = req.params.symbol.toUpperCase();
    const stock = mockStocks[symbol];
    
    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Stock not found'
      });
    }
    
    res.json({
      success: true,
      data: stock
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching stock quote',
      error: error.message
    });
  }
});

// @route   GET /api/stocks/search
// @desc    Search for stocks by symbol or name
// @access  Public
router.get('/search', async (req, res) => {
  try {
    const query = req.query.q?.toLowerCase() || '';
    
    if (!query) {
      return res.json({
        success: true,
        data: []
      });
    }
    
    const results = Object.values(mockStocks).filter(stock =>
      stock.symbol.toLowerCase().includes(query) ||
      stock.name.toLowerCase().includes(query)
    );
    
    res.json({
      success: true,
      data: results
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching stocks',
      error: error.message
    });
  }
});

// @route   GET /api/stocks/trending
// @desc    Get trending stocks
// @access  Public
router.get('/trending', async (req, res) => {
  try {
    const trending = Object.values(mockStocks).slice(0, 10);
    
    res.json({
      success: true,
      data: trending
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching trending stocks',
      error: error.message
    });
  }
});

// @route   POST /api/stocks/quotes
// @desc    Get multiple stock quotes
// @access  Public
router.post('/quotes', async (req, res) => {
  try {
    const { symbols } = req.body;
    
    if (!symbols || !Array.isArray(symbols)) {
      return res.status(400).json({
        success: false,
        message: 'Symbols array is required'
      });
    }
    
    const quotes = symbols.map(symbol => {
      const upperSymbol = symbol.toUpperCase();
      return mockStocks[upperSymbol] || null;
    }).filter(quote => quote !== null);
    
    res.json({
      success: true,
      data: quotes
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching stock quotes',
      error: error.message
    });
  }
});

module.exports = router;

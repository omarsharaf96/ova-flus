/**
 * Portfolio Models
 * Shared data structures for stock portfolio management across all platforms
 */

class Stock {
  constructor(id, symbol, name, currentPrice, previousClose, change, changePercent) {
    this.id = id;
    this.symbol = symbol;
    this.name = name;
    this.currentPrice = currentPrice;
    this.previousClose = previousClose;
    this.change = change || 0;
    this.changePercent = changePercent || 0;
  }

  updatePrice(newPrice) {
    this.change = newPrice - this.previousClose;
    this.changePercent = (this.change / this.previousClose) * 100;
    this.currentPrice = newPrice;
  }

  isPositive() {
    return this.change >= 0;
  }
}

class StockHolding {
  constructor(id, stockId, symbol, shares, avgPurchasePrice, currentPrice) {
    this.id = id;
    this.stockId = stockId;
    this.symbol = symbol;
    this.shares = shares;
    this.avgPurchasePrice = avgPurchasePrice;
    this.currentPrice = currentPrice;
  }

  getTotalCost() {
    return this.shares * this.avgPurchasePrice;
  }

  getCurrentValue() {
    return this.shares * this.currentPrice;
  }

  getProfitLoss() {
    return this.getCurrentValue() - this.getTotalCost();
  }

  getProfitLossPercentage() {
    return (this.getProfitLoss() / this.getTotalCost()) * 100;
  }
}

class StockTransaction {
  constructor(id, portfolioId, stockId, symbol, type, shares, price, date, fees) {
    this.id = id;
    this.portfolioId = portfolioId;
    this.stockId = stockId;
    this.symbol = symbol;
    this.type = type; // 'buy' or 'sell'
    this.shares = shares;
    this.price = price;
    this.date = date || new Date();
    this.fees = fees || 0;
  }

  getTotalAmount() {
    return (this.shares * this.price) + this.fees;
  }
}

class Portfolio {
  constructor(id, userId, name, holdings, cash) {
    this.id = id;
    this.userId = userId;
    this.name = name;
    this.holdings = holdings || [];
    this.cash = cash || 0;
  }

  getTotalValue() {
    const holdingsValue = this.holdings.reduce((sum, holding) => 
      sum + holding.getCurrentValue(), 0
    );
    return holdingsValue + this.cash;
  }

  getTotalCost() {
    return this.holdings.reduce((sum, holding) => 
      sum + holding.getTotalCost(), 0
    );
  }

  getTotalProfitLoss() {
    return this.holdings.reduce((sum, holding) => 
      sum + holding.getProfitLoss(), 0
    );
  }

  getTotalReturn() {
    const totalCost = this.getTotalCost();
    return totalCost > 0 ? (this.getTotalProfitLoss() / totalCost) * 100 : 0;
  }

  addHolding(holding) {
    this.holdings.push(holding);
  }

  removeHolding(holdingId) {
    this.holdings = this.holdings.filter(h => h.id !== holdingId);
  }
}

module.exports = {
  Stock,
  StockHolding,
  StockTransaction,
  Portfolio
};

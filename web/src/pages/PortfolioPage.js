import React, { useState, useEffect } from 'react';
import { portfolioAPI } from '../services/api';

function PortfolioPage() {
  const [selectedPortfolio, setSelectedPortfolio] = useState(null);
  const [performance, setPerformance] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddTransaction, setShowAddTransaction] = useState(false);
  const [newTransaction, setNewTransaction] = useState({
    stockId: '',
    symbol: '',
    type: 'buy',
    shares: '',
    price: '',
    fees: '0'
  });

  const fetchPortfolios = async () => {
    try {
      setLoading(true);
      const response = await portfolioAPI.getAll();
      if (response.data.success) {
        if (response.data.data.length > 0) {
          const portfolio = response.data.data[0];
          setSelectedPortfolio(portfolio);
          fetchPortfolioDetails(portfolio.id);
        }
      }
    } catch (error) {
      console.error('Error fetching portfolios:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPortfolios();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);



  const fetchPortfolioDetails = async (portfolioId) => {
    try {
      const [perfResponse, transResponse] = await Promise.all([
        portfolioAPI.getPerformance(portfolioId),
        portfolioAPI.getTransactions(portfolioId)
      ]);

      if (perfResponse.data.success) {
        setPerformance(perfResponse.data.data);
      }

      if (transResponse.data.success) {
        setTransactions(transResponse.data.data);
      }
    } catch (error) {
      console.error('Error fetching portfolio details:', error);
    }
  };

  const handleAddTransaction = async (e) => {
    e.preventDefault();
    try {
      await portfolioAPI.addTransaction(selectedPortfolio.id, {
        ...newTransaction,
        shares: parseFloat(newTransaction.shares),
        price: parseFloat(newTransaction.price),
        fees: parseFloat(newTransaction.fees)
      });

      setNewTransaction({
        stockId: '',
        symbol: '',
        type: 'buy',
        shares: '',
        price: '',
        fees: '0'
      });
      setShowAddTransaction(false);
      fetchPortfolios();
    } catch (error) {
      console.error('Error adding transaction:', error);
    }
  };

  if (loading) {
    return <div className="page-header"><h2>Loading Portfolio...</h2></div>;
  }

  if (!selectedPortfolio) {
    return (
      <div>
        <div className="page-header">
          <h2>Stock Portfolio</h2>
          <p>No portfolios found. Create your first portfolio to get started.</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="page-header">
        <h2>Stock Portfolio</h2>
        <p>Track and manage your stock investments</p>
      </div>

      {performance && (
        <div className="grid grid-3">
          <div className="stat-card">
            <div className="stat-label">Total Value</div>
            <div className="stat-value">${performance.totalValue.toLocaleString()}</div>
            <div className="stat-change">{performance.holdingsCount} holdings</div>
          </div>

          <div className={`stat-card ${performance.profitLoss >= 0 ? 'success' : 'danger'}`}>
            <div className="stat-label">Profit/Loss</div>
            <div className="stat-value">
              {performance.profitLoss >= 0 ? '+' : ''}${performance.profitLoss.toLocaleString()}
            </div>
            <div className="stat-change">
              {performance.profitLoss >= 0 ? '+' : ''}{performance.returnPercentage.toFixed(2)}% return
            </div>
          </div>

          <div className="stat-card">
            <div className="stat-label">Cash Balance</div>
            <div className="stat-value">${performance.cash.toLocaleString()}</div>
            <div className="stat-change">Available funds</div>
          </div>
        </div>
      )}

      <div className="card">
        <div className="card-header">
          <h3 className="card-title">Holdings</h3>
          <button 
            className="btn btn-primary"
            onClick={() => setShowAddTransaction(!showAddTransaction)}
          >
            {showAddTransaction ? 'Cancel' : 'Add Transaction'}
          </button>
        </div>

        {showAddTransaction && (
          <form onSubmit={handleAddTransaction} style={{
            marginBottom: '1.5rem',
            padding: '1rem',
            backgroundColor: '#f5f5f5',
            borderRadius: '4px'
          }}>
            <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: '1fr 1fr' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Stock Symbol
                </label>
                <input
                  type="text"
                  value={newTransaction.symbol}
                  onChange={(e) => setNewTransaction({ 
                    ...newTransaction, 
                    symbol: e.target.value.toUpperCase(),
                    stockId: e.target.value.toUpperCase()
                  })}
                  required
                  placeholder="e.g., AAPL"
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Transaction Type
                </label>
                <select
                  value={newTransaction.type}
                  onChange={(e) => setNewTransaction({ ...newTransaction, type: e.target.value })}
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                  }}
                >
                  <option value="buy">Buy</option>
                  <option value="sell">Sell</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Shares
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={newTransaction.shares}
                  onChange={(e) => setNewTransaction({ ...newTransaction, shares: e.target.value })}
                  required
                  placeholder="0"
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Price per Share
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={newTransaction.price}
                  onChange={(e) => setNewTransaction({ ...newTransaction, price: e.target.value })}
                  required
                  placeholder="0.00"
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Fees (optional)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={newTransaction.fees}
                  onChange={(e) => setNewTransaction({ ...newTransaction, fees: e.target.value })}
                  placeholder="0.00"
                  style={{
                    width: '100%',
                    padding: '0.5rem',
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                  }}
                />
              </div>
            </div>

            <button type="submit" className="btn btn-success" style={{ marginTop: '1rem' }}>
              Add Transaction
            </button>
          </form>
        )}

        <div>
          {selectedPortfolio.holdings.length === 0 ? (
            <p style={{ padding: '2rem', textAlign: 'center', color: '#757575' }}>
              No holdings yet. Add your first transaction to get started.
            </p>
          ) : (
            selectedPortfolio.holdings.map((holding) => {
              const currentValue = holding.shares * holding.currentPrice;
              const cost = holding.shares * holding.avgPurchasePrice;
              const profitLoss = currentValue - cost;
              const profitLossPercent = (profitLoss / cost) * 100;

              return (
                <div key={holding.id} style={{
                  padding: '1rem',
                  borderBottom: '1px solid #e0e0e0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: '1.2rem' }}>{holding.symbol}</div>
                    <div style={{ color: '#757575', fontSize: '0.875rem' }}>
                      {holding.shares} shares @ ${holding.currentPrice.toFixed(2)}
                    </div>
                    <div style={{ color: '#757575', fontSize: '0.875rem' }}>
                      Avg cost: ${holding.avgPurchasePrice.toFixed(2)}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 600, fontSize: '1.2rem' }}>
                      ${currentValue.toLocaleString()}
                    </div>
                    <div style={{
                      color: profitLoss >= 0 ? '#4CAF50' : '#f44336',
                      fontSize: '0.875rem',
                      fontWeight: 500
                    }}>
                      {profitLoss >= 0 ? '+' : ''}${profitLoss.toFixed(2)}
                    </div>
                    <div style={{
                      color: profitLoss >= 0 ? '#4CAF50' : '#f44336',
                      fontSize: '0.875rem'
                    }}>
                      {profitLossPercent >= 0 ? '+' : ''}{profitLossPercent.toFixed(2)}%
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {transactions.length > 0 && (
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Transaction History</h3>
          </div>
          <div>
            {transactions.map((transaction) => (
              <div key={transaction.id} style={{
                padding: '1rem',
                borderBottom: '1px solid #e0e0e0',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
              }}>
                <div>
                  <div style={{ fontWeight: 600 }}>
                    {transaction.type.toUpperCase()} {transaction.symbol}
                  </div>
                  <div style={{ color: '#757575', fontSize: '0.875rem' }}>
                    {transaction.shares} shares @ ${transaction.price} • {new Date(transaction.date).toLocaleDateString()}
                  </div>
                </div>
                <div style={{
                  fontWeight: 600,
                  color: transaction.type === 'buy' ? '#f44336' : '#4CAF50',
                  fontSize: '1.1rem'
                }}>
                  {transaction.type === 'buy' ? '-' : '+'}${transaction.getTotalAmount ? transaction.getTotalAmount().toFixed(2) : (transaction.shares * transaction.price + transaction.fees).toFixed(2)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default PortfolioPage;

import React, { useState, useEffect } from 'react';
import { budgetAPI, portfolioAPI } from '../services/api';

function Dashboard() {
  const [budgetData, setBudgetData] = useState(null);
  const [portfolioData, setPortfolioData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const [budgets, portfolios] = await Promise.all([
        budgetAPI.getAll(),
        portfolioAPI.getAll()
      ]);

      if (budgets.data.success && budgets.data.data.length > 0) {
        setBudgetData(budgets.data.data[0]);
      }

      if (portfolios.data.success && portfolios.data.data.length > 0) {
        const portfolio = portfolios.data.data[0];
        const performance = await portfolioAPI.getPerformance(portfolio.id);
        setPortfolioData({
          ...portfolio,
          performance: performance.data.data
        });
      }
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateBudgetStats = () => {
    if (!budgetData) return { spent: 0, limit: 0, remaining: 0, percentage: 0 };
    
    const spent = budgetData.categories.reduce((sum, cat) => sum + cat.spent, 0);
    const limit = budgetData.totalLimit;
    const remaining = limit - spent;
    const percentage = (spent / limit) * 100;
    
    return { spent, limit, remaining, percentage };
  };

  if (loading) {
    return (
      <div className="page-header">
        <h2>Loading Dashboard...</h2>
      </div>
    );
  }

  const budgetStats = calculateBudgetStats();

  return (
    <div>
      <div className="page-header">
        <h2>Financial Dashboard</h2>
        <p>Overview of your budget and portfolio performance</p>
      </div>

      <div className="grid grid-2">
        <div className="stat-card">
          <div className="stat-label">Total Budget</div>
          <div className="stat-value">${budgetStats.limit.toLocaleString()}</div>
          <div className="stat-change">Monthly limit</div>
        </div>

        <div className={`stat-card ${budgetStats.percentage > 90 ? 'danger' : budgetStats.percentage > 75 ? 'warning' : 'success'}`}>
          <div className="stat-label">Budget Remaining</div>
          <div className="stat-value">${budgetStats.remaining.toLocaleString()}</div>
          <div className="stat-change">{budgetStats.percentage.toFixed(1)}% used</div>
        </div>

        {portfolioData && (
          <>
            <div className="stat-card success">
              <div className="stat-label">Portfolio Value</div>
              <div className="stat-value">${portfolioData.performance.totalValue.toLocaleString()}</div>
              <div className="stat-change">Total assets</div>
            </div>

            <div className={`stat-card ${portfolioData.performance.profitLoss >= 0 ? 'success' : 'danger'}`}>
              <div className="stat-label">Profit/Loss</div>
              <div className="stat-value">
                {portfolioData.performance.profitLoss >= 0 ? '+' : ''}
                ${portfolioData.performance.profitLoss.toLocaleString()}
              </div>
              <div className="stat-change">
                {portfolioData.performance.returnPercentage >= 0 ? '+' : ''}
                {portfolioData.performance.returnPercentage.toFixed(2)}% return
              </div>
            </div>
          </>
        )}
      </div>

      <div className="grid grid-2">
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Budget Categories</h3>
          </div>
          {budgetData && budgetData.categories.map((category) => {
            const percentage = (category.spent / category.limit) * 100;
            return (
              <div key={category.id} style={{ marginBottom: '1rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                  <span>{category.name}</span>
                  <span>${category.spent} / ${category.limit}</span>
                </div>
                <div style={{ 
                  width: '100%', 
                  height: '8px', 
                  backgroundColor: '#e0e0e0', 
                  borderRadius: '4px',
                  overflow: 'hidden'
                }}>
                  <div style={{ 
                    width: `${Math.min(percentage, 100)}%`, 
                    height: '100%', 
                    backgroundColor: percentage > 90 ? '#f44336' : percentage > 75 ? '#ff9800' : '#4CAF50',
                    transition: 'width 0.3s'
                  }}></div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Portfolio Holdings</h3>
          </div>
          {portfolioData && portfolioData.holdings.map((holding) => {
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
                  <div style={{ fontWeight: 600, fontSize: '1.1rem' }}>{holding.symbol}</div>
                  <div style={{ color: '#757575', fontSize: '0.875rem' }}>
                    {holding.shares} shares @ ${holding.currentPrice}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontWeight: 600 }}>${currentValue.toFixed(2)}</div>
                  <div style={{ 
                    color: profitLoss >= 0 ? '#4CAF50' : '#f44336',
                    fontSize: '0.875rem'
                  }}>
                    {profitLoss >= 0 ? '+' : ''}${profitLoss.toFixed(2)} 
                    ({profitLossPercent >= 0 ? '+' : ''}{profitLossPercent.toFixed(2)}%)
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export default Dashboard;

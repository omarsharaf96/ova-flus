import React, { useState, useEffect } from 'react';
import { budgetAPI } from '../services/api';

function BudgetPage() {
  const [budgets, setBudgets] = useState([]);
  const [selectedBudget, setSelectedBudget] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddTransaction, setShowAddTransaction] = useState(false);
  const [newTransaction, setNewTransaction] = useState({
    categoryId: '',
    amount: '',
    description: '',
    type: 'expense'
  });

  useEffect(() => {
    fetchBudgets();
  }, []);

  const fetchBudgets = async () => {
    try {
      setLoading(true);
      const response = await budgetAPI.getAll();
      if (response.data.success) {
        setBudgets(response.data.data);
        if (response.data.data.length > 0) {
          setSelectedBudget(response.data.data[0]);
          fetchTransactions(response.data.data[0].id);
        }
      }
    } catch (error) {
      console.error('Error fetching budgets:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchTransactions = async (budgetId) => {
    try {
      const response = await budgetAPI.getTransactions(budgetId);
      if (response.data.success) {
        setTransactions(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching transactions:', error);
    }
  };

  const handleAddTransaction = async (e) => {
    e.preventDefault();
    try {
      await budgetAPI.addTransaction(selectedBudget.id, {
        ...newTransaction,
        amount: parseFloat(newTransaction.amount)
      });
      
      setNewTransaction({
        categoryId: '',
        amount: '',
        description: '',
        type: 'expense'
      });
      setShowAddTransaction(false);
      fetchBudgets();
      fetchTransactions(selectedBudget.id);
    } catch (error) {
      console.error('Error adding transaction:', error);
    }
  };

  if (loading) {
    return <div className="page-header"><h2>Loading Budget...</h2></div>;
  }

  if (!selectedBudget) {
    return (
      <div>
        <div className="page-header">
          <h2>Budget Tracking</h2>
          <p>No budgets found. Create your first budget to get started.</p>
        </div>
      </div>
    );
  }

  const totalSpent = selectedBudget.categories.reduce((sum, cat) => sum + cat.spent, 0);
  const totalLimit = selectedBudget.totalLimit;
  const remaining = totalLimit - totalSpent;
  const usagePercent = (totalSpent / totalLimit) * 100;

  return (
    <div>
      <div className="page-header">
        <h2>Budget Tracking</h2>
        <p>Manage your expenses and track your budget</p>
      </div>

      <div className="grid grid-3">
        <div className="stat-card">
          <div className="stat-label">Total Budget</div>
          <div className="stat-value">${totalLimit.toLocaleString()}</div>
          <div className="stat-change">{selectedBudget.period}</div>
        </div>

        <div className={`stat-card ${usagePercent > 90 ? 'danger' : usagePercent > 75 ? 'warning' : ''}`}>
          <div className="stat-label">Total Spent</div>
          <div className="stat-value">${totalSpent.toLocaleString()}</div>
          <div className="stat-change">{usagePercent.toFixed(1)}% of budget</div>
        </div>

        <div className={`stat-card ${remaining > 0 ? 'success' : 'danger'}`}>
          <div className="stat-label">Remaining</div>
          <div className="stat-value">${remaining.toLocaleString()}</div>
          <div className="stat-change">{((remaining / totalLimit) * 100).toFixed(1)}% available</div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <h3 className="card-title">Budget Categories</h3>
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
                  Category
                </label>
                <select
                  value={newTransaction.categoryId}
                  onChange={(e) => setNewTransaction({ ...newTransaction, categoryId: e.target.value })}
                  required
                  style={{ 
                    width: '100%', 
                    padding: '0.5rem', 
                    border: '1px solid #ddd', 
                    borderRadius: '4px' 
                  }}
                >
                  <option value="">Select category</option>
                  {selectedBudget.categories.map(cat => (
                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Amount
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={newTransaction.amount}
                  onChange={(e) => setNewTransaction({ ...newTransaction, amount: e.target.value })}
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

              <div style={{ gridColumn: '1 / -1' }}>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: 500 }}>
                  Description
                </label>
                <input
                  type="text"
                  value={newTransaction.description}
                  onChange={(e) => setNewTransaction({ ...newTransaction, description: e.target.value })}
                  required
                  placeholder="What was this for?"
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
          {selectedBudget.categories.map((category) => {
            const percentage = (category.spent / category.limit) * 100;
            const isOverBudget = category.spent > category.limit;
            
            return (
              <div key={category.id} style={{ 
                padding: '1rem', 
                borderBottom: '1px solid #e0e0e0',
                marginBottom: '1rem'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                  <div>
                    <span style={{ fontWeight: 600, fontSize: '1.1rem' }}>{category.name}</span>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 600 }}>
                      ${category.spent.toLocaleString()} / ${category.limit.toLocaleString()}
                    </div>
                    <div style={{ 
                      fontSize: '0.875rem',
                      color: isOverBudget ? '#f44336' : '#4CAF50'
                    }}>
                      {isOverBudget ? 'Over budget by ' : 'Remaining: '}
                      ${Math.abs(category.limit - category.spent).toLocaleString()}
                    </div>
                  </div>
                </div>
                
                <div style={{ 
                  width: '100%', 
                  height: '12px', 
                  backgroundColor: '#e0e0e0', 
                  borderRadius: '6px',
                  overflow: 'hidden'
                }}>
                  <div style={{ 
                    width: `${Math.min(percentage, 100)}%`, 
                    height: '100%', 
                    backgroundColor: percentage > 100 ? '#f44336' : percentage > 90 ? '#ff9800' : '#4CAF50',
                    transition: 'width 0.3s'
                  }}></div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {transactions.length > 0 && (
        <div className="card">
          <div className="card-header">
            <h3 className="card-title">Recent Transactions</h3>
          </div>
          <div>
            {transactions.map((transaction) => {
              const category = selectedBudget.categories.find(c => c.id === transaction.categoryId);
              return (
                <div key={transaction.id} style={{
                  padding: '1rem',
                  borderBottom: '1px solid #e0e0e0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <div style={{ fontWeight: 600 }}>{transaction.description}</div>
                    <div style={{ color: '#757575', fontSize: '0.875rem' }}>
                      {category?.name} • {new Date(transaction.date).toLocaleDateString()}
                    </div>
                  </div>
                  <div style={{ 
                    fontWeight: 600, 
                    color: transaction.type === 'expense' ? '#f44336' : '#4CAF50',
                    fontSize: '1.1rem'
                  }}>
                    {transaction.type === 'expense' ? '-' : '+'}${transaction.amount.toFixed(2)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export default BudgetPage;

import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import BudgetPage from './pages/BudgetPage';
import PortfolioPage from './pages/PortfolioPage';
import './styles/App.css';

function App() {
  return (
    <Router>
      <div className="app">
        <nav className="navbar">
          <div className="navbar-container">
            <div className="navbar-brand">
              <h1>💰 OVA FLUS</h1>
              <p>Finance Manager</p>
            </div>
            <ul className="navbar-menu">
              <li><Link to="/">Dashboard</Link></li>
              <li><Link to="/budget">Budget</Link></li>
              <li><Link to="/portfolio">Portfolio</Link></li>
            </ul>
          </div>
        </nav>

        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/budget" element={<BudgetPage />} />
            <Route path="/portfolio" element={<PortfolioPage />} />
          </Routes>
        </main>

        <footer className="footer">
          <p>&copy; 2024 OVA FLUS. Cross-platform Finance Management.</p>
        </footer>
      </div>
    </Router>
  );
}

export default App;

import React, { useState } from 'react';
import { Outlet, NavLink } from 'react-router-dom';

const Dashboard = () => {
  const [sidebarOpen, setSidebarOpen] = useState(true);

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>Dashboard</h1>
        <button 
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="sidebar-toggle"
        >
          {sidebarOpen ? '←' : '→'}
        </button>
      </header>

      <div className="dashboard-layout">
        {sidebarOpen && (
          <aside className="dashboard-sidebar">
            <nav className="dashboard-nav">
              <ul>
                <li>
                  <NavLink 
                    to="/dashboard" 
                    end
                    className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}
                  >
                    Overview
                  </NavLink>
                </li>
                <li>
                  <NavLink 
                    to="/dashboard/analytics"
                    className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}
                  >
                    Analytics
                  </NavLink>
                </li>
                <li>
                  <NavLink 
                    to="/dashboard/settings"
                    className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}
                  >
                    Settings
                  </NavLink>
                </li>
              </ul>
            </nav>
          </aside>
        )}

        <main className="dashboard-content">
          <Outlet />
          
          {/* Default dashboard content when no child route is matched */}
          <div className="dashboard-overview">
            <div className="stats-grid">
              <div className="stat-card">
                <h3>Total Users</h3>
                <p className="stat-number">1,234</p>
              </div>
              <div className="stat-card">
                <h3>Active Sessions</h3>
                <p className="stat-number">567</p>
              </div>
              <div className="stat-card">
                <h3>Revenue</h3>
                <p className="stat-number">$12,345</p>
              </div>
              <div className="stat-card">
                <h3>Growth</h3>
                <p className="stat-number">+23%</p>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Dashboard;
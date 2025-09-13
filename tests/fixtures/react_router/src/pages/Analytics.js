import React, { useState, useEffect } from 'react';

const Analytics = () => {
  const [data, setData] = useState(null);
  const [timeRange, setTimeRange] = useState('7d');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate analytics data fetching
    setTimeout(() => {
      const analyticsData = {
        pageViews: {
          total: 15678,
          change: +12.5,
          data: [
            { date: '2024-01-08', views: 1234 },
            { date: '2024-01-09', views: 1456 },
            { date: '2024-01-10', views: 1678 },
            { date: '2024-01-11', views: 1890 },
            { date: '2024-01-12', views: 2123 },
            { date: '2024-01-13', views: 2345 },
            { date: '2024-01-14', views: 2567 },
          ]
        },
        users: {
          total: 3456,
          change: +8.2,
          active: 1234,
          new: 456
        },
        conversion: {
          rate: 3.2,
          change: -0.5,
          total: 234
        },
        topPages: [
          { path: '/', views: 5678, bounce: 45.2 },
          { path: '/about', views: 2345, bounce: 52.1 },
          { path: '/users', views: 1890, bounce: 38.9 },
          { path: '/contact', views: 1234, bounce: 41.5 }
        ]
      };
      
      setData(analyticsData);
      setLoading(false);
    }, 800);
  }, [timeRange]);

  const handleTimeRangeChange = (range) => {
    setTimeRange(range);
    setLoading(true);
  };

  if (loading) {
    return (
      <div className="analytics-loading">
        <div className="spinner">Loading analytics...</div>
      </div>
    );
  }

  return (
    <div className="analytics">
      <header className="analytics-header">
        <h1>Analytics Dashboard</h1>
        <div className="time-range-selector">
          <button 
            className={timeRange === '24h' ? 'active' : ''}
            onClick={() => handleTimeRangeChange('24h')}
          >
            24 Hours
          </button>
          <button 
            className={timeRange === '7d' ? 'active' : ''}
            onClick={() => handleTimeRangeChange('7d')}
          >
            7 Days
          </button>
          <button 
            className={timeRange === '30d' ? 'active' : ''}
            onClick={() => handleTimeRangeChange('30d')}
          >
            30 Days
          </button>
        </div>
      </header>

      <div className="analytics-grid">
        <div className="metric-card">
          <h3>Page Views</h3>
          <div className="metric-value">
            {data.pageViews.total.toLocaleString()}
            <span className="metric-change positive">
              +{data.pageViews.change}%
            </span>
          </div>
        </div>

        <div className="metric-card">
          <h3>Total Users</h3>
          <div className="metric-value">
            {data.users.total.toLocaleString()}
            <span className="metric-change positive">
              +{data.users.change}%
            </span>
          </div>
          <div className="metric-details">
            <p>Active: {data.users.active}</p>
            <p>New: {data.users.new}</p>
          </div>
        </div>

        <div className="metric-card">
          <h3>Conversion Rate</h3>
          <div className="metric-value">
            {data.conversion.rate}%
            <span className="metric-change negative">
              {data.conversion.change}%
            </span>
          </div>
          <div className="metric-details">
            <p>Conversions: {data.conversion.total}</p>
          </div>
        </div>
      </div>

      <div className="analytics-charts">
        <div className="chart-section">
          <h2>Page Views Trend</h2>
          <div className="simple-chart">
            {data.pageViews.data.map((item, index) => (
              <div key={index} className="chart-bar">
                <div 
                  className="bar" 
                  style={{ height: `${(item.views / 3000) * 100}%` }}
                ></div>
                <span className="chart-label">{item.date.slice(-2)}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="top-pages-section">
          <h2>Top Pages</h2>
          <div className="pages-list">
            {data.topPages.map((page, index) => (
              <div key={index} className="page-item">
                <div className="page-path">{page.path}</div>
                <div className="page-stats">
                  <span>Views: {page.views.toLocaleString()}</span>
                  <span>Bounce: {page.bounce}%</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Analytics;
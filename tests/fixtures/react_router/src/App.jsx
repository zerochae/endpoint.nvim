import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import About from './pages/About';
import Users from './pages/Users';
import UserDetail from './pages/UserDetail';
import Dashboard from './pages/Dashboard';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/users" element={<Users />} />
          <Route path="/users/:id" element={<UserDetail />} />
          <Route path="/dashboard/*" element={<Dashboard />} />
          <Route path="/admin/users" element={<AdminUsers />} />
          <Route path="/api/v1/docs" element={<ApiDocs />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
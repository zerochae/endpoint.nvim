import React from 'react';
import { Link, NavLink, useNavigate } from 'react-router-dom';

function Navigation() {
  const navigate = useNavigate();

  const handleLogin = () => {
    // Programmatic navigation examples
    navigate('/login');
  };

  const handleLogout = () => {
    navigate('/');
  };

  const goToProfile = (userId) => {
    navigate(`/users/${userId}`);
  };

  const redirectToSettings = () => {
    navigate('/settings/profile');
  };

  return (
    <nav>
      <ul>
        <li>
          <Link to="/">Home</Link>
        </li>
        <li>
          <Link to="/about">About</Link>
        </li>
        <li>
          <NavLink to="/users">Users</NavLink>
        </li>
        <li>
          <NavLink to="/dashboard">Dashboard</NavLink>
        </li>
        <li>
          <Link to="/contact/support">Contact</Link>
        </li>
        <li>
          <NavLink to="/admin/panel">Admin</NavLink>
        </li>
      </ul>
      
      <div>
        <button onClick={handleLogin}>Login</button>
        <button onClick={handleLogout}>Logout</button>
        <button onClick={() => goToProfile(123)}>My Profile</button>
        <button onClick={redirectToSettings}>Settings</button>
      </div>
    </nav>
  );
}

export default Navigation;
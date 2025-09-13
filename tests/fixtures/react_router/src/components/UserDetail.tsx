import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

interface User {
  id: number;
  name: string;
  email: string;
  bio: string;
  avatar: string;
}

const UserDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      const userData: User = {
        id: parseInt(id || '1'),
        name: `User ${id}`,
        email: `user${id}@example.com`,
        bio: `This is the bio for user ${id}. They are an amazing person who loves to code and contribute to open source projects.`,
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${id}`
      };
      setUser(userData);
      setLoading(false);
    }, 800);
  }, [id]);

  if (loading) {
    return (
      <div className="user-detail-loading">
        <div className="spinner">Loading user details...</div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="user-detail-error">
        <h1>User not found</h1>
        <button onClick={() => navigate('/users')}>Back to Users</button>
      </div>
    );
  }

  return (
    <div className="user-detail">
      <header className="user-header">
        <img src={user.avatar} alt={user.name} className="user-avatar" />
        <div className="user-info">
          <h1>{user.name}</h1>
          <p className="user-email">{user.email}</p>
        </div>
      </header>
      
      <section className="user-bio">
        <h2>About</h2>
        <p>{user.bio}</p>
      </section>
      
      <div className="user-actions">
        <button onClick={() => navigate('/users')}>Back to Users</button>
        <button onClick={() => navigate(`/users/${user.id}/edit`)}>Edit User</button>
      </div>
    </div>
  );
};

export default UserDetail;
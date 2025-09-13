import React from 'react';

interface HomeProps {
  title?: string;
}

const Home: React.FC<HomeProps> = ({ title = "Welcome" }) => {
  return (
    <div className="home-container">
      <h1>{title}</h1>
      <p>This is the Home component loaded from index.tsx</p>
      <nav>
        <a href="/about">About</a>
        <a href="/users">Users</a>
      </nav>
    </div>
  );
};

export default Home;
import React from 'react';
import { useNavigate, Link } from 'react-router-dom';

const Home: React.FC = () => {
  const navigate = useNavigate();

  const handleGetStarted = () => {
    navigate('/onboarding/step1');
  };

  const handleExplore = () => {
    navigate('/explore/categories');
  };

  return (
    <div>
      <h1>Welcome Home</h1>
      <p>This is the home page with TypeScript support.</p>
      
      <div>
        <Link to="/features">View Features</Link>
        <Link to="/pricing">See Pricing</Link>
        <Link to="/docs/getting-started">Documentation</Link>
      </div>
      
      <div>
        <button onClick={handleGetStarted}>Get Started</button>
        <button onClick={handleExplore}>Explore</button>
        <button onClick={() => navigate('/signup')}>Sign Up</button>
      </div>
    </div>
  );
};

export default Home;
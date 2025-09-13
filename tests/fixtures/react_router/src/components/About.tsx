import React from 'react';

const About: React.FC = () => {
  return (
    <div className="about-page">
      <h1>About Us</h1>
      <p>This is the About component as a direct file (About.tsx)</p>
      <div>
        <h2>Our Story</h2>
        <p>We are a team of developers building amazing React applications.</p>
      </div>
    </div>
  );
};

export default About;
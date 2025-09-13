import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

interface Post {
  id: number;
  title: string;
  content: string;
  author: string;
  publishedAt: string;
  tags: string[];
}

interface User {
  id: number;
  name: string;
}

const PostDetail: React.FC = () => {
  const { userId, postId } = useParams<{ userId: string; postId: string }>();
  const navigate = useNavigate();
  const [post, setPost] = useState<Post | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      const postData: Post = {
        id: parseInt(postId || '1'),
        title: `Amazing Post #${postId}`,
        content: `This is the content of post ${postId} by user ${userId}. 
        
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`,
        author: `User ${userId}`,
        publishedAt: '2024-01-15',
        tags: ['react', 'typescript', 'web-development']
      };

      const userData: User = {
        id: parseInt(userId || '1'),
        name: `User ${userId}`
      };

      setPost(postData);
      setUser(userData);
      setLoading(false);
    }, 1000);
  }, [userId, postId]);

  if (loading) {
    return (
      <div className="post-detail-loading">
        <div className="spinner">Loading post...</div>
      </div>
    );
  }

  if (!post || !user) {
    return (
      <div className="post-detail-error">
        <h1>Post not found</h1>
        <button onClick={() => navigate(`/users/${userId}`)}>
          Back to User Profile
        </button>
      </div>
    );
  }

  return (
    <div className="post-detail">
      <header className="post-header">
        <div className="breadcrumbs">
          <button onClick={() => navigate('/users')}>Users</button>
          <span>/</span>
          <button onClick={() => navigate(`/users/${userId}`)}>
            {user.name}
          </button>
          <span>/</span>
          <span>Post #{post.id}</span>
        </div>
        
        <h1 className="post-title">{post.title}</h1>
        
        <div className="post-meta">
          <span className="post-author">By {post.author}</span>
          <span className="post-date">Published on {post.publishedAt}</span>
        </div>
        
        <div className="post-tags">
          {post.tags.map(tag => (
            <span key={tag} className="tag">#{tag}</span>
          ))}
        </div>
      </header>
      
      <article className="post-content">
        {post.content.split('\n\n').map((paragraph, index) => (
          <p key={index}>{paragraph}</p>
        ))}
      </article>
      
      <footer className="post-actions">
        <button onClick={() => navigate(`/users/${userId}`)}>
          View Author Profile
        </button>
        <button onClick={() => navigate(`/users/${userId}/posts`)}>
          More Posts by {user.name}
        </button>
      </footer>
    </div>
  );
};

export default PostDetail;
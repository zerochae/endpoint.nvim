import { createBrowserRouter } from 'react-router-dom';
import Home from './pages/Home';
import About from './pages/About';
import Profile from './pages/Profile';
import Settings from './pages/Settings';

// Modern React Router v6 configuration
export const router = createBrowserRouter([
  {
    path: "/",
    element: <Home />,
  },
  {
    path: "/about", 
    element: <About />,
  },
  {
    path: "/profile",
    element: <Profile />,
  },
  {
    path: "/settings/:tab",
    element: <Settings />,
  },
  {
    path: "/users/:userId/posts/:postId",
    element: <PostDetail />,
  }
]);

// Alternative array format
const routes = [
  { path: "/api/docs", element: <ApiDocs /> },
  { path: "/help/faq", element: <FAQ /> },
  { path: "/contact/support", element: <Support /> }
];
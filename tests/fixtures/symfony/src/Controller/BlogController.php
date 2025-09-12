<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/blog')]
final class BlogController extends AbstractController
{
    #[Route('/', name: 'blog_index', methods: ['GET'])]
    public function index(): Response
    {
        return new Response('Blog posts list');
    }

    #[Route('/posts/{id}', name: 'blog_post_show', methods: ['GET'])]
    public function show(int $id): Response
    {
        return new Response('Blog post: ' . $id);
    }

    #[Route('/posts/{id}/edit', name: 'blog_post_edit', methods: ['GET', 'POST'])]
    public function edit(int $id): Response
    {
        return new Response('Edit blog post: ' . $id);
    }

    #[Route('/posts/{id}/comments', name: 'blog_post_comments', methods: ['GET', 'POST'])]
    public function comments(int $id): Response
    {
        return new Response('Comments for post: ' . $id);
    }

    #[Route('/posts/{id}/comments/{commentId}', name: 'blog_comment_show', methods: ['GET'])]
    public function showComment(int $id, int $commentId): Response
    {
        return new Response('Comment ' . $commentId . ' for post: ' . $id);
    }

    #[Route('/posts/{id}/comments/{commentId}/edit', name: 'blog_comment_edit', methods: ['GET', 'PUT'])]
    public function editComment(int $id, int $commentId): Response
    {
        return new Response('Edit comment ' . $commentId . ' for post: ' . $id);
    }

    #[Route('/posts/{id}/comments/{commentId}/delete', name: 'blog_comment_delete', methods: ['DELETE'])]
    public function deleteComment(int $id, int $commentId): Response
    {
        return new Response('Delete comment ' . $commentId . ' for post: ' . $id);
    }

    #[Route('/posts/{id}/like', name: 'blog_post_like', methods: ['POST'])]
    public function like(int $id): Response
    {
        return new Response('Like post: ' . $id);
    }

    #[Route('/posts/{id}/unlike', name: 'blog_post_unlike', methods: ['DELETE'])]
    public function unlike(int $id): Response
    {
        return new Response('Unlike post: ' . $id);
    }

    #[Route('/posts/{id}/share', name: 'blog_post_share', methods: ['POST'])]
    public function share(int $id): Response
    {
        return new Response('Share post: ' . $id);
    }

    #[Route('/create', name: 'blog_post_create', methods: ['GET', 'POST'])]
    public function create(): Response
    {
        return new Response('Create new blog post');
    }

    #[Route('/posts/{id}/delete', name: 'blog_post_delete', methods: ['DELETE'])]
    public function delete(int $id): Response
    {
        return new Response('Delete post: ' . $id);
    }

    #[Route('/categories', name: 'blog_categories', methods: ['GET'])]
    public function categories(): Response
    {
        return new Response('Blog categories');
    }

    #[Route('/categories/{category}', name: 'blog_category_posts', methods: ['GET'])]
    public function categoryPosts(string $category): Response
    {
        return new Response('Posts in category: ' . $category);
    }

    #[Route('/search', name: 'blog_search', methods: ['GET', 'POST'])]
    public function search(): Response
    {
        return new Response('Search blog posts');
    }

    #[Route('/archive/{year}', name: 'blog_archive_year', methods: ['GET'])]
    public function archiveYear(int $year): Response
    {
        return new Response('Posts from year: ' . $year);
    }

    #[Route('/archive/{year}/{month}', name: 'blog_archive_month', methods: ['GET'])]
    public function archiveMonth(int $year, int $month): Response
    {
        return new Response('Posts from ' . $year . '/' . $month);
    }

    #[Route('/rss', name: 'blog_rss', methods: ['GET'])]
    public function rss(): Response
    {
        return new Response('RSS feed');
    }
}
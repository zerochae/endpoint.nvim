<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

/**
 * @Route("/api/v1")
 */
class ApiController extends AbstractController
{
    /**
     * @Route("/users", methods={"GET"})
     */
    public function getUsers(): Response
    {
        return new Response('GET /api/v1/users');
    }

    /**
     * @Route("/users", methods={"POST"})
     */
    public function createUser(): Response
    {
        return new Response('POST /api/v1/users');
    }

    /**
     * @Route("/users/{id}", methods={"PUT"})
     */
    public function updateUser(int $id): Response
    {
        return new Response('PUT /api/v1/users/' . $id);
    }

    /**
     * @Route("/users/{id}", methods={"DELETE"})
     */
    public function deleteUser(int $id): Response
    {
        return new Response('DELETE /api/v1/users/' . $id);
    }

    /**
     * @Route("/users/{id}", methods={"PATCH"})
     */
    public function patchUser(int $id): Response
    {
        return new Response('PATCH /api/v1/users/' . $id);
    }

    /**
     * Multiple methods in docblock annotation
     * @Route("/profile", methods={"GET", "POST"})
     */
    public function profile(): Response
    {
        return new Response('Profile (GET/POST)');
    }
}

// Modern PHP 8+ style for comparison
class ModernController extends AbstractController
{
    #[Route('/products', methods: ['GET'])]
    public function getProducts(): Response
    {
        return new Response('GET /products');
    }

    #[Route('/products', methods: ['POST'])]
    public function createProduct(): Response
    {
        return new Response('POST /products');
    }

    // Multiple methods in PHP 8+ attributes
    #[Route('/edit', name: 'user_edit', methods: ['GET', 'POST'])]
    public function edit(): Response
    {
        return new Response('Edit user');
    }

    #[Route('/settings', name: 'user_settings', methods: ['GET', 'POST'])]
    public function settings(): Response
    {
        return new Response('User settings');
    }
}

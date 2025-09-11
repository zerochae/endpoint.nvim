<?php

namespace App\AuthBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/auth')]
final class AuthController extends AbstractController
{
    #[Route('/login', name: 'auth_login', methods: ['GET', 'POST'])]
    public function login(): Response
    {
        return new Response('Login Form');
    }

    #[Route('/logout', name: 'auth_logout', methods: ['POST'])]
    public function logout(): Response
    {
        return new Response('Logout');
    }

    #[Route('/register', name: 'auth_register', methods: ['GET', 'POST'])]
    public function register(): Response
    {
        return new Response('Register Form');
    }
}
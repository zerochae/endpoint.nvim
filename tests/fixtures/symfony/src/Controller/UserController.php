<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/profile')]
final class UserController extends AbstractController
{
    #[Route('/edit', name: 'user_edit', methods: ['GET', 'POST'])]
    public function edit(): Response
    {
        return new Response('Edit user');
    }

    #[Route('/change-password', name: 'user_change_password', methods: ['GET', 'POST'])]
    public function changePassword(): Response
    {
        return new Response('Change password');
    }
}
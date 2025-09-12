<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/profile')]
final class UserController extends AbstractController
{
    #[Route('/', name: 'user_profile', methods: ['GET'])]
    public function profile(): Response
    {
        return new Response('User profile');
    }

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

    #[Route('/preferences', name: 'user_preferences', methods: ['GET', 'PUT'])]
    public function preferences(): Response
    {
        return new Response('User preferences');
    }

    #[Route('/avatar', name: 'user_avatar', methods: ['GET', 'POST', 'DELETE'])]
    public function avatar(): Response
    {
        return new Response('User avatar');
    }

    #[Route('/change-password', name: 'user_change_password', methods: ['GET', 'POST'])]
    public function changePassword(): Response
    {
        return new Response('Change password');
    }

    #[Route('/security', name: 'user_security', methods: ['GET', 'POST'])]
    public function security(): Response
    {
        return new Response('Security settings');
    }

    #[Route('/notifications', name: 'user_notifications', methods: ['GET', 'PUT'])]
    public function notifications(): Response
    {
        return new Response('Notification settings');
    }

    #[Route('/privacy', name: 'user_privacy', methods: ['GET', 'PUT'])]
    public function privacy(): Response
    {
        return new Response('Privacy settings');
    }

    #[Route('/delete', name: 'user_delete', methods: ['POST', 'DELETE'])]
    public function delete(): Response
    {
        return new Response('Delete user account');
    }
}
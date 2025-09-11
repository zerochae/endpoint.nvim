<?php

namespace App\AuthBundle\Controllers;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/security')]
final class SecurityController extends AbstractController
{
    #[Route('/login', name: 'security_login', methods: ['GET', 'POST'])]
    public function login(): Response
    {
        return new Response('Security Login');
    }

    #[Route('/validate', name: 'security_validate', methods: ['POST'])]
    public function validate(): Response
    {
        return new Response('Validate User');
    }

    #[Route('/reset-password', name: 'security_reset', methods: ['GET', 'POST'])]
    public function resetPassword(): Response
    {
        return new Response('Reset Password');
    }
}
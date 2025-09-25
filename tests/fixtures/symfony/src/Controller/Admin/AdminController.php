<?php

namespace App\Controller\Admin;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/admin')]
final class AdminController extends AbstractController
{
    #[Route('/dashboard', name: 'admin_dashboard', methods: ['GET'])]
    public function dashboard(): Response
    {
        return new Response('Admin Dashboard');
    }

    /* #[Route('/users', name: 'admin_users_list', methods: ['GET'])] */
    /* public function usersList(): Response */
    /* { */
    /*     return new Response('Admin Users List'); */
    /* } */

    #[Route('/users/{id}/delete', name: 'admin_user_delete', methods: ['DELETE'])]
    public function deleteUser(int $id): Response
    {
        return new Response('Delete User ' . $id);
    }
}

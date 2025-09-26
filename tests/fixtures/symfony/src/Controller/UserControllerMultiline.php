<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route(
    path: '/api/users',
    name: 'user.'
)]
class UserController extends AbstractController
{
    #[Route(
        path: '',
        name: 'list',
        methods: ['GET']
    )]
    public function list(): Response
    {
        return new Response('List users');
    }

    #[Route(
        path: '/{id}',
        name: 'show',
        methods: ['GET'],
        requirements: ['id' => '\d+']
    )]
    public function show(): Response
    {
        return new Response('Show user');
    }

    #[Route(
        methods: ['POST'],
        path: '',
        name: 'create'
    )]
    public function create(): Response
    {
        return new Response('Create user');
    }

    // Very complex multiline with mixed argument order
    #[Route(
        requirements: ['id' => '\d+'],
        name: 'complex_update',
        condition: 'request.headers.get("Content-Type") matches "/^application/"',
        methods: ['PUT', 'PATCH'],
        path: '/{id}/profile',
        defaults: ['_format' => 'json']
    )]
    public function complexUpdate(): Response
    {
        return new Response('Complex update');
    }
}
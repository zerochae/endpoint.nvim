<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/v3')]
class CommentController extends AbstractController
{
    #[Route(
        path: '/posts/{postId}/comments',
        name: 'comment.create',
        methods: ['POST'],
    )]
    public function create(): Response
    {
        return new Response('Create comment');
    }

    #[Route(
        name: 'comment.update',
        methods: ['PUT'],
        path: '/posts/{postId}/comments/{commentId}',
    )]
    public function update(): Response
    {
        return new Response('Update comment');
    }

    #[Route(
        methods: ['GET'],
        path: '/posts/{postId}/comments',
        name: 'comment.list'
    )]
    public function list(): Response
    {
        return new Response('List comments');
    }

    #[Route(
        path: '/comments/{commentId}',
        methods: ['DELETE'],
        name: 'comment.delete',
        requirements: ['commentId' => '\d+']
    )]
    public function delete(): Response
    {
        return new Response('Delete comment');
    }

    // Traditional annotation style (also multiline)
    /**
     * @Route(
     *     "/legacy/comments",
     *     methods={"GET"},
     *     name="comment.legacy"
     * )
     */
    public function legacy(): Response
    {
        return new Response('Legacy comment endpoint');
    }
}

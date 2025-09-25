<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class CommentedController
{
    // Single line commented endpoints - should be filtered
    // #[Route('/single-line-comment', methods: ['GET'])]
    // public function getSingleLineComment(): Response { return new Response('filtered'); }

    // #[Route('/another-single-line', methods: ['POST'])]
    // public function postAnotherSingleLine(): Response { return new Response('filtered'); }

    /* Block commented endpoints - should be filtered */
    /* #[Route('/block-comment', methods: ['PUT'])] */
    /* public function putBlockComment(): Response { return new Response('filtered'); } */

    /*
     * Multi-line block commented endpoints - should be filtered
     * #[Route('/multi-line-block', methods: ['DELETE'])]
     * public function deleteMultiLineBlock(): Response { return new Response('filtered'); }
     */

    /**
     * PHPDoc commented endpoints - should be filtered
     * #[Route('/phpdoc-comment', methods: ['PATCH'])]
     * public function patchPhpdocComment(): Response { return new Response('filtered'); }
     */

    # Hash commented endpoints - should be filtered (but NOT PHP attributes!)
    # This is a regular hash comment
    # #[Route('/hash-commented', methods: ['GET'])] - This should be filtered
    # public function getHashCommented(): Response { return new Response('filtered'); }

    // Active endpoints - should NOT be filtered
  
    #[Route('/active', methods: ['GET'])]
    public function getActive(): Response
    {
        return new Response('active');
    }

    #[Route('/users', methods: ['POST'])]
    public function createUser(): Response
    {
        return new Response('created');
    }

    // Mixed scenarios
    /*
    #[Route('/mixed-block', methods: ['GET'])]
    public function getMixedBlock(): Response
    {
        return new Response('filtered');
    }
    */

    // #[Route('/commented-inline', methods: ['GET'])] // This should be filtered

    #[Route('/active-after-comment', methods: ['PATCH'])]
    public function patchActiveAfterComment(): Response
    {
        return new Response('active'); // This should NOT be filtered
    }

    // Annotation style (legacy)
    // @Route("/annotation-comment", methods={"GET"})
    // public function getAnnotationComment(): Response { return new Response('filtered'); }

    /**
     * @Route("/annotation-active", methods={"GET"})
     */
    public function getAnnotationActive(): Response
    {
        return new Response('active');
    }
}

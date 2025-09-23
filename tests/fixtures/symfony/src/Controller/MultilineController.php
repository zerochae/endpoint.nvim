<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class MultilineController extends AbstractController
{
    // Test case 1: Simple multiline #[Route] attribute (PHP 8+)
    #[Route(
        '/users/{id}',
        methods: ['GET']
    )]
    public function getUser(int $id): JsonResponse
    {
        $user = [
            'id' => $id,
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ];

        return $this->json($user);
    }

    // Test case 2: Complex multiline #[Route] with multiple parameters
    #[Route(
        '/users',
        methods: ['POST'],
        name: 'create_user'
    )]
    public function createUser(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        $user = [
            'id' => rand(1, 1000),
            'name' => $data['name'] ?? 'Unknown',
            'email' => $data['email'] ?? 'unknown@example.com'
        ];

        return $this->json($user, Response::HTTP_CREATED);
    }

    // Test case 3: Multiline #[Route] with complex path and constraints
    #[Route(
        '/users/{id}',
        methods: ['PUT'],
        requirements: ['id' => '\d+'],
        name: 'update_user'
    )]
    public function updateUser(int $id, Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        $user = [
            'id' => $id,
            'name' => $data['name'] ?? 'Updated User',
            'email' => $data['email'] ?? 'updated@example.com'
        ];

        return $this->json($user);
    }

    // Test case 4: Complex multiline #[Route] with multiple options
    #[Route(
        '/users/{id}',
        methods: ['DELETE'],
        requirements: ['id' => '\d+'],
        name: 'delete_user',
        condition: "request.headers.get('Authorization')"
    )]
    public function deleteUser(int $id): JsonResponse
    {
        return $this->json(
            ['message' => 'User deleted successfully'],
            Response::HTTP_NO_CONTENT
        );
    }

    // Test case 5: Multiline #[Route] with PATCH method
    #[Route(
        '/users/{id}/status',
        methods: ['PATCH'],
        requirements: ['id' => '\d+'],
        name: 'update_user_status'
    )]
    public function updateUserStatus(int $id, Request $request): JsonResponse
    {
        $status = $request->query->get('status');
        $reason = $request->query->get('reason', 'No reason provided');

        $response = [
            'id' => $id,
            'status' => $status,
            'reason' => $reason
        ];

        return $this->json($response);
    }

    // Test case 6: Legacy multiline @Route annotation (older Symfony versions)
    /**
     * @Route(
     *     "/legacy/users/{id}",
     *     methods={"GET"},
     *     requirements={"id"="\d+"}
     * )
     */
    public function getLegacyUser(int $id): JsonResponse
    {
        $user = [
            'id' => $id,
            'name' => 'Legacy User',
            'email' => 'legacy@example.com'
        ];

        return $this->json($user);
    }

    // Test case 7: Complex multiline @Route with all options
    /**
     * @Route(
     *     "/legacy/users",
     *     methods={"POST"},
     *     name="create_legacy_user",
     *     condition="request.getContentType() == 'json'"
     * )
     */
    public function createLegacyUser(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        $user = [
            'id' => rand(1, 1000),
            'name' => $data['name'] ?? 'Legacy User',
            'email' => $data['email'] ?? 'legacy@example.com'
        ];

        return $this->json($user, Response::HTTP_CREATED);
    }

    // Test case 8: Very complex multiline route with nested paths
    #[Route(
        '/users/{userId}/posts/{postId}/comments',
        methods: ['POST'],
        requirements: [
            'userId' => '\d+',
            'postId' => '\d+'
        ],
        name: 'create_comment'
    )]
    public function createComment(
        int $userId,
        int $postId,
        Request $request
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);

        $comment = [
            'id' => rand(1, 1000),
            'content' => $data['content'] ?? 'Default comment',
            'userId' => $userId,
            'postId' => $postId
        ];

        return $this->json($comment, Response::HTTP_CREATED);
    }

    // Test case 9: Multiline route with defaults and host constraints
    #[Route(
        '/api/users/{id}',
        methods: ['GET'],
        requirements: ['id' => '\d+'],
        defaults: ['_format' => 'json'],
        host: 'api.{domain}',
        name: 'api_get_user'
    )]
    public function getApiUser(int $id): JsonResponse
    {
        $user = [
            'id' => $id,
            'name' => 'API User',
            'email' => 'api@example.com',
            'type' => 'api'
        ];

        return $this->json($user);
    }

    // Test case 10: Mixed annotation styles in same class
    /**
     * @Route(
     *     "/mixed/users/{id}/profile",
     *     methods={"GET", "POST"},
     *     requirements={"id"="\d+"}
     * )
     */
    public function handleUserProfile(int $id, Request $request): JsonResponse
    {
        if ($request->isMethod('GET')) {
            $profile = [
                'userId' => $id,
                'description' => 'User profile'
            ];
        } else {
            $data = json_decode($request->getContent(), true);
            $profile = [
                'userId' => $id,
                'description' => $data['description'] ?? 'Updated profile'
            ];
        }

        return $this->json($profile);
    }

    // Test case 11: Complex multiline with middleware-like conditions
    #[Route(
        '/secure/users/{id}',
        methods: ['GET', 'PUT', 'DELETE'],
        requirements: ['id' => '\d+'],
        condition: "request.headers.get('Authorization') and request.headers.get('X-API-Key')",
        name: 'secure_user_operations'
    )]
    public function secureUserOperations(int $id, Request $request): JsonResponse
    {
        $method = $request->getMethod();
        $response = [
            'userId' => $id,
            'method' => $method,
            'secure' => true
        ];

        $statusCode = match($method) {
            'GET' => Response::HTTP_OK,
            'PUT' => Response::HTTP_OK,
            'DELETE' => Response::HTTP_NO_CONTENT,
            default => Response::HTTP_METHOD_NOT_ALLOWED
        };

        return $this->json($response, $statusCode);
    }

    // Test case 12: Multiline route with very complex requirements
    /**
     * @Route(
     *     "/complex/{category}/{subcategory}/{id}",
     *     methods={"GET"},
     *     requirements={
     *         "category"="[a-zA-Z]+",
     *         "subcategory"="[a-zA-Z0-9\-]+",
     *         "id"="\d+"
     *     },
     *     defaults={"_format"="json"},
     *     name="complex_nested_route"
     * )
     */
    public function complexNestedRoute(
        string $category,
        string $subcategory,
        int $id
    ): JsonResponse {
        $data = [
            'category' => $category,
            'subcategory' => $subcategory,
            'id' => $id,
            'path' => sprintf('/%s/%s/%d', $category, $subcategory, $id)
        ];

        return $this->json($data);
    }
}
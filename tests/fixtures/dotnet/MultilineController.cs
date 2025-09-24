using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.ComponentModel.DataAnnotations;

namespace Example.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MultilineController : ControllerBase
    {
        // Test case 1: Simple multiline [HttpGet]
        [HttpGet(
            "users/{id:int}"
        )]
        public ActionResult<User> GetUser(int id)
        {
            var user = new User { Id = id, Name = "John Doe", Email = "john@example.com" };
            return Ok(user);
        }

        // Test case 2: Complex multiline [HttpPost] with attributes
        [HttpPost(
            "users"
        )]
        [Consumes("application/json")]
        [Produces("application/json")]
        public ActionResult<User> CreateUser(
            [FromBody] UserCreateRequest request,
            [FromHeader(Name = "Authorization")] string authorization
        )
        {
            var user = new User { Id = 1, Name = request.Name, Email = request.Email };
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }

        // Test case 3: Multiline [HttpPut] with validation
        [HttpPut(
            "users/{id:int}"
        )]
        [Authorize]
        public ActionResult<User> UpdateUser(
            int id,
            [FromBody][Required] UserUpdateRequest request
        )
        {
            var user = new User { Id = id, Name = request.Name, Email = request.Email };
            return Ok(user);
        }

        // Test case 4: Complex multiline [HttpDelete] with response types
        [HttpDelete(
            "users/{id:int}"
        )]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public IActionResult DeleteUser(
            int id,
            [FromHeader] string apiVersion = "v1"
        )
        {
            return NoContent();
        }

        // Test case 5: Multiline [HttpPatch] with query parameters
        [HttpPatch(
            "users/{id:int}/status"
        )]
        [Produces("application/json")]
        public ActionResult<StatusResponse> UpdateUserStatus(
            int id,
            [FromQuery] string status,
            [FromQuery] string? reason = null
        )
        {
            var response = new StatusResponse
            {
                Id = id,
                Status = status,
                Reason = reason ?? "No reason provided"
            };
            return Ok(response);
        }

        // Test case 6: Complex multiline [Route] with multiple HTTP methods
        [Route(
            "users/{id:int}/posts"
        )]
        [HttpGet]
        [HttpPost]
        public ActionResult<IEnumerable<Post>> HandleUserPosts(
            int id,
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0,
            [FromBody] PostCreateRequest? createRequest = null
        )
        {
            var posts = new List<Post>
            {
                new Post { Id = 1, Title = "Sample Post", Content = "Content", UserId = id }
            };
            return Ok(posts);
        }

        // Test case 7: Very complex multiline with multiple attributes
        [HttpPost(
            "users/{userId:int}/posts/{postId:int}/comments"
        )]
        [Authorize(Roles = "User,Admin")]
        [Consumes("application/json")]
        [ProducesResponseType(typeof(Comment), 201)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        public ActionResult<Comment> CreateComment(
            int userId,
            int postId,
            [FromBody][Required] CommentCreateRequest request,
            [FromHeader(Name = "X-Request-ID")] string? requestId = null
        )
        {
            var comment = new Comment
            {
                Id = 1,
                Content = request.Content,
                UserId = userId,
                PostId = postId
            };
            return CreatedAtAction("GetComment", new { id = comment.Id }, comment);
        }

        // Test case 8: Minimal API style endpoint mapping (for .NET 6+)
        // Note: This would typically be in Program.cs, but included here for testing
        /*
        app.MapGet(
            "/api/health"
        ).WithName("HealthCheck");

        app.MapPost(
            "/api/users/{id}/activate"
        ).RequireAuthorization();

        app.MapPut(
            "/api/users/{id}/profile"
        ).WithOpenApi();

        app.MapDelete(
            "/api/users/{id}/sessions"
        ).WithTags("Authentication");

        app.MapPatch(
            "/api/users/{id}/preferences"
        ).WithSummary("Update user preferences");
        */
    }

    // Supporting classes
    public class User
    {
        public int Id { get; set; }
        public required string Name { get; set; }
        public required string Email { get; set; }
    }

    public class UserCreateRequest
    {
        [Required]
        public required string Name { get; set; }

        [Required]
        [EmailAddress]
        public required string Email { get; set; }
    }

    public class UserUpdateRequest
    {
        [Required]
        public required string Name { get; set; }

        [Required]
        [EmailAddress]
        public required string Email { get; set; }
    }

    public class StatusResponse
    {
        public int Id { get; set; }
        public required string Status { get; set; }
        public string? Reason { get; set; }
    }

    public class Post
    {
        public int Id { get; set; }
        public required string Title { get; set; }
        public required string Content { get; set; }
        public int UserId { get; set; }
    }

    public class PostCreateRequest
    {
        [Required]
        public required string Title { get; set; }

        [Required]
        public required string Content { get; set; }
    }

    public class Comment
    {
        public int Id { get; set; }
        public required string Content { get; set; }
        public int UserId { get; set; }
        public int PostId { get; set; }
    }

    public class CommentCreateRequest
    {
        [Required]
        [MinLength(1)]
        public required string Content { get; set; }
    }
}
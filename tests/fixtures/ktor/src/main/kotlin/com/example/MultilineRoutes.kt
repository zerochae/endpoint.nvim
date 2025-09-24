package com.example

import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.http.*
import kotlinx.serialization.Serializable

// Test case 1: Simple multiline route definitions
fun Application.configureMultilineRouting() {
    routing {
      route(
        "/api/multiline"
      ){
        // Test case 1: Simple multiline get route
        get(
            "/users/{id}"
        ) {
            val id = call.parameters["id"]?.toIntOrNull()
            if (id != null) {
                call.respond(User(id, "John Doe", "john@example.com"))
            } else {
                call.respond(HttpStatusCode.BadRequest, "Invalid user ID")
            }
        }

        // Test case 2: Multiline post route with complex body handling
        post(
            "/users"
        ) {
            val user = call.receive<UserCreateRequest>()
            val newUser = User(1, user.name, user.email)
            call.respond(HttpStatusCode.Created, newUser)
        }

        // Test case 3: Multiline put route with path parameters
        put(
            "/users/{id}"
        ) {
            val id = call.parameters["id"]?.toIntOrNull()
            val updateRequest = call.receive<UserUpdateRequest>()

            if (id != null) {
                val updatedUser = User(id, updateRequest.name, updateRequest.email)
                call.respond(updatedUser)
            } else {
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        // Test case 4: Complex multiline delete route
        delete(
            "/users/{id}"
        ) {
            val id = call.parameters["id"]?.toIntOrNull()
            val authHeader = call.request.headers["Authorization"]

            if (id != null && authHeader != null) {
                call.respond(HttpStatusCode.NoContent)
            } else {
                call.respond(HttpStatusCode.Unauthorized)
            }
        }

        // Test case 5: Multiline patch route with query parameters
        patch(
            "/users/{id}/status"
        ) {
            val id = call.parameters["id"]?.toIntOrNull()
            val status = call.request.queryParameters["status"]
            val reason = call.request.queryParameters["reason"]

            if (id != null && status != null) {
                val response = mapOf(
                    "id" to id,
                    "status" to status,
                    "reason" to (reason ?: "No reason provided")
                )
                call.respond(response)
            } else {
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        // Test case 6: Nested routing with multiline routes
        route("/api/v1") {
            get(
                "/users/{userId}/posts/{postId}"
            ) {
                val userId = call.parameters["userId"]?.toIntOrNull()
                val postId = call.parameters["postId"]?.toIntOrNull()

                if (userId != null && postId != null) {
                    val post = Post(postId, "Sample Post", "Content", userId)
                    call.respond(post)
                } else {
                    call.respond(HttpStatusCode.BadRequest)
                }
            }

            post(
                "/users/{userId}/posts"
            ) {
                val userId = call.parameters["userId"]?.toIntOrNull()
                val postRequest = call.receive<PostCreateRequest>()

                if (userId != null) {
                    val post = Post(1, postRequest.title, postRequest.content, userId)
                    call.respond(HttpStatusCode.Created, post)
                } else {
                    call.respond(HttpStatusCode.BadRequest)
                }
            }

            // Test case 7: Very complex multiline route with multiple parameters
            post(
                "/users/{userId}/posts/{postId}/comments"
            ) {
                val userId = call.parameters["userId"]?.toIntOrNull()
                val postId = call.parameters["postId"]?.toIntOrNull()
                val commentRequest = call.receive<CommentCreateRequest>()
                val requestId = call.request.headers["X-Request-ID"]

                if (userId != null && postId != null) {
                    val comment = Comment(1, commentRequest.content, userId, postId)
                    call.respond(HttpStatusCode.Created, comment)
                } else {
                    call.respond(HttpStatusCode.BadRequest)
                }
            }
        }

        // Test case 8: Multiline route with generic type parameters (advanced Ktor)
        get<UserLocation>(
            "/users/{id}/location"
        ) { userLocation ->
            val location = LocationResponse(
                userId = userLocation.id,
                latitude = 37.7749,
                longitude = -122.4194,
                address = "San Francisco, CA"
            )
            call.respond(location)
        }

        // Test case 9: Multiline route with complex authentication
        authenticate("jwt") {
            put(
                "/users/{id}/profile"
            ) {
                val id = call.parameters["id"]?.toIntOrNull()
                val profileRequest = call.receive<UserProfileRequest>()

                if (id != null) {
                    val profile = UserProfile(id, profileRequest.description)
                    call.respond(profile)
                } else {
                    call.respond(HttpStatusCode.BadRequest)
                }
            }
        }

        // Test case 10: Multiline WebSocket route (if applicable)
        webSocket(
            "/ws/users/{id}/notifications"
        ) {
            val userId = call.parameters["id"]
            // WebSocket handling logic would go here
            send("Connected to notifications for user $userId")
        }
        }
    }
}

// Supporting data classes
@Serializable
data class User(
    val id: Int,
    val name: String,
    val email: String
)

@Serializable
data class UserCreateRequest(
    val name: String,
    val email: String
)

@Serializable
data class UserUpdateRequest(
    val name: String,
    val email: String
)

@Serializable
data class Post(
    val id: Int,
    val title: String,
    val content: String,
    val userId: Int
)

@Serializable
data class PostCreateRequest(
    val title: String,
    val content: String
)

@Serializable
data class Comment(
    val id: Int,
    val content: String,
    val userId: Int,
    val postId: Int
)

@Serializable
data class CommentCreateRequest(
    val content: String
)

@Serializable
data class LocationResponse(
    val userId: Int,
    val latitude: Double,
    val longitude: Double,
    val address: String
)

@Serializable
data class UserProfile(
    val userId: Int,
    val description: String
)

@Serializable
data class UserProfileRequest(
    val description: String
)

// Location class for typed routing
@kotlinx.serialization.Serializable
@io.ktor.resources.Resource("/users/{id}/location")
class UserLocation(val id: Int)

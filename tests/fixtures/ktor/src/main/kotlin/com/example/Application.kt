package com.example

import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun main() {
    embeddedServer(Netty, port = 8080, host = "0.0.0.0", module = Application::module)
        .start(wait = true)
}

fun Application.module() {
    configureRouting()
}

fun Application.configureRouting() {
    routing {
        get("/") {
            call.respondText("Hello World!")
        }
        
        get("/health") {
            call.respondText("OK")
        }
        
        route("/api") {
            route("/v1") {
                get("/users") {
                    call.respondText("Get all users")
                }
                
                get("/users/{id}") {
                    val id = call.parameters["id"]
                    call.respondText("Get user: $id")
                }
                
                post("/users") {
                    call.respondText("Create user")
                }
                
                put("/users/{id}") {
                    val id = call.parameters["id"]
                    call.respondText("Update user: $id")
                }
                
                delete("/users/{id}") {
                    val id = call.parameters["id"]
                    call.respondText("Delete user: $id")
                }
                
                patch("/users/{id}/status") {
                    val id = call.parameters["id"]
                    call.respondText("Update user status: $id")
                }
            }
            
            route("/v2") {
                get("/products") {
                    call.respondText("Get all products v2")
                }
                
                get("/products/{productId}/reviews/{reviewId}") {
                    val productId = call.parameters["productId"]
                    val reviewId = call.parameters["reviewId"]
                    call.respondText("Get review $reviewId for product $productId")
                }
            }
        }
        
        // Type-safe routing example
        get<Articles> {
            call.respondText("Get articles")
        }
        
        get<ArticleById> { article ->
            call.respondText("Get article: ${article.id}")
        }
    }
}

// Type-safe routing classes
@kotlinx.serialization.Serializable
data class Articles(val page: Int? = null)

@kotlinx.serialization.Serializable
data class ArticleById(val id: Int)
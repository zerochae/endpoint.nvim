package com.example

import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Application.configureOrderRoutes() {
    routing {
        route("/orders") {
            get {
                call.respondText("Get all orders")
            }
            
            get("/{orderId}") {
                val orderId = call.parameters["orderId"]
                call.respondText("Get order: $orderId")
            }
            
            post {
                call.respondText("Create order")
            }
            
            put("/{orderId}") {
                val orderId = call.parameters["orderId"]
                call.respondText("Update order: $orderId")
            }
            
            delete("/{orderId}") {
                val orderId = call.parameters["orderId"]
                call.respondText("Delete order: $orderId")
            }
            
            route("/{orderId}/items") {
                get {
                    val orderId = call.parameters["orderId"]
                    call.respondText("Get items for order: $orderId")
                }
                
                post {
                    val orderId = call.parameters["orderId"]
                    call.respondText("Add item to order: $orderId")
                }
                
                delete("/{itemId}") {
                    val orderId = call.parameters["orderId"]
                    val itemId = call.parameters["itemId"]
                    call.respondText("Remove item $itemId from order $orderId")
                }
            }
        }
        
        // Single quotes example
        get('/analytics/dashboard') {
            call.respondText("Analytics dashboard")
        }
        
        post('/analytics/report') {
            call.respondText("Generate analytics report")
        }
    }
}
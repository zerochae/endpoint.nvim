package com.example;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/v1")
public class ApiController {
    
    @GetMapping
    public ResponseEntity<String> getApiInfo() {
        return ResponseEntity.ok("API v1 Information");
    }
    
    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("API is healthy");
    }
    
    @GetMapping(value = "/status")
    public ResponseEntity<String> getStatus() {
        return ResponseEntity.ok("Service is running");
    }
    
    @GetMapping(path = "/version")
    public ResponseEntity<String> getVersion() {
        return ResponseEntity.ok("1.0.0");
    }
    
    @GetMapping("/metrics")
    public ResponseEntity<String> getMetrics() {
        return ResponseEntity.ok("API metrics data");
    }
    
    @GetMapping("/config")
    public ResponseEntity<String> getConfig() {
        return ResponseEntity.ok("API configuration");
    }
    
    // RequestMapping with method parameter
    @RequestMapping(value = "/info", method = RequestMethod.GET)
    public ResponseEntity<String> getInfo() {
        return ResponseEntity.ok("API information via RequestMapping");
    }
    
    @RequestMapping(path = "/docs", method = RequestMethod.GET)
    public ResponseEntity<String> getDocs() {
        return ResponseEntity.ok("API documentation");
    }
    
    @PostMapping("/reset")
    public ResponseEntity<String> resetSystem() {
        return ResponseEntity.ok("System reset initiated");
    }
    
    @PostMapping(value = "/backup")
    public ResponseEntity<String> createBackup() {
        return ResponseEntity.ok("Backup created");
    }
    
    @RequestMapping(value = "/maintenance", method = RequestMethod.POST)
    public ResponseEntity<String> toggleMaintenance() {
        return ResponseEntity.ok("Maintenance mode toggled");
    }
    
    @PutMapping("/settings")
    public ResponseEntity<String> updateSettings(@RequestBody Object settings) {
        return ResponseEntity.ok("Settings updated");
    }
    
    @PutMapping(value = "/configuration")
    public ResponseEntity<String> updateConfiguration(@RequestBody Object config) {
        return ResponseEntity.ok("Configuration updated");
    }
    
    @PatchMapping("/cache")
    public ResponseEntity<String> refreshCache() {
        return ResponseEntity.ok("Cache refreshed");
    }
    
    @DeleteMapping("/cache")
    public ResponseEntity<String> clearCache() {
        return ResponseEntity.ok("Cache cleared");
    }
    
    @DeleteMapping(value = "/logs")
    public ResponseEntity<String> clearLogs() {
        return ResponseEntity.ok("Logs cleared");
    }
    
    @RequestMapping(value = "/shutdown", method = RequestMethod.DELETE)
    public ResponseEntity<String> shutdown() {
        return ResponseEntity.ok("System shutdown initiated");
    }
}
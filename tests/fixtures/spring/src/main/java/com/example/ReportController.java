package com.example;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping(value = "/reports", produces = "application/json")
public class ReportController {
    
    // Mixed annotation patterns for comprehensive testing
    
    @GetMapping
    public ResponseEntity<String> getAllReports(@RequestParam(required = false) String type,
                                              @RequestParam(required = false) String period) {
        return ResponseEntity.ok("All reports (type: " + type + ", period: " + period + ")");
    }
    
    @GetMapping("/sales")
    public ResponseEntity<String> getSalesReports() {
        return ResponseEntity.ok("Sales reports");
    }
    
    @GetMapping(value = "/financial")
    public ResponseEntity<String> getFinancialReports() {
        return ResponseEntity.ok("Financial reports");
    }
    
    @GetMapping(path = "/inventory")
    public ResponseEntity<String> getInventoryReports() {
        return ResponseEntity.ok("Inventory reports");
    }
    
    @GetMapping(value = "/users", produces = "application/pdf")
    public ResponseEntity<String> getUserReports() {
        return ResponseEntity.ok("User reports");
    }
    
    // RequestMapping variations
    @RequestMapping(value = "/performance", method = RequestMethod.GET)
    public ResponseEntity<String> getPerformanceReports() {
        return ResponseEntity.ok("Performance reports");
    }
    
    @RequestMapping(path = "/analytics", method = RequestMethod.GET, produces = "application/json")
    public ResponseEntity<String> getAnalyticsReports() {
        return ResponseEntity.ok("Analytics reports");
    }
    
    @RequestMapping(value = "/custom/{reportId}", method = RequestMethod.GET)
    public ResponseEntity<String> getCustomReport(@PathVariable Long reportId) {
        return ResponseEntity.ok("Custom report #" + reportId);
    }
    
    // Detailed report endpoints with path variables
    @GetMapping("/sales/{year}")
    public ResponseEntity<String> getSalesReportByYear(@PathVariable int year) {
        return ResponseEntity.ok("Sales report for year " + year);
    }
    
    @GetMapping(value = "/sales/{year}/{month}")
    public ResponseEntity<String> getSalesReportByMonth(@PathVariable int year, @PathVariable int month) {
        return ResponseEntity.ok("Sales report for " + month + "/" + year);
    }
    
    @GetMapping(path = "/financial/{year}/quarterly")
    public ResponseEntity<String> getQuarterlyFinancialReport(@PathVariable int year,
                                                             @RequestParam int quarter) {
        return ResponseEntity.ok("Quarterly financial report for Q" + quarter + " " + year);
    }
    
    @RequestMapping(value = "/inventory/{category}/summary", method = RequestMethod.GET)
    public ResponseEntity<String> getInventorySummary(@PathVariable String category,
                                                    @RequestParam(required = false) String warehouse) {
        return ResponseEntity.ok("Inventory summary for " + category + " in " + warehouse);
    }
    
    // Report generation endpoints
    @PostMapping("/generate")
    public ResponseEntity<String> generateReport(@RequestBody Object reportConfig) {
        return ResponseEntity.status(HttpStatus.ACCEPTED).body("Report generation started");
    }
    
    @PostMapping(value = "/custom")
    public ResponseEntity<String> generateCustomReport(@RequestBody Object customConfig) {
        return ResponseEntity.status(HttpStatus.CREATED).body("Custom report created");
    }
    
    @PostMapping(path = "/schedule")
    public ResponseEntity<String> scheduleReport(@RequestBody Object scheduleConfig) {
        return ResponseEntity.ok("Report scheduled");
    }
    
    @RequestMapping(value = "/export/{reportId}", method = RequestMethod.POST)
    public ResponseEntity<String> exportReport(@PathVariable Long reportId,
                                             @RequestParam String format) {
        return ResponseEntity.ok("Report #" + reportId + " exported as " + format);
    }
    
    @RequestMapping(path = "/email/{reportId}", method = RequestMethod.POST)
    public ResponseEntity<String> emailReport(@PathVariable Long reportId,
                                            @RequestBody Object emailConfig) {
        return ResponseEntity.ok("Report #" + reportId + " emailed");
    }
    
    // Report management endpoints
    @PutMapping("/templates/{templateId}")
    public ResponseEntity<String> updateReportTemplate(@PathVariable Long templateId,
                                                      @RequestBody Object templateDto) {
        return ResponseEntity.ok("Report template #" + templateId + " updated");
    }
    
    @PutMapping(value = "/config/{configId}")
    public ResponseEntity<String> updateReportConfig(@PathVariable Long configId,
                                                    @RequestBody Object configDto) {
        return ResponseEntity.ok("Report config #" + configId + " updated");
    }
    
    @RequestMapping(value = "/settings/{settingId}", method = RequestMethod.PUT)
    public ResponseEntity<String> updateReportSettings(@PathVariable Long settingId,
                                                      @RequestBody Object settingsDto) {
        return ResponseEntity.ok("Report settings #" + settingId + " updated");
    }
    
    @PatchMapping("/status/{reportId}")
    public ResponseEntity<String> updateReportStatus(@PathVariable Long reportId,
                                                    @RequestBody Object statusDto) {
        return ResponseEntity.ok("Status updated for report #" + reportId);
    }
    
    @PatchMapping(value = "/priority/{reportId}")
    public ResponseEntity<String> updateReportPriority(@PathVariable Long reportId,
                                                      @RequestBody Object priorityDto) {
        return ResponseEntity.ok("Priority updated for report #" + reportId);
    }
    
    @RequestMapping(value = "/archive/{reportId}", method = RequestMethod.PATCH)
    public ResponseEntity<String> archiveReport(@PathVariable Long reportId) {
        return ResponseEntity.ok("Report #" + reportId + " archived");
    }
    
    // Report cleanup endpoints
    @DeleteMapping("/{reportId}")
    public ResponseEntity<Void> deleteReport(@PathVariable Long reportId) {
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping(value = "/expired")
    public ResponseEntity<String> deleteExpiredReports() {
        return ResponseEntity.ok("Expired reports deleted");
    }
    
    @DeleteMapping(path = "/user/{userId}/reports")
    public ResponseEntity<String> deleteUserReports(@PathVariable Long userId) {
        return ResponseEntity.ok("All reports deleted for user #" + userId);
    }
    
    @RequestMapping(value = "/cache", method = RequestMethod.DELETE)
    public ResponseEntity<String> clearReportCache() {
        return ResponseEntity.ok("Report cache cleared");
    }
    
    @RequestMapping(path = "/temp-files", method = RequestMethod.DELETE)
    public ResponseEntity<String> cleanupTempFiles() {
        return ResponseEntity.ok("Temporary report files cleaned up");
    }
}
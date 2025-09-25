package com.example;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/comments")
public class CommentedController {

    // Single line commented endpoints - should be filtered
    // @GetMapping("/single-line-comment")
    // public String getSingleLineComment() { return "filtered"; }

    /* Block commented endpoints - should be filtered */
    /* @PostMapping("/block-comment") */
    /* public String getBlockComment() { return "filtered"; } */

    /*
     * Multi-line block commented endpoints - should be filtered
     * @PutMapping("/multi-line-block")
     * public String getMultiLineBlock() { return "filtered"; }
     */

    /**
     * Javadoc commented endpoints - should be filtered
     * @DeleteMapping("/javadoc-comment")
     * public String getJavadocComment() { return "filtered"; }
     */

    // Active endpoints - should NOT be filtered
    @GetMapping("/active")
    public String getActive() {
        return "active";
    }

    @PostMapping("/users")
    public String createUser() {
        return "created";
    }

    // Mixed scenarios
    /*
    @GetMapping("/mixed-block")
    public String getMixedBlock() {
        return "filtered";
    }
    */

    // @GetMapping("/commented-inline") // This should be filtered

    @PatchMapping("/active-after-comment")
    public String getActiveAfterComment() {
        return "active"; // This should NOT be filtered
    }
}
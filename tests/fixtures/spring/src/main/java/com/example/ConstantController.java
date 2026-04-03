package com.example;

import org.springframework.web.bind.annotation.*;
import com.example.constants.PathConstants;

@RestController
@RequestMapping(PathConstants.Student.BASE_V0)
public class ConstantController {

    @GetMapping
    public String root() {
        return "Student root";
    }

    @GetMapping(PathConstants.Student.GET_ALL)
    public String getAll() {
        return "All students";
    }

    @GetMapping(PathConstants.Student.GET_BY_ID)
    public String getById(@PathVariable String id) {
        return "Student: " + id;
    }

    @PostMapping(PathConstants.Student.CREATE)
    public String create() {
        return "Student created";
    }

    @GetMapping("/search")
    public String search(@RequestParam String query) {
        return "Search: " + query;
    }

    @DeleteMapping(value = PathConstants.Student.GET_BY_ID)
    public String delete(@PathVariable String id) {
        return "Student deleted: " + id;
    }
}

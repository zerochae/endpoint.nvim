package com.example.constants;

public class PathConstants {

    public static final String API_BASE = "/api";

    public static class Student {
        public static final String BASE_V0 = "/api/v0/students";
        public static final String GET_ALL = "/all";
        public static final String GET_BY_ID = "/{id}";
        public static final String CREATE = "/create";
    }

    public static class Teacher {
        public static final String BASE = "/api/v1/teachers";
        public static final String GET_ALL = "/list";
        public static final String GET_BY_ID = "/{teacherId}";
    }

    public static class Course {
        public static final String BASE = "/api/v1/courses";
        public static final String ENROLL = "/enroll";
    }
}

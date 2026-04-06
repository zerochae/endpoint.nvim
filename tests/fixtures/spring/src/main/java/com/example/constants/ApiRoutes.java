package com.example.constants;

public interface ApiRoutes {

    String API_PREFIX = "/api";

    interface Users {
        String BASE = "/api/v1/users";
        String FIND_ALL = "/list";
        String FIND_BY_ID = "/{id}";
        String CREATE = "/create";
    }

    interface Products {
        String BASE = "/api/v1/products";
        String SEARCH = "/search";
    }
}

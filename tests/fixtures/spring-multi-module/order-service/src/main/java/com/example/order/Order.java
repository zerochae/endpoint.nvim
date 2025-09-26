package com.example.order;

public class Order {
    private Long id;
    private Long userId;
    private String productName;
    private Double amount;

    public Order() {
    }

    public Order(Long id, Long userId, String productName, Double amount) {
        this.id = id;
        this.userId = userId;
        this.productName = productName;
        this.amount = amount;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public Double getAmount() {
        return amount;
    }

    public void setAmount(Double amount) {
        this.amount = amount;
    }
}
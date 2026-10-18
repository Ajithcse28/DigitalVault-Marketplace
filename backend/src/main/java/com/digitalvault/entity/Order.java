package com.digitalvault.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_number", nullable = false, unique = true, length = 64)
    private String orderNumber;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "subtotal_inr", nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotalInr;

    @Column(name = "discount_inr", precision = 10, scale = 2)
    private BigDecimal discountInr = BigDecimal.ZERO;

    @Column(name = "total_amount_inr", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmountInr;

    @Column(nullable = false, length = 30)
    private String status = "PENDING"; // PENDING, PAID, FAILED, REFUNDED

    @Column(name = "razorpay_order_id", unique = true, length = 120)
    private String razorpayOrderId;

    @Column(name = "receipt_number", length = 80)
    private String receiptNumber;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "paid_at")
    private Instant paidAt;
}

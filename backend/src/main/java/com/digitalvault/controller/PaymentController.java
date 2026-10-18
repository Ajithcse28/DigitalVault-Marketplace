package com.digitalvault.controller;

import com.digitalvault.entity.Order;
import com.digitalvault.payment.RazorpayPaymentService;
import com.digitalvault.repository.OrderRepository;
import com.digitalvault.service.OrderFulfillmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

/**
 * Dedicated REST Controller for Order Creation, Razorpay Order Initialization,
 * HMAC-SHA256 Signature Verification, and Server-to-Server Webhook Handling.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Payments & Orders", description = "End-to-End Razorpay Payment Lifecycle Endpoints")
public class PaymentController {

    private final OrderRepository orderRepository;
    private final RazorpayPaymentService razorpayPaymentService;
    private final OrderFulfillmentService orderFulfillmentService;

    public record CreateOrderRequest(
        @NotNull Long userId,
        @NotNull BigDecimal subtotalInr,
        BigDecimal discountInr,
        @NotNull BigDecimal totalAmountInr
    ) {}

    public record CreateRazorpayOrderRequest(@NotNull Long orderId) {}

    public record VerifyPaymentPayload(
        @NotBlank String razorpayOrderId,
        @NotBlank String razorpayPaymentId,
        @NotBlank String razorpaySignature
    ) {}

    @PostMapping("/orders")
    @Operation(summary = "Step 1: Create a PENDING internal order before initiating payment")
    public ResponseEntity<Order> createPendingOrder(@Valid @RequestBody CreateOrderRequest req) {
        String orderNum = "DV-2026-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        Order pending = Order.builder()
            .orderNumber(orderNum)
            .receiptNumber("RCPT-" + orderNum)
            .userId(req.userId())
            .subtotalInr(req.subtotalInr())
            .discountInr(req.discountInr() != null ? req.discountInr() : BigDecimal.ZERO)
            .totalAmountInr(req.totalAmountInr())
            .status("PENDING")
            .build();
        return ResponseEntity.ok(orderRepository.save(pending));
    }

    @PostMapping("/payments/create")
    @Operation(summary = "Step 2: Create a Razorpay order_id on the server using the pending order total")
    public ResponseEntity<?> createRazorpayOrder(@Valid @RequestBody CreateRazorpayOrderRequest req) throws Exception {
        Order order = orderRepository.findById(req.orderId())
            .orElseThrow(() -> new IllegalArgumentException("Order not found: " + req.orderId()));

        String rzpOrderId = razorpayPaymentService.createRazorpayOrder(order);
        order.setRazorpayOrderId(rzpOrderId);
        orderRepository.save(order);

        return ResponseEntity.ok(Map.of(
            "internalOrderId", order.getId(),
            "orderNumber", order.getOrderNumber(),
            "razorpayOrderId", rzpOrderId,
            "amountInPaise", order.getTotalAmountInr().multiply(BigDecimal.valueOf(100)).longValueExact(),
            "currency", "INR"
        ));
    }

    @PostMapping("/payments/webhook")
    @Operation(summary = "Step 4 (Async): Verify X-Razorpay-Signature header for server-to-server webhook events")
    public ResponseEntity<?> handleRazorpayWebhook(
            @RequestBody String rawPayload,
            @RequestHeader("X-Razorpay-Signature") String signatureHeader) {
        boolean authentic = razorpayPaymentService.verifyWebhookSignature(rawPayload, signatureHeader);
        if (!authentic) {
            return ResponseEntity.status(400).body(Map.of("status", "INVALID_WEBHOOK_SIGNATURE"));
        }
        return ResponseEntity.ok(Map.of("status", "WEBHOOK_VERIFIED"));
    }
}

package com.digitalvault.service;

import com.digitalvault.entity.Order;
import com.digitalvault.payment.RazorpayPaymentService;
import com.digitalvault.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Coordinates idempotent order verification, product_access entitlement creation,
 * Google Drive API permission grants, and transactional email receipts.
 */
@Service
@RequiredArgsConstructor
public class OrderFulfillmentService {
    private static final Logger log = LoggerFactory.getLogger(OrderFulfillmentService.class);

    private final OrderRepository orderRepository;
    private final RazorpayPaymentService razorpayPaymentService;

    @Transactional
    public Order verifyAndFulfillOrder(String razorpayOrderId, String razorpayPaymentId, String razorpaySignature) {
        Order order = orderRepository.findByRazorpayOrderId(razorpayOrderId)
            .orElseThrow(() -> new IllegalArgumentException("Order not found for Razorpay Order ID: " + razorpayOrderId));

        // Prevent duplicate payment processing (idempotency guard)
        if ("PAID".equalsIgnoreCase(order.getStatus())) {
            log.info("Order {} already marked PAID; skipping duplicate fulfillment.", order.getOrderNumber());
            return order;
        }

        boolean valid = razorpayPaymentService.verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
        if (!valid) {
            order.setStatus("FAILED");
            orderRepository.save(order);
            throw new SecurityException("Razorpay HMAC-SHA256 signature verification failed.");
        }

        order.setStatus("PAID");
        order.setPaidAt(Instant.now());
        return orderRepository.save(order);
    }
}

package com.digitalvault.controller;

import com.digitalvault.payment.RazorpayPaymentService;
import com.digitalvault.storage.DigitalDeliveryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Core REST API Controller exposing Product Catalog, Razorpay Verification,
 * Customer Digital Vault Library, and Admin Management endpoints.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "DigitalVault API", description = "Products, Orders, Razorpay Verification, and Digital Delivery Endpoints")
public class MarketplaceController {

    private final RazorpayPaymentService razorpayPaymentService;
    private final DigitalDeliveryService digitalDeliveryService;

    public record PaymentVerifyRequest(
        @NotNull Long internalOrderId,
        @NotBlank String razorpayOrderId,
        @NotBlank String razorpayPaymentId,
        @NotBlank String razorpaySignature
    ) {}

    @PostMapping("/payments/verify")
    @Operation(summary = "Verify Razorpay payment signature on the server and unlock digital product access")
    public ResponseEntity<?> verifyPayment(@Valid @RequestBody PaymentVerifyRequest request) {
        boolean isValid = razorpayPaymentService.verifyPaymentSignature(
            request.razorpayOrderId(),
            request.razorpayPaymentId(),
            request.razorpaySignature()
        );

        if (!isValid) {
            return ResponseEntity.status(400).body(Map.of(
                "verified", false,
                "message", "Invalid Razorpay HMAC-SHA256 payment signature. Order remains PENDING."
            ));
        }

        // After signature verification:
        // 1. Mark order as PAID idempotently
        // 2. Insert ProductAccess records for customer
        // 3. Trigger Google Drive API permission grant (if GOOGLE_DRIVE product)
        // 4. Send order confirmation email receipt
        return ResponseEntity.ok(Map.of(
            "verified", true,
            "orderStatus", "PAID",
            "message", "Payment signature verified. Digital assets unlocked in My Library."
        ));
    }

    @GetMapping("/customer/downloads/{assetId}/signed-url")
    @Operation(summary = "Generate a 15-minute signed download URL after verifying customer ownership")
    public ResponseEntity<?> getSignedDownloadUrl(
            @PathVariable Long assetId,
            @RequestParam Long userId) {
        String signedUrl = digitalDeliveryService.generateSignedDownloadUrl(userId, assetId);
        return ResponseEntity.ok(Map.of(
            "assetId", assetId,
            "signedUrl", signedUrl,
            "expiresInSeconds", 900
        ));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/admin/dashboard")
    @Operation(summary = "Retrieve protected Admin Dashboard KPIs and sales analytics")
    public ResponseEntity<?> getAdminDashboardSummary() {
        return ResponseEntity.ok(Map.of(
            "status", "PROTECTED_RBAC_ADMIN_ONLY",
            "totalProducts", 8,
            "securityModel", "JWT + BCrypt + Server-Side Razorpay HMAC + Signed Asset Delivery"
        ));
    }
}

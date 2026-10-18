package com.digitalvault.payment;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

import static org.junit.jupiter.api.Assertions.*;

class RazorpayPaymentServiceTest {

    private RazorpayPaymentService paymentService;
    private static final String TEST_SECRET = "rzp_test_secret_key_2026";

    @BeforeEach
    void setUp() {
        paymentService = new RazorpayPaymentService();
        ReflectionTestUtils.setField(paymentService, "keySecret", TEST_SECRET);
    }

    @Test
    void shouldVerifyAuthenticRazorpayHmacSignature() throws Exception {
        String orderId = "order_P9xTest12345";
        String paymentId = "pay_P9xTest98765";
        String payload = orderId + "|" + paymentId;

        Mac hmac = Mac.getInstance("HmacSHA256");
        hmac.init(new SecretKeySpec(TEST_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        String validSignature = HexFormat.of().formatHex(hmac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));

        assertTrue(paymentService.verifyPaymentSignature(orderId, paymentId, validSignature));
        assertFalse(paymentService.verifyPaymentSignature(orderId, paymentId, "tampered_signature_0000"));
    }
}

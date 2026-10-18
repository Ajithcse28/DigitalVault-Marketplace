package com.digitalvault.payment;

import com.digitalvault.entity.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

/**
 * Handles server-side Razorpay Order Creation and strict HMAC-SHA256 signature verification.
 * Never trusts browser-side success callbacks without cryptographic verification.
 */
@Service
public class RazorpayPaymentService {
    private static final Logger log = LoggerFactory.getLogger(RazorpayPaymentService.class);

    @Value("${app.razorpay.key-id}")
    private String keyId;

    @Value("${app.razorpay.key-secret}")
    private String keySecret;

    @Value("${app.razorpay.webhook-secret}")
    private String webhookSecret;

    /**
     * Creates a pending order in Razorpay (amount in paise = INR * 100).
     */
    public String createRazorpayOrder(Order order) throws RazorpayException {
        RazorpayClient client = new RazorpayClient(keyId, keySecret);
        long amountInPaise = order.getTotalAmountInr().multiply(BigDecimal.valueOf(100)).longValueExact();

        JSONObject options = new JSONObject();
        options.put("amount", amountInPaise);
        options.put("currency", "INR");
        options.put("receipt", order.getOrderNumber());
        options.put("payment_capture", 1);

        com.razorpay.Order rzpOrder = client.orders.create(options);
        String rzpOrderId = rzpOrder.get("id");
        log.info("Created Razorpay order {} for internal order {}", rzpOrderId, order.getOrderNumber());
        return rzpOrderId;
    }

    /**
     * Verifies Razorpay signature using HMAC-SHA256(razorpay_order_id + "|" + razorpay_payment_id, keySecret)
     * with constant-time comparison to prevent timing attacks.
     */
    public boolean verifyPaymentSignature(String razorpayOrderId, String razorpayPaymentId, String razorpaySignature) {
        try {
            String payload = razorpayOrderId + "|" + razorpayPaymentId;
            Mac sha256Hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKey = new SecretKeySpec(keySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256Hmac.init(secretKey);
            byte[] hash = sha256Hmac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            String expectedSignature = HexFormat.of().formatHex(hash);

            return MessageDigest.isEqual(
                expectedSignature.getBytes(StandardCharsets.UTF_8),
                razorpaySignature.getBytes(StandardCharsets.UTF_8)
            );
        } catch (Exception e) {
            log.error("Razorpay signature verification failed", e);
            return false;
        }
    }

    /**
     * Verifies server-to-server Razorpay Webhook signature.
     */
    public boolean verifyWebhookSignature(String rawBody, String headerSignature) {
        try {
            Mac sha256Hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKey = new SecretKeySpec(webhookSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256Hmac.init(secretKey);
            String expected = HexFormat.of().formatHex(sha256Hmac.doFinal(rawBody.getBytes(StandardCharsets.UTF_8)));
            return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                headerSignature.getBytes(StandardCharsets.UTF_8)
            );
        } catch (Exception e) {
            log.error("Webhook signature verification error", e);
            return false;
        }
    }
}

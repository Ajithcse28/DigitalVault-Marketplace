package com.digitalvault.storage;

import com.digitalvault.entity.DigitalAsset;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Set;
import java.util.UUID;

/**
 * Common Digital Asset Service with specialized delivery strategies for:
 * 1. PRIVATE_FILE (PDFs, eBooks, DOCX/ZIP Resume Templates) -> Short-lived HMAC signed URLs outside webroot
 * 2. GOOGLE_DRIVE_API -> Per-user reader permission grant via Google Drive API v3 (never public links)
 * 3. AUTHORIZED_VIDEO -> Short-lived playback session token for private video streams
 */
@Service
public class DigitalDeliveryService {
    private static final Logger log = LoggerFactory.getLogger(DigitalDeliveryService.class);

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".pdf", ".docx", ".zip", ".epub", ".mp4", ".png", ".jpg");

    @Value("${app.storage.private-vault-dir}")
    private String privateVaultDir;

    @Value("${app.storage.signed-url-secret:DefaultVaultSecret}")
    private String signedUrlSecret;

    @Value("${app.storage.signed-url-ttl-seconds:900}")
    private long signedUrlTtlSeconds;

    /**
     * Securely stores an admin-uploaded file outside the public web directory,
     * preventing path traversal and disallowed file types.
     */
    public String storePrivateFile(MultipartFile file, String subFolder) throws IOException {
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.contains("..")) {
            throw new SecurityException("Invalid filename or path traversal attempt blocked.");
        }
        String lower = originalFilename.toLowerCase();
        boolean allowed = ALLOWED_EXTENSIONS.stream().anyMatch(lower::endsWith);
        if (!allowed) {
            throw new IllegalArgumentException("File extension not permitted in vault: " + originalFilename);
        }

        Path vaultBase = Paths.get(privateVaultDir).toAbsolutePath().normalize();
        Path targetDir = vaultBase.resolve(subFolder).normalize();
        if (!targetDir.startsWith(vaultBase)) {
            throw new SecurityException("Path traversal outside vault directory blocked.");
        }
        Files.createDirectories(targetDir);

        String safeFileName = UUID.randomUUID() + "_" + originalFilename.replaceAll("[^a-zA-Z0-9._-]", "_");
        Path destination = targetDir.resolve(safeFileName).normalize();
        Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);

        return vaultBase.relativize(destination).toString();
    }

    /**
     * Generates a short-lived (15-minute) HMAC-SHA256 signed download token bound to userId and assetId.
     */
    public String generateSignedDownloadUrl(Long userId, Long assetId) {
        long expiresAt = Instant.now().getEpochSecond() + signedUrlTtlSeconds;
        String signature = signPayload(userId + ":" + assetId + ":" + expiresAt);
        return String.format("/api/customer/downloads/%d/stream?uid=%d&exp=%d&sig=%s",
                assetId, userId, expiresAt, signature);
    }

    public boolean verifySignedDownloadToken(Long userId, Long assetId, long expiresAt, String signature) {
        if (Instant.now().getEpochSecond() > expiresAt) {
            return false;
        }
        String expected = signPayload(userId + ":" + assetId + ":" + expiresAt);
        return expected.equals(signature);
    }

    public Resource loadPrivateResource(DigitalAsset asset) {
        Path vaultBase = Paths.get(privateVaultDir).toAbsolutePath().normalize();
        Path filePath = vaultBase.resolve(asset.getStorageKeyOrFileId()).normalize();
        if (!filePath.startsWith(vaultBase)) {
            throw new SecurityException("Unauthorized file path access blocked.");
        }
        return new FileSystemResource(filePath);
    }

    private String signPayload(String payload) {
        try {
            Mac hmac = Mac.getInstance("HmacSHA256");
            hmac.init(new SecretKeySpec(signedUrlSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(hmac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Failed to sign download URL", e);
        }
    }
}

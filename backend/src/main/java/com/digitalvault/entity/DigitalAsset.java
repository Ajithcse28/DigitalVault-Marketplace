package com.digitalvault.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

/**
 * Stores metadata and internal storage references for private files, Google Drive fileIds,
 * or private video stream identifiers. Never serialized directly into public Product DTOs.
 */
@Entity
@Table(name = "digital_assets")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DigitalAsset {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(name = "asset_name", nullable = false, length = 200)
    private String assetName;

    @Column(name = "delivery_type", nullable = false, length = 40)
    private String deliveryType; // PRIVATE_FILE, GOOGLE_DRIVE_API, AUTHORIZED_VIDEO

    @Column(name = "storage_provider", nullable = false, length = 40)
    private String storageProvider; // LOCAL_VAULT, S3_PRIVATE, GOOGLE_DRIVE, VIMEO_PRIVATE

    @Column(name = "storage_key_or_file_id", nullable = false, length = 500)
    private String storageKeyOrFileId;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "checksum_sha256", length = 64)
    private String checksumSha256;

    @Column(name = "access_notes", columnDefinition = "TEXT")
    private String accessNotes;

    @Column(name = "is_active")
    private boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt = Instant.now();
}

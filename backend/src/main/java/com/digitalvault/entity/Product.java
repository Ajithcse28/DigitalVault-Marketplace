package com.digitalvault.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "products")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, unique = true, length = 220)
    private String slug;

    @Column(name = "short_description", nullable = false, length = 500)
    private String shortDescription;

    @Column(name = "detailed_description", nullable = false, columnDefinition = "TEXT")
    private String detailedDescription;

    @Column(name = "whats_included", columnDefinition = "TEXT")
    private String whatsIncluded;

    @Column(name = "product_type", nullable = false, length = 50)
    private String productType; // PDF_EBOOK, GOOGLE_DRIVE, VIDEO_COURSE, RESUME_TEMPLATE, RESUME_BUNDLE, STUDY_MATERIAL

    @Column(name = "career_track", length = 80)
    private String careerTrack;

    @Column(name = "price_inr", nullable = false, precision = 10, scale = 2)
    private BigDecimal priceInr;

    @Column(name = "discount_price_inr", precision = 10, scale = 2)
    private BigDecimal discountPriceInr;

    @Column(name = "is_free")
    private boolean isFree;

    @Column(name = "cover_image_url", length = 500)
    private String coverImageUrl;

    @Column(name = "preview_video_url", length = 500)
    private String previewVideoUrl;

    @Column(name = "file_format", length = 80)
    private String fileFormat;

    @Column(name = "file_size_label", length = 50)
    private String fileSizeLabel;

    @Column(name = "video_duration_label", length = 50)
    private String videoDurationLabel;

    @Column(name = "compatibility_info", length = 255)
    private String compatibilityInfo;

    @Column(name = "is_featured")
    private boolean isFeatured;

    @Column(name = "is_bestseller")
    private boolean isBestseller;

    @Column(name = "is_published")
    private boolean isPublished = true;

    @Column(name = "is_demo_product")
    private boolean isDemoProduct = true;

    @Column(name = "sales_count")
    private int salesCount = 0;

    @Column(name = "rating_avg", precision = 3, scale = 2)
    private BigDecimal ratingAvg = BigDecimal.ZERO;

    @Column(name = "review_count")
    private int reviewCount = 0;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt = Instant.now();
}

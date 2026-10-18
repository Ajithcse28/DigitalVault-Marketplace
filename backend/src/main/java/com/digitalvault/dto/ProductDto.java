package com.digitalvault.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public record ProductDto(
    Long id,
    @NotNull Long categoryId,
    String categoryName,
    @NotBlank @Size(max = 200) String title,
    String slug,
    @NotBlank @Size(max = 500) String shortDescription,
    @NotBlank String detailedDescription,
    List<String> whatsIncluded,
    @NotBlank String productType,
    String careerTrack,
    @NotNull @DecimalMin("0.00") BigDecimal priceInr,
    BigDecimal discountPriceInr,
    boolean isFree,
    String coverImageUrl,
    String previewVideoUrl,
    String fileFormat,
    String fileSizeLabel,
    String videoDurationLabel,
    String compatibilityInfo,
    boolean isFeatured,
    boolean isBestseller,
    boolean isPublished,
    boolean isDemoProduct,
    int salesCount,
    BigDecimal ratingAvg,
    int reviewCount
) {}

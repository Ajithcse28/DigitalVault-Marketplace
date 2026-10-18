package com.digitalvault.repository;

import com.digitalvault.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository extends JpaRepository<Product, Long> {
    @Query("SELECT p FROM Product p WHERE p.isPublished = true " +
           "AND (:categoryId IS NULL OR p.category.id = :categoryId) " +
           "AND (:query IS NULL OR LOWER(p.title) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(p.shortDescription) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Product> searchPublishedProducts(
        @Param("categoryId") Long categoryId,
        @Param("query") String query,
        Pageable pageable
    );
}

package com.fintrack.category;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoryRepository extends JpaRepository<Category, UUID> {

  Optional<Category> findByIdAndUserId(UUID id, UUID userId);

  boolean existsByUserIdAndNameIgnoreCaseAndKind(UUID userId, String name, CategoryKind kind);

  boolean existsByUserIdAndNameIgnoreCaseAndKindAndIdNot(
      UUID userId, String name, CategoryKind kind, UUID id);

  @Query(
      """
        SELECT c FROM Category c
        WHERE c.userId = :userId
          AND (:kind IS NULL OR c.kind = :kind)
          AND (:includeArchived = true OR c.archived = false)
        ORDER BY c.name ASC
        """)
  List<Category> findAllForUser(
      @Param("userId") UUID userId,
      @Param("kind") CategoryKind kind,
      @Param("includeArchived") boolean includeArchived);

  @Query(
      value =
          """
            SELECT COUNT(*) > 0
            FROM transactions t
            WHERE t.user_id = :userId AND t.category_id = :categoryId
            """,
      nativeQuery = true)
  boolean hasTransactions(@Param("userId") UUID userId, @Param("categoryId") UUID categoryId);

  @Query(
      value =
          """
            SELECT COUNT(*) > 0
            FROM budgets b
            WHERE b.user_id = :userId AND b.category_id = :categoryId
            """,
      nativeQuery = true)
  boolean hasBudgets(@Param("userId") UUID userId, @Param("categoryId") UUID categoryId);
}

package com.fintrack.budget;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, UUID> {

  Optional<Budget> findByIdAndUserId(UUID id, UUID userId);

  Optional<Budget> findByUserIdAndCategoryIdAndYearMonth(
      UUID userId, UUID categoryId, String yearMonth);

  List<Budget> findByUserIdAndYearMonth(UUID userId, String yearMonth);

  @Query(
      value =
          """
        SELECT b.id AS id,
               b.category_id AS categoryId,
               c.name AS categoryName,
               c.color AS categoryColor,
               c.icon AS categoryIcon,
               b.year_month AS yearMonth,
               b.limit_amount AS limitAmount,
               COALESCE(SUM(t.amount), 0) AS spentAmount
        FROM budgets b
        JOIN categories c
               ON c.id = b.category_id
              AND c.user_id = b.user_id
        LEFT JOIN transactions t
               ON t.category_id = b.category_id
              AND t.user_id = b.user_id
              AND t.type = 'EXPENSE'
              AND t.date >= :monthStart
              AND t.date < :monthEnd
        WHERE b.user_id = :userId
          AND b.year_month = :yearMonth
        GROUP BY b.id, b.category_id, c.name, c.color, c.icon, b.year_month, b.limit_amount
        ORDER BY c.name ASC
        """,
      nativeQuery = true)
  List<BudgetWithSpentRow> findAllWithSpentForMonth(
      @Param("userId") UUID userId,
      @Param("yearMonth") String yearMonth,
      @Param("monthStart") java.time.LocalDate monthStart,
      @Param("monthEnd") java.time.LocalDate monthEnd);

  @Query(
      value =
          """
        SELECT b.id AS id,
               b.category_id AS categoryId,
               c.name AS categoryName,
               c.color AS categoryColor,
               c.icon AS categoryIcon,
               b.year_month AS yearMonth,
               b.limit_amount AS limitAmount,
               COALESCE(SUM(t.amount), 0) AS spentAmount
        FROM budgets b
        JOIN categories c
               ON c.id = b.category_id
              AND c.user_id = b.user_id
        LEFT JOIN transactions t
               ON t.category_id = b.category_id
              AND t.user_id = b.user_id
              AND t.type = 'EXPENSE'
              AND t.date >= :monthStart
              AND t.date < :monthEnd
        WHERE b.user_id = :userId
          AND b.id = :budgetId
        GROUP BY b.id, b.category_id, c.name, c.color, c.icon, b.year_month, b.limit_amount
        """,
      nativeQuery = true)
  Optional<BudgetWithSpentRow> findOneWithSpent(
      @Param("userId") UUID userId,
      @Param("budgetId") UUID budgetId,
      @Param("monthStart") java.time.LocalDate monthStart,
      @Param("monthEnd") java.time.LocalDate monthEnd);
}

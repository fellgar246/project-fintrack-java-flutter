package com.fintrack.report;

import com.fintrack.account.AccountBalanceSql;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ReportRepository
    extends JpaRepository<com.fintrack.transaction.Transaction, UUID> {

  @Query(
      value =
          """
        WITH account_monthly AS (
            SELECT a.id AS accountId,
                   a.name AS name,
                   COALESCE(SUM(CASE
                       WHEN t.type = 'INCOME'
                        AND t.date >= :monthStart
                        AND t.date < :monthEnd
                        AND t.account_id = a.id
                       THEN t.amount END), 0) AS income,
                   COALESCE(SUM(CASE
                       WHEN t.type = 'EXPENSE'
                        AND t.date >= :monthStart
                        AND t.date < :monthEnd
                        AND t.account_id = a.id
                       THEN t.amount END), 0) AS expense,
                   """
              + AccountBalanceSql.CURRENT_BALANCE_EXPR
              + """
                   AS currentBalance
            FROM accounts a
            """
              + AccountBalanceSql.TRANSACTION_JOIN
              + """
            WHERE a.user_id = :userId
              AND a.archived = false
            GROUP BY a.id, a.name, a.initial_balance
        )
        SELECT accountId,
               name,
               income,
               expense,
               currentBalance,
               SUM(income) OVER () AS totalIncome,
               SUM(expense) OVER () AS totalExpense
        FROM account_monthly
        ORDER BY name ASC
        """,
      nativeQuery = true)
  List<SummaryAccountRow> findSummaryForMonth(
      @Param("userId") UUID userId,
      @Param("monthStart") LocalDate monthStart,
      @Param("monthEnd") LocalDate monthEnd);

  @Query(
      value =
          """
        SELECT c.id AS categoryId,
               c.name AS name,
               c.color AS color,
               c.icon AS icon,
               COALESCE(SUM(t.amount), 0) AS total
        FROM transactions t
        JOIN categories c
          ON c.id = t.category_id
         AND c.user_id = t.user_id
        WHERE t.user_id = :userId
          AND t.type = :kind
          AND c.kind = :kind
          AND t.date >= :monthStart
          AND t.date < :monthEnd
        GROUP BY c.id, c.name, c.color, c.icon
        ORDER BY total DESC
        """,
      nativeQuery = true)
  List<ByCategoryRow> findByCategoryForMonth(
      @Param("userId") UUID userId,
      @Param("kind") String kind,
      @Param("monthStart") LocalDate monthStart,
      @Param("monthEnd") LocalDate monthEnd);

  @Query(
      value =
          """
        WITH months AS (
            SELECT CAST(d AS date) AS month_start,
                   to_char(d, 'YYYY-MM') AS year_month
            FROM generate_series(
                CAST(:seriesStart AS date),
                CAST(:seriesEnd AS date),
                interval '1 month'
            ) AS d
        )
        SELECT m.year_month AS yearMonth,
               COALESCE(SUM(CASE WHEN t.type = 'INCOME' THEN t.amount END), 0) AS income,
               COALESCE(SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount END), 0) AS expense
        FROM months m
        LEFT JOIN transactions t
               ON t.user_id = :userId
              AND t.date >= m.month_start
              AND t.date < (m.month_start + interval '1 month')::date
              AND t.type IN ('INCOME', 'EXPENSE')
        GROUP BY m.year_month, m.month_start
        ORDER BY m.month_start ASC
        """,
      nativeQuery = true)
  List<TrendRow> findTrend(
      @Param("userId") UUID userId,
      @Param("seriesStart") LocalDate seriesStart,
      @Param("seriesEnd") LocalDate seriesEnd);
}

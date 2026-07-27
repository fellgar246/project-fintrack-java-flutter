package com.fintrack.account;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AccountRepository extends JpaRepository<Account, UUID> {

  Optional<Account> findByIdAndUserId(UUID id, UUID userId);

  boolean existsByUserIdAndNameIgnoreCase(UUID userId, String name);

  boolean existsByUserIdAndNameIgnoreCaseAndIdNot(UUID userId, String name, UUID id);

  @Query(value = """
      SELECT a.id AS id,
             a.name AS name,
             a.type AS type,
             a.initial_balance AS initialBalance,
             a.archived AS archived,
             a.created_at AS createdAt,
             a.initial_balance
           + COALESCE(SUM(CASE WHEN t.type = 'INCOME'   AND t.account_id = a.id THEN t.amount END), 0)
           - COALESCE(SUM(CASE WHEN t.type = 'EXPENSE'  AND t.account_id = a.id THEN t.amount END), 0)
           - COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.account_id = a.id THEN t.amount END), 0)
           + COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.transfer_account_id = a.id THEN t.amount END), 0)
             AS currentBalance
      FROM accounts a
      LEFT JOIN transactions t
             ON (t.account_id = a.id OR t.transfer_account_id = a.id)
            AND t.user_id = a.user_id
      WHERE a.user_id = :userId
        AND (:includeArchived = true OR a.archived = false)
      GROUP BY a.id, a.name, a.type, a.initial_balance, a.archived, a.created_at
      ORDER BY a.name ASC
      """, nativeQuery = true)
  List<AccountBalanceRow> findAllWithBalance(
      @Param("userId") UUID userId,
      @Param("includeArchived") boolean includeArchived);

  @Query(value = """
      SELECT a.id AS id,
             a.name AS name,
             a.type AS type,
             a.initial_balance AS initialBalance,
             a.archived AS archived,
             a.created_at AS createdAt,
             a.initial_balance
           + COALESCE(SUM(CASE WHEN t.type = 'INCOME'   AND t.account_id = a.id THEN t.amount END), 0)
           - COALESCE(SUM(CASE WHEN t.type = 'EXPENSE'  AND t.account_id = a.id THEN t.amount END), 0)
           - COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.account_id = a.id THEN t.amount END), 0)
           + COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.transfer_account_id = a.id THEN t.amount END), 0)
             AS currentBalance
      FROM accounts a
      LEFT JOIN transactions t
             ON (t.account_id = a.id OR t.transfer_account_id = a.id)
            AND t.user_id = a.user_id
      WHERE a.user_id = :userId
        AND a.id = :accountId
      GROUP BY a.id, a.name, a.type, a.initial_balance, a.archived, a.created_at
      """, nativeQuery = true)
  Optional<AccountBalanceRow> findOneWithBalance(
      @Param("userId") UUID userId,
      @Param("accountId") UUID accountId);

  @Query(value = """
      SELECT COUNT(*) > 0
      FROM transactions t
      WHERE t.user_id = :userId
        AND (t.account_id = :accountId OR t.transfer_account_id = :accountId)
      """, nativeQuery = true)
  boolean hasTransactions(@Param("userId") UUID userId, @Param("accountId") UUID accountId);
}

package com.fintrack.account;

/**
 * Shared SQL fragments for RB-01 current-balance calculation. Used by
 * {@link AccountRepository} and report aggregations so balance logic stays in one place.
 */
public final class AccountBalanceSql {

    private AccountBalanceSql() {
    }

    public static final String TRANSACTION_JOIN = """
        LEFT JOIN transactions t
               ON (t.account_id = a.id OR t.transfer_account_id = a.id)
              AND t.user_id = a.user_id
        """;

    public static final String CURRENT_BALANCE_EXPR = """
        a.initial_balance
      + COALESCE(SUM(CASE WHEN t.type = 'INCOME'   AND t.account_id = a.id THEN t.amount END), 0)
      - COALESCE(SUM(CASE WHEN t.type = 'EXPENSE'  AND t.account_id = a.id THEN t.amount END), 0)
      - COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.account_id = a.id THEN t.amount END), 0)
      + COALESCE(SUM(CASE WHEN t.type = 'TRANSFER' AND t.transfer_account_id = a.id THEN t.amount END), 0)
        """;
}

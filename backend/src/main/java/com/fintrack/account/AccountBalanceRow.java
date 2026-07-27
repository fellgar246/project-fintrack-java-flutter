package com.fintrack.account;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Projection for the RB-01 balance query: one row per account with currentBalance
 * computed in a single SQL pass (no N+1).
 */
public interface AccountBalanceRow {

    UUID getId();

    String getName();

    String getType();

    BigDecimal getInitialBalance();

    BigDecimal getCurrentBalance();

    boolean getArchived();

    Instant getCreatedAt();
}

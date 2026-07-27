package com.fintrack.budget;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Projection for budget list with spent amount aggregated in a single SQL pass.
 */
public interface BudgetWithSpentRow {

    UUID getId();

    UUID getCategoryId();

    String getCategoryName();

    String getCategoryColor();

    String getCategoryIcon();

    String getYearMonth();

    BigDecimal getLimitAmount();

    BigDecimal getSpentAmount();
}

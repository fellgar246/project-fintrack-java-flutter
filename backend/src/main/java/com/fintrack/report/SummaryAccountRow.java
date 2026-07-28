package com.fintrack.report;

import java.math.BigDecimal;
import java.util.UUID;

public interface SummaryAccountRow {

    UUID getAccountId();

    String getName();

    BigDecimal getIncome();

    BigDecimal getExpense();

    BigDecimal getCurrentBalance();

    BigDecimal getTotalIncome();

    BigDecimal getTotalExpense();
}

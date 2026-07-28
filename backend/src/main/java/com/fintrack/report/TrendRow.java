package com.fintrack.report;

import java.math.BigDecimal;

public interface TrendRow {

    String getYearMonth();

    BigDecimal getIncome();

    BigDecimal getExpense();
}

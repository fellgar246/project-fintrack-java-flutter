package com.fintrack.report;

import java.math.BigDecimal;
import java.util.UUID;

public interface ByCategoryRow {

    UUID getCategoryId();

    String getName();

    String getColor();

    String getIcon();

    BigDecimal getTotal();
}

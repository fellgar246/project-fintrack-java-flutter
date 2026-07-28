package com.fintrack.budget;

import com.fintrack.budget.dto.BudgetResponse;
import com.fintrack.transaction.dto.TransactionCategorySummary;
import java.math.BigDecimal;
import java.math.RoundingMode;
import org.springframework.stereotype.Component;

@Component
public class BudgetMapper {

  private static final BigDecimal HUNDRED = new BigDecimal("100");
  private static final BigDecimal WARNING_THRESHOLD = new BigDecimal("70");

  public BudgetResponse toResponse(BudgetWithSpentRow row) {
    return toResponse(
        row.getId(),
        row.getCategoryId(),
        row.getCategoryName(),
        row.getCategoryColor(),
        row.getCategoryIcon(),
        row.getYearMonth(),
        row.getLimitAmount(),
        row.getSpentAmount());
  }

  public BudgetResponse toResponse(
      java.util.UUID id,
      java.util.UUID categoryId,
      String categoryName,
      String categoryColor,
      String categoryIcon,
      String yearMonth,
      BigDecimal limitAmount,
      BigDecimal spentAmount) {
    TransactionCategorySummary category =
        TransactionCategorySummary.builder()
            .id(categoryId)
            .name(categoryName)
            .color(categoryColor)
            .icon(categoryIcon)
            .build();

    BigDecimal remaining = limitAmount.subtract(spentAmount);
    BigDecimal percentUsed =
        spentAmount.multiply(HUNDRED).divide(limitAmount, 2, RoundingMode.HALF_UP);

    return BudgetResponse.builder()
        .id(id)
        .category(category)
        .yearMonth(yearMonth)
        .limitAmount(formatAmount(limitAmount))
        .spentAmount(formatAmount(spentAmount))
        .remainingAmount(formatAmount(remaining))
        .percentUsed(percentUsed)
        .status(resolveStatus(percentUsed))
        .build();
  }

  public BudgetResponse toUnbudgetedResponse(
      java.util.UUID categoryId,
      String categoryName,
      String categoryColor,
      String categoryIcon,
      String yearMonth) {
    TransactionCategorySummary category =
        TransactionCategorySummary.builder()
            .id(categoryId)
            .name(categoryName)
            .color(categoryColor)
            .icon(categoryIcon)
            .build();

    return BudgetResponse.builder()
        .id(null)
        .category(category)
        .yearMonth(yearMonth)
        .limitAmount(null)
        .spentAmount(null)
        .remainingAmount(null)
        .percentUsed(null)
        .status(null)
        .build();
  }

  BudgetStatus resolveStatus(BigDecimal percentUsed) {
    if (percentUsed.compareTo(HUNDRED) >= 0) {
      return BudgetStatus.EXCEEDED;
    }
    if (percentUsed.compareTo(WARNING_THRESHOLD) >= 0) {
      return BudgetStatus.WARNING;
    }
    return BudgetStatus.OK;
  }

  private String formatAmount(BigDecimal amount) {
    return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
  }
}

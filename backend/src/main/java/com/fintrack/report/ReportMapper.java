package com.fintrack.report;

import com.fintrack.report.dto.ByCategoryResponse;
import com.fintrack.report.dto.SummaryResponse;
import com.fintrack.report.dto.TrendResponse;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class ReportMapper {

  public SummaryResponse toSummaryResponse(String yearMonth, List<SummaryAccountRow> rows) {
    BigDecimal totalIncome = BigDecimal.ZERO;
    BigDecimal totalExpense = BigDecimal.ZERO;

    if (!rows.isEmpty()) {
      totalIncome = nullToZero(rows.getFirst().getTotalIncome());
      totalExpense = nullToZero(rows.getFirst().getTotalExpense());
    }

    BigDecimal net = totalIncome.subtract(totalExpense);

    List<SummaryResponse.AccountSummaryItem> byAccount =
        rows.stream()
            .map(
                row ->
                    SummaryResponse.AccountSummaryItem.builder()
                        .accountId(row.getAccountId())
                        .name(row.getName())
                        .income(formatAmount(row.getIncome()))
                        .expense(formatAmount(row.getExpense()))
                        .currentBalance(formatAmount(row.getCurrentBalance()))
                        .build())
            .toList();

    return SummaryResponse.builder()
        .yearMonth(yearMonth)
        .totalIncome(formatAmount(totalIncome))
        .totalExpense(formatAmount(totalExpense))
        .net(formatAmount(net))
        .byAccount(byAccount)
        .build();
  }

  public List<ByCategoryResponse> toByCategoryResponses(List<ByCategoryRow> rows) {
    BigDecimal grandTotal =
        rows.stream()
            .map(row -> nullToZero(row.getTotal()))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    if (grandTotal.compareTo(BigDecimal.ZERO) == 0) {
      return List.of();
    }

    return rows.stream()
        .map(
            row -> {
              BigDecimal total = nullToZero(row.getTotal());
              BigDecimal percent =
                  total.multiply(new BigDecimal("100")).divide(grandTotal, 2, RoundingMode.HALF_UP);

              return ByCategoryResponse.builder()
                  .categoryId(row.getCategoryId())
                  .name(row.getName())
                  .color(row.getColor())
                  .icon(row.getIcon())
                  .total(formatAmount(total))
                  .percent(percent)
                  .build();
            })
        .toList();
  }

  public TrendResponse toTrendResponse(TrendRow row) {
    BigDecimal income = nullToZero(row.getIncome());
    BigDecimal expense = nullToZero(row.getExpense());
    BigDecimal net = income.subtract(expense);

    return TrendResponse.builder()
        .yearMonth(row.getYearMonth())
        .income(formatAmount(income))
        .expense(formatAmount(expense))
        .net(formatAmount(net))
        .build();
  }

  private BigDecimal nullToZero(BigDecimal value) {
    return value == null ? BigDecimal.ZERO : value;
  }

  private String formatAmount(BigDecimal amount) {
    return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
  }
}

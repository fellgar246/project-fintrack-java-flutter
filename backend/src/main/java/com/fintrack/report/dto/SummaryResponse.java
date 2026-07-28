package com.fintrack.report.dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SummaryResponse {

  private String yearMonth;
  private String totalIncome;
  private String totalExpense;
  private String net;
  private List<AccountSummaryItem> byAccount;

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  public static class AccountSummaryItem {

    private java.util.UUID accountId;
    private String name;
    private String income;
    private String expense;
    private String currentBalance;
  }
}

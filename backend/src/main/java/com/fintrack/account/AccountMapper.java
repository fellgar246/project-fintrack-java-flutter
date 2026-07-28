package com.fintrack.account;

import com.fintrack.account.dto.AccountResponse;
import java.math.RoundingMode;
import org.springframework.stereotype.Component;

@Component
public class AccountMapper {

  public AccountResponse toResponse(AccountBalanceRow row) {
    return AccountResponse.builder()
        .id(row.getId())
        .name(row.getName())
        .type(AccountType.valueOf(row.getType()))
        .initialBalance(formatAmount(row.getInitialBalance()))
        .currentBalance(formatAmount(row.getCurrentBalance()))
        .archived(row.getArchived())
        .createdAt(row.getCreatedAt())
        .build();
  }

  public AccountResponse toResponse(Account account) {
    return AccountResponse.builder()
        .id(account.getId())
        .name(account.getName())
        .type(account.getType())
        .initialBalance(formatAmount(account.getInitialBalance()))
        .currentBalance(formatAmount(account.getInitialBalance()))
        .archived(account.getArchived())
        .createdAt(account.getCreatedAt())
        .build();
  }

  private String formatAmount(java.math.BigDecimal amount) {
    return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
  }
}

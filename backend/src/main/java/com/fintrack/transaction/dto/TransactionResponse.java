package com.fintrack.transaction.dto;

import com.fintrack.transaction.TransactionType;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
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
public class TransactionResponse {

  private UUID id;
  private TransactionType type;
  private String amount;
  private LocalDate date;
  private UUID accountId;
  private UUID categoryId;
  private UUID transferAccountId;
  private String note;
  private TransactionAccountSummary account;
  private TransactionCategorySummary category;
  private TransactionAccountSummary transferAccount;
  private Instant createdAt;
  private Instant updatedAt;
}

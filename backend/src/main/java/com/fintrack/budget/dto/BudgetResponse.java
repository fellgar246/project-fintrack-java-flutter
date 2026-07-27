package com.fintrack.budget.dto;

import com.fintrack.budget.BudgetStatus;
import com.fintrack.transaction.dto.TransactionCategorySummary;
import java.math.BigDecimal;
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
public class BudgetResponse {

    private UUID id;
    private TransactionCategorySummary category;
    private String yearMonth;
    private String limitAmount;
    private String spentAmount;
    private String remainingAmount;
    private BigDecimal percentUsed;
    private BudgetStatus status;
}

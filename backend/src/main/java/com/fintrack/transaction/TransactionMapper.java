package com.fintrack.transaction;

import com.fintrack.account.Account;
import com.fintrack.category.Category;
import com.fintrack.transaction.dto.TransactionAccountSummary;
import com.fintrack.transaction.dto.TransactionCategorySummary;
import com.fintrack.transaction.dto.TransactionResponse;
import java.math.BigDecimal;
import java.math.RoundingMode;
import org.springframework.stereotype.Component;

@Component
public class TransactionMapper {

    public TransactionResponse toResponse(Transaction transaction) {
        Account account = transaction.getAccount();
        Category category = transaction.getCategory();
        Account transferAccount = transaction.getTransferAccount();

        return TransactionResponse.builder()
            .id(transaction.getId())
            .type(transaction.getType())
            .amount(formatAmount(transaction.getAmount()))
            .date(transaction.getDate())
            .accountId(account.getId())
            .categoryId(category != null ? category.getId() : null)
            .transferAccountId(transferAccount != null ? transferAccount.getId() : null)
            .note(transaction.getNote())
            .account(toAccountSummary(account))
            .category(category != null ? toCategorySummary(category) : null)
            .transferAccount(transferAccount != null ? toAccountSummary(transferAccount) : null)
            .createdAt(transaction.getCreatedAt())
            .updatedAt(transaction.getUpdatedAt())
            .build();
    }

    private TransactionAccountSummary toAccountSummary(Account account) {
        return TransactionAccountSummary.builder()
            .id(account.getId())
            .name(account.getName())
            .build();
    }

    private TransactionCategorySummary toCategorySummary(Category category) {
        return TransactionCategorySummary.builder()
            .id(category.getId())
            .name(category.getName())
            .color(category.getColor())
            .icon(category.getIcon())
            .build();
    }

    private String formatAmount(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }
}

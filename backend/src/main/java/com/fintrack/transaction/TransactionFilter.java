package com.fintrack.transaction;

import com.fintrack.transaction.TransactionType;
import java.time.LocalDate;
import java.util.UUID;

public record TransactionFilter(
    UUID userId,
    LocalDate from,
    LocalDate to,
    UUID accountId,
    UUID categoryId,
    TransactionType type,
    String search
) {
}

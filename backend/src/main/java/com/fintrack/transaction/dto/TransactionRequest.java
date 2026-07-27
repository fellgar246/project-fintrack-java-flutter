package com.fintrack.transaction.dto;

import com.fintrack.transaction.TransactionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
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
public class TransactionRequest {

    @NotNull
    private TransactionType type;

    @NotBlank
    private String amount;

    @NotNull
    private LocalDate date;

    @NotNull
    private UUID accountId;

    private UUID categoryId;

    private UUID transferAccountId;

    @Size(max = 255)
    private String note;
}

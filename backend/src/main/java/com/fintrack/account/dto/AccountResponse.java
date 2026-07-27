package com.fintrack.account.dto;

import com.fintrack.account.AccountType;
import java.time.Instant;
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
public class AccountResponse {

    private UUID id;
    private String name;
    private AccountType type;
    private String initialBalance;
    private String currentBalance;
    private boolean archived;
    private Instant createdAt;
}

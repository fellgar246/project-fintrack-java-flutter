package com.fintrack.account.dto;

import com.fintrack.account.AccountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
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
public class AccountRequest {

    @NotBlank
    @Size(max = 100)
    private String name;

    @NotNull
    private AccountType type;

    @NotBlank
    @Pattern(regexp = "^-?\\d+(\\.\\d{1,2})?$", message = "Must be a decimal amount with up to 2 fractional digits")
    private String initialBalance;
}

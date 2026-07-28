package com.fintrack.budget.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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
public class BudgetUpsertRequest {

  @NotNull private UUID categoryId;

  @NotBlank
  @Pattern(regexp = "^\\d{4}-(0[1-9]|1[0-2])$")
  private String yearMonth;

  @NotBlank private String limitAmount;
}

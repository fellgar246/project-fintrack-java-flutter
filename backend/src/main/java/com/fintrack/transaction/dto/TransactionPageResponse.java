package com.fintrack.transaction.dto;

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
public class TransactionPageResponse {

  private List<TransactionResponse> content;
  private int page;
  private int size;
  private long totalElements;
  private int totalPages;
  private boolean last;
}

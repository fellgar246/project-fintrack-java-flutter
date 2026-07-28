package com.fintrack.category.dto;

import com.fintrack.category.CategoryKind;
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
public class CategoryResponse {

  private UUID id;
  private String name;
  private CategoryKind kind;
  private String color;
  private String icon;
  private boolean archived;
}

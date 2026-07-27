package com.fintrack.category.dto;

import com.fintrack.category.CategoryKind;
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
public class CategoryRequest {

    @NotBlank
    @Size(max = 60)
    private String name;

    @NotNull
    private CategoryKind kind;

    @NotBlank
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Must be a hex color in #RRGGBB format")
    private String color;

    @NotBlank
    @Size(max = 40)
    private String icon;
}

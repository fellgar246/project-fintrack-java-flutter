package com.fintrack.category.dto;

import jakarta.validation.constraints.NotBlank;
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
public class CategoryUpdateRequest {

    @NotBlank
    @Size(max = 60)
    private String name;

    @NotBlank
    @Pattern(regexp = "^#[0-9A-Fa-f]{6}$", message = "Must be a hex color in #RRGGBB format")
    private String color;

    @NotBlank
    @Size(max = 40)
    private String icon;
}

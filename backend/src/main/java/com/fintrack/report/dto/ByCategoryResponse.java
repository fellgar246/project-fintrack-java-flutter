package com.fintrack.report.dto;

import java.math.BigDecimal;
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
public class ByCategoryResponse {

    private UUID categoryId;
    private String name;
    private String color;
    private String icon;
    private String total;
    private BigDecimal percent;
}

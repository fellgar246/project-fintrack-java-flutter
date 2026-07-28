package com.fintrack.report.dto;

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
public class TrendResponse {

    private String yearMonth;
    private String income;
    private String expense;
    private String net;
}

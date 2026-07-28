package com.fintrack.report;

import com.fintrack.config.CurrentUser;
import com.fintrack.report.dto.ByCategoryResponse;
import com.fintrack.report.dto.SummaryResponse;
import com.fintrack.report.dto.TrendResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/reports")
@Tag(name = "Reports")
public class ReportController {

  private final ReportService reportService;

  public ReportController(ReportService reportService) {
    this.reportService = reportService;
  }

  @GetMapping("/summary")
  @Operation(
      description =
          "Monthly income/expense summary with per-account breakdown. Transfers excluded (RB-03).")
  public SummaryResponse summary(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestParam(required = false) String yearMonth) {
    return reportService.summary(currentUser.id(), yearMonth);
  }

  @GetMapping("/by-category")
  @Operation(description = "Category breakdown for a month and kind (INCOME or EXPENSE).")
  public List<ByCategoryResponse> byCategory(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestParam(required = false) String yearMonth,
      @RequestParam String kind) {
    return reportService.byCategory(currentUser.id(), yearMonth, kind);
  }

  @GetMapping("/trend")
  @Operation(
      description =
          "Monthly income/expense trend ending in the current month. Empty months included.")
  public List<TrendResponse> trend(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestParam(defaultValue = "6") int months) {
    return reportService.trend(currentUser.id(), months);
  }

  @GetMapping("/export")
  @Operation(description = "Export transactions as CSV with UTF-8 BOM for Excel compatibility.")
  public ResponseEntity<org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody>
      export(
          @AuthenticationPrincipal CurrentUser currentUser,
          @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
          @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
    CsvExportService.CsvExportResult result = reportService.exportCsv(currentUser.id(), from, to);

    return ResponseEntity.ok()
        .header(
            HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + result.filename() + "\"")
        .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
        .body(result.body());
  }
}

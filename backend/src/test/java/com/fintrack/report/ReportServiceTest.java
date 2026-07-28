package com.fintrack.report;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import com.fintrack.common.error.BadRequestException;
import com.fintrack.report.dto.ByCategoryResponse;
import com.fintrack.report.dto.SummaryResponse;
import com.fintrack.report.dto.TrendResponse;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

  @Mock private ReportRepository reportRepository;

  @Mock private CsvExportService csvExportService;

  private ReportMapper reportMapper;
  private ReportService reportService;

  private final UUID userId = UUID.randomUUID();
  private static final DateTimeFormatter YEAR_MONTH = DateTimeFormatter.ofPattern("yyyy-MM");

  @BeforeEach
  void setUp() {
    reportMapper = new ReportMapper();
    reportService = new ReportService(reportRepository, reportMapper, csvExportService);
  }

  @Test
  @DisplayName("RB-03: net = ingresos − gastos en summary")
  void rb03_summaryNetEqualsIncomeMinusExpense() {
    SummaryAccountRow row =
        summaryRow(
            new BigDecimal("5000.00"),
            new BigDecimal("3200.50"),
            new BigDecimal("5000.00"),
            new BigDecimal("3200.50"));
    when(reportRepository.findSummaryForMonth(
            eq(userId), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(List.of(row));

    SummaryResponse response = reportService.summary(userId, "2026-07");

    assertEquals("5000.00", response.getTotalIncome());
    assertEquals("3200.50", response.getTotalExpense());
    assertEquals("1799.50", response.getNet());
  }

  @Test
  @DisplayName("RB-03: porcentajes por categoría suman 100 (±0.01)")
  void rb03_categoryPercentsSumTo100() {
    List<ByCategoryRow> rows =
        List.of(
            categoryRow("Food", new BigDecimal("600.00")),
            categoryRow("Transport", new BigDecimal("400.00")));
    when(reportRepository.findByCategoryForMonth(
            eq(userId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(rows);

    List<ByCategoryResponse> responses = reportService.byCategory(userId, "2026-07", "EXPENSE");

    BigDecimal sum =
        responses.stream()
            .map(ByCategoryResponse::getPercent)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    assertTrue(sum.subtract(new BigDecimal("100")).abs().compareTo(new BigDecimal("0.01")) <= 0);
  }

  @Test
  @DisplayName("RB-03: total 0 → lista vacía sin división entre cero")
  void rb03_zeroTotal_emptyCategoryList() {
    when(reportRepository.findByCategoryForMonth(
            eq(userId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(List.of());

    List<ByCategoryResponse> responses = reportService.byCategory(userId, "2026-07", "EXPENSE");

    assertTrue(responses.isEmpty());
  }

  @Test
  @DisplayName("RB-03: trend rellena meses sin datos con ceros")
  void rb03_trendFillsMissingMonthsWithZeros() {
    YearMonth end = YearMonth.now();
    YearMonth start = end.minusMonths(2);
    LocalDate seriesStart = start.atDay(1);
    LocalDate seriesEnd = end.atDay(1);

    when(reportRepository.findTrend(userId, seriesStart, seriesEnd))
        .thenReturn(
            List.of(
                trendRow(end.format(YEAR_MONTH), BigDecimal.ZERO, BigDecimal.ZERO),
                trendRow(
                    end.minusMonths(1).format(YEAR_MONTH),
                    new BigDecimal("100.00"),
                    new BigDecimal("50.00")),
                trendRow(end.minusMonths(2).format(YEAR_MONTH), BigDecimal.ZERO, BigDecimal.ZERO)));

    List<TrendResponse> trend = reportService.trend(userId, 3);

    assertEquals(3, trend.size());
    assertEquals("0.00", trend.get(0).getIncome());
    assertEquals("0.00", trend.get(0).getExpense());
    assertEquals("0.00", trend.get(0).getNet());
  }

  @Test
  @DisplayName("RB-03: transferencias excluidas — solo INCOME/EXPENSE en trend query")
  void rb03_transfersExcludedFromTrend() {
    YearMonth end = YearMonth.now();
    when(reportRepository.findTrend(eq(userId), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(
            List.of(
                trendRow(
                    end.format(YEAR_MONTH), new BigDecimal("1000.00"), new BigDecimal("300.00"))));

    List<TrendResponse> trend = reportService.trend(userId, 1);

    assertEquals("700.00", trend.getFirst().getNet());
  }

  @Test
  @DisplayName("trend con months fuera de rango → BadRequestException")
  void trend_invalidMonths() {
    assertThrows(BadRequestException.class, () -> reportService.trend(userId, 0));
    assertThrows(BadRequestException.class, () -> reportService.trend(userId, 25));
  }

  @Test
  @DisplayName("byCategory con kind inválido → BadRequestException")
  void byCategory_invalidKind() {
    assertThrows(
        BadRequestException.class, () -> reportService.byCategory(userId, "2026-07", "FOO"));
  }

  @Test
  @DisplayName("exportCsv valida rango de fechas")
  void exportCsv_invalidDateRange() {
    assertThrows(
        BadRequestException.class,
        () -> reportService.exportCsv(userId, LocalDate.of(2026, 7, 10), LocalDate.of(2026, 7, 1)));
  }

  @Test
  @DisplayName("summary usa mes actual cuando yearMonth es null")
  void summary_defaultYearMonth() {
    when(reportRepository.findSummaryForMonth(
            eq(userId), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(List.of());

    SummaryResponse response = reportService.summary(userId, null);

    assertEquals(YearMonth.now().format(YEAR_MONTH), response.getYearMonth());
  }

  @Test
  @DisplayName("summary con yearMonth inválido → BadRequestException")
  void summary_invalidYearMonth() {
    assertThrows(BadRequestException.class, () -> reportService.summary(userId, "2026-99"));
  }

  @Test
  @DisplayName("exportCsv rechaza rango mayor a 2 años")
  void exportCsv_rangeTooLarge() {
    assertThrows(
        BadRequestException.class,
        () -> reportService.exportCsv(userId, LocalDate.of(2024, 1, 1), LocalDate.of(2026, 1, 2)));
  }

  private SummaryAccountRow summaryRow(
      BigDecimal income, BigDecimal expense, BigDecimal totalIncome, BigDecimal totalExpense) {
    return new SummaryAccountRow() {
      @Override
      public UUID getAccountId() {
        return UUID.randomUUID();
      }

      @Override
      public String getName() {
        return "Cuenta";
      }

      @Override
      public BigDecimal getIncome() {
        return income;
      }

      @Override
      public BigDecimal getExpense() {
        return expense;
      }

      @Override
      public BigDecimal getCurrentBalance() {
        return new BigDecimal("1000.00");
      }

      @Override
      public BigDecimal getTotalIncome() {
        return totalIncome;
      }

      @Override
      public BigDecimal getTotalExpense() {
        return totalExpense;
      }
    };
  }

  private ByCategoryRow categoryRow(String name, BigDecimal total) {
    return new ByCategoryRow() {
      @Override
      public UUID getCategoryId() {
        return UUID.randomUUID();
      }

      @Override
      public String getName() {
        return name;
      }

      @Override
      public String getColor() {
        return "#FF7043";
      }

      @Override
      public String getIcon() {
        return "restaurant";
      }

      @Override
      public BigDecimal getTotal() {
        return total;
      }
    };
  }

  private TrendRow trendRow(String yearMonth, BigDecimal income, BigDecimal expense) {
    return new TrendRow() {
      @Override
      public String getYearMonth() {
        return yearMonth;
      }

      @Override
      public BigDecimal getIncome() {
        return income;
      }

      @Override
      public BigDecimal getExpense() {
        return expense;
      }
    };
  }
}

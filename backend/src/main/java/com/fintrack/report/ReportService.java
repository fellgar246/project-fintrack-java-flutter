package com.fintrack.report;

import com.fintrack.category.CategoryKind;
import com.fintrack.common.error.BadRequestException;
import com.fintrack.report.dto.ByCategoryResponse;
import com.fintrack.report.dto.SummaryResponse;
import com.fintrack.report.dto.TrendResponse;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class ReportService {

    private static final String INVALID_YEAR_MONTH_MESSAGE = "yearMonth must match YYYY-MM";
    private static final String INVALID_KIND_MESSAGE = "kind must be INCOME or EXPENSE";
    private static final String INVALID_MONTHS_MESSAGE = "months must be between 1 and 24";
    private static final String INVALID_DATE_RANGE_MESSAGE = "from must be on or before to";
    private static final String RANGE_TOO_LARGE_MESSAGE = "Date range cannot exceed 2 years";
    private static final DateTimeFormatter YEAR_MONTH_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final ReportRepository reportRepository;
    private final ReportMapper reportMapper;
    private final CsvExportService csvExportService;

    public ReportService(
        ReportRepository reportRepository,
        ReportMapper reportMapper,
        CsvExportService csvExportService
    ) {
        this.reportRepository = reportRepository;
        this.reportMapper = reportMapper;
        this.csvExportService = csvExportService;
    }

    public SummaryResponse summary(UUID userId, String yearMonth) {
        String resolvedYearMonth = resolveYearMonth(yearMonth);
        YearMonth month = parseYearMonth(resolvedYearMonth);
        LocalDate monthStart = month.atDay(1);
        LocalDate monthEnd = month.plusMonths(1).atDay(1);

        List<SummaryAccountRow> rows = reportRepository.findSummaryForMonth(userId, monthStart, monthEnd);
        return reportMapper.toSummaryResponse(resolvedYearMonth, rows);
    }

    public List<ByCategoryResponse> byCategory(UUID userId, String yearMonth, String kind) {
        CategoryKind categoryKind = parseKind(kind);
        String resolvedYearMonth = resolveYearMonth(yearMonth);
        YearMonth month = parseYearMonth(resolvedYearMonth);
        LocalDate monthStart = month.atDay(1);
        LocalDate monthEnd = month.plusMonths(1).atDay(1);

        List<ByCategoryRow> rows = reportRepository.findByCategoryForMonth(
            userId,
            categoryKind.name(),
            monthStart,
            monthEnd
        );
        return reportMapper.toByCategoryResponses(rows);
    }

    public List<TrendResponse> trend(UUID userId, int months) {
        if (months < 1 || months > 24) {
            throw new BadRequestException(INVALID_MONTHS_MESSAGE);
        }

        YearMonth endMonth = YearMonth.now();
        YearMonth startMonth = endMonth.minusMonths(months - 1L);
        LocalDate seriesStart = startMonth.atDay(1);
        LocalDate seriesEnd = endMonth.atDay(1);

        return reportRepository.findTrend(userId, seriesStart, seriesEnd).stream()
            .map(reportMapper::toTrendResponse)
            .toList();
    }

    public CsvExportService.CsvExportResult exportCsv(UUID userId, LocalDate from, LocalDate to) {
        validateDateRange(from, to);
        return csvExportService.export(userId, from, to);
    }

    private String resolveYearMonth(String yearMonth) {
        if (yearMonth == null || yearMonth.isBlank()) {
            return YearMonth.now().format(YEAR_MONTH_FORMAT);
        }
        return yearMonth.trim();
    }

    private YearMonth parseYearMonth(String yearMonth) {
        if (!yearMonth.matches("^\\d{4}-(0[1-9]|1[0-2])$")) {
            throw new BadRequestException(INVALID_YEAR_MONTH_MESSAGE);
        }
        try {
            return YearMonth.parse(yearMonth, YEAR_MONTH_FORMAT);
        } catch (DateTimeParseException ex) {
            throw new BadRequestException(INVALID_YEAR_MONTH_MESSAGE);
        }
    }

    private CategoryKind parseKind(String kind) {
        if (kind == null || kind.isBlank()) {
            throw new BadRequestException(INVALID_KIND_MESSAGE);
        }
        try {
            return CategoryKind.valueOf(kind.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new BadRequestException(INVALID_KIND_MESSAGE);
        }
    }

    private void validateDateRange(LocalDate from, LocalDate to) {
        if (from == null || to == null) {
            throw new BadRequestException("from and to are required");
        }
        if (from.isAfter(to)) {
            throw new BadRequestException(INVALID_DATE_RANGE_MESSAGE);
        }
        long days = ChronoUnit.DAYS.between(from, to) + 1;
        if (days > 731) {
            throw new BadRequestException(RANGE_TOO_LARGE_MESSAGE);
        }
    }
}

package com.fintrack.budget;

import com.fintrack.budget.dto.BudgetResponse;
import com.fintrack.budget.dto.BudgetUpsertRequest;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.common.error.BadRequestException;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.NotFoundException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BudgetService {

  private static final String NOT_FOUND_MESSAGE = "Budget not found";
  private static final String CATEGORY_NOT_FOUND_MESSAGE = "Category not found";
  private static final String INCOME_CATEGORY_MESSAGE =
      "Budgets can only be set for expense categories";
  private static final String ARCHIVED_CATEGORY_MESSAGE =
      "Archived categories cannot have new budgets";
  private static final String INVALID_YEAR_MONTH_MESSAGE = "yearMonth must match YYYY-MM";
  private static final BigDecimal MAX_AMOUNT = new BigDecimal("999999999999.99");
  private static final DateTimeFormatter YEAR_MONTH_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM");

  private final BudgetRepository budgetRepository;
  private final CategoryRepository categoryRepository;
  private final BudgetMapper budgetMapper;

  public BudgetService(
      BudgetRepository budgetRepository,
      CategoryRepository categoryRepository,
      BudgetMapper budgetMapper) {
    this.budgetRepository = budgetRepository;
    this.categoryRepository = categoryRepository;
    this.budgetMapper = budgetMapper;
  }

  public List<BudgetResponse> list(UUID userId, String yearMonth, boolean includeUnbudgeted) {
    String resolvedYearMonth = resolveYearMonth(yearMonth);
    YearMonth month = parseYearMonth(resolvedYearMonth);
    LocalDate monthStart = month.atDay(1);
    LocalDate monthEnd = month.plusMonths(1).atDay(1);

    List<BudgetResponse> responses =
        budgetRepository
            .findAllWithSpentForMonth(userId, resolvedYearMonth, monthStart, monthEnd)
            .stream()
            .map(budgetMapper::toResponse)
            .collect(Collectors.toCollection(ArrayList::new));

    if (includeUnbudgeted) {
      Set<UUID> budgetedCategoryIds =
          responses.stream().map(r -> r.getCategory().getId()).collect(Collectors.toSet());

      categoryRepository.findAllForUser(userId, CategoryKind.EXPENSE, false).stream()
          .filter(category -> !budgetedCategoryIds.contains(category.getId()))
          .map(
              category ->
                  budgetMapper.toUnbudgetedResponse(
                      category.getId(),
                      category.getName(),
                      category.getColor(),
                      category.getIcon(),
                      resolvedYearMonth))
          .forEach(responses::add);
    }

    return responses;
  }

  @Transactional
  public BudgetResponse upsert(UUID userId, BudgetUpsertRequest request) {
    String yearMonth = request.getYearMonth().trim();
    parseYearMonth(yearMonth);
    BigDecimal limitAmount = parseAndValidateAmount(request.getLimitAmount());

    Category category =
        categoryRepository
            .findByIdAndUserId(request.getCategoryId(), userId)
            .orElseThrow(() -> new NotFoundException(CATEGORY_NOT_FOUND_MESSAGE));

    if (category.getKind() != CategoryKind.EXPENSE) {
      throw new BusinessRuleException(INCOME_CATEGORY_MESSAGE);
    }

    Budget budget =
        budgetRepository
            .findByUserIdAndCategoryIdAndYearMonth(userId, request.getCategoryId(), yearMonth)
            .orElse(null);

    if (budget == null) {
      if (Boolean.TRUE.equals(category.getArchived())) {
        throw new BusinessRuleException(ARCHIVED_CATEGORY_MESSAGE);
      }
      budget =
          Budget.builder()
              .userId(userId)
              .categoryId(request.getCategoryId())
              .yearMonth(yearMonth)
              .limitAmount(limitAmount)
              .build();
    } else {
      budget.setLimitAmount(limitAmount);
    }

    Budget saved = budgetRepository.save(budget);
    YearMonth month = parseYearMonth(yearMonth);
    LocalDate monthStart = month.atDay(1);
    LocalDate monthEnd = month.plusMonths(1).atDay(1);

    return budgetRepository
        .findOneWithSpent(userId, saved.getId(), monthStart, monthEnd)
        .map(budgetMapper::toResponse)
        .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
  }

  @Transactional
  public void delete(UUID userId, UUID budgetId) {
    Budget budget =
        budgetRepository
            .findByIdAndUserId(budgetId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
    budgetRepository.delete(budget);
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

  private BigDecimal parseAndValidateAmount(String raw) {
    if (raw == null || raw.isBlank()) {
      throw new BadRequestException("Amount must be greater than zero");
    }
    String trimmed = raw.trim();
    if (!trimmed.matches("^\\d+(\\.\\d{1,2})?$")) {
      throw new BadRequestException(
          "Amount must be a positive decimal with up to 2 fractional digits");
    }
    BigDecimal amount = new BigDecimal(trimmed);
    if (amount.compareTo(BigDecimal.ZERO) <= 0) {
      throw new BadRequestException("Amount must be greater than zero");
    }
    if (amount.compareTo(MAX_AMOUNT) > 0) {
      throw new BadRequestException("Amount exceeds the maximum allowed value");
    }
    return amount.setScale(2, RoundingMode.UNNECESSARY);
  }
}

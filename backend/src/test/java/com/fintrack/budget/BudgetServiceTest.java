package com.fintrack.budget;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fintrack.budget.dto.BudgetResponse;
import com.fintrack.budget.dto.BudgetUpsertRequest;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.common.error.BadRequestException;
import com.fintrack.common.error.BusinessRuleException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class BudgetServiceTest {

  @Mock private BudgetRepository budgetRepository;

  @Mock private CategoryRepository categoryRepository;

  private BudgetMapper budgetMapper;
  private BudgetService budgetService;

  private final UUID userId = UUID.randomUUID();
  private final UUID categoryId = UUID.randomUUID();
  private final UUID budgetId = UUID.randomUUID();

  @BeforeEach
  void setUp() {
    budgetMapper = new BudgetMapper();
    budgetService = new BudgetService(budgetRepository, categoryRepository, budgetMapper);
  }

  @Test
  @DisplayName("RB-04: categoría INCOME → BusinessRuleException")
  void rb04_incomeCategoryRejected() {
    Category income = category(CategoryKind.INCOME);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(income));

    BudgetUpsertRequest request = new BudgetUpsertRequest(categoryId, "2026-07", "5000.00");

    assertThrows(BusinessRuleException.class, () -> budgetService.upsert(userId, request));
  }

  @Test
  @DisplayName("RB-04: percentUsed 3250.75/5000 → 65.02 (HALF_UP)")
  void rb04_percentUsedRounding() {
    BudgetResponse response =
        budgetMapper.toResponse(
            budgetId,
            categoryId,
            "Comida",
            "#FF7043",
            "restaurant",
            "2026-07",
            new BigDecimal("5000.00"),
            new BigDecimal("3250.75"));

    assertEquals(new BigDecimal("65.02"), response.getPercentUsed());
  }

  @Test
  @DisplayName("RB-04: límite cubierto exacto → 100.00 y EXCEEDED")
  void rb04_exactLimit_exceededStatus() {
    BudgetResponse response =
        budgetMapper.toResponse(
            budgetId,
            categoryId,
            "Comida",
            "#FF7043",
            "restaurant",
            "2026-07",
            new BigDecimal("1000.00"),
            new BigDecimal("1000.00"));

    assertEquals(new BigDecimal("100.00"), response.getPercentUsed());
    assertEquals(BudgetStatus.EXCEEDED, response.getStatus());
  }

  @Test
  @DisplayName("RB-04: gasto > límite → remainingAmount negativo")
  void rb04_overspend_negativeRemaining() {
    BudgetResponse response =
        budgetMapper.toResponse(
            budgetId,
            categoryId,
            "Comida",
            "#FF7043",
            "restaurant",
            "2026-07",
            new BigDecimal("1000.00"),
            new BigDecimal("1200.00"));

    assertEquals("-200.00", response.getRemainingAmount());
    assertEquals(BudgetStatus.EXCEEDED, response.getStatus());
  }

  @Test
  @DisplayName("RB-04: límite 0 o negativo → excepción de validación")
  void rb04_zeroOrNegativeLimitRejected() {
    Category expense = category(CategoryKind.EXPENSE);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expense));

    BudgetUpsertRequest zero = new BudgetUpsertRequest(categoryId, "2026-07", "0");
    assertThrows(BadRequestException.class, () -> budgetService.upsert(userId, zero));

    BudgetUpsertRequest negative = new BudgetUpsertRequest(categoryId, "2026-07", "-10");
    assertThrows(BadRequestException.class, () -> budgetService.upsert(userId, negative));
  }

  @Test
  @DisplayName("RB-04: upsert existente → actualiza límite")
  void rb04_upsertExisting_updatesLimit() {
    Category expense = category(CategoryKind.EXPENSE);
    Budget existing =
        Budget.builder()
            .id(budgetId)
            .userId(userId)
            .categoryId(categoryId)
            .yearMonth("2026-07")
            .limitAmount(new BigDecimal("1000.00"))
            .build();

    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expense));
    when(budgetRepository.findByUserIdAndCategoryIdAndYearMonth(userId, categoryId, "2026-07"))
        .thenReturn(Optional.of(existing));
    when(budgetRepository.save(existing)).thenReturn(existing);
    when(budgetRepository.findOneWithSpent(
            eq(userId), eq(budgetId), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(Optional.of(spentRow(new BigDecimal("1000.00"), new BigDecimal("200.00"))));

    budgetService.upsert(userId, new BudgetUpsertRequest(categoryId, "2026-07", "2000.00"));

    assertEquals(new BigDecimal("2000.00"), existing.getLimitAmount());
  }

  @Test
  @DisplayName("RB-04: upsert nuevo → crea presupuesto")
  void rb04_upsertNew_createsBudget() {
    Category expense = category(CategoryKind.EXPENSE);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expense));
    when(budgetRepository.findByUserIdAndCategoryIdAndYearMonth(userId, categoryId, "2026-07"))
        .thenReturn(Optional.empty());

    Budget saved =
        Budget.builder()
            .id(budgetId)
            .userId(userId)
            .categoryId(categoryId)
            .yearMonth("2026-07")
            .limitAmount(new BigDecimal("5000.00"))
            .build();

    when(budgetRepository.save(any(Budget.class))).thenReturn(saved);
    when(budgetRepository.findOneWithSpent(
            eq(userId), eq(budgetId), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(Optional.of(spentRow(new BigDecimal("5000.00"), BigDecimal.ZERO)));

    budgetService.upsert(userId, new BudgetUpsertRequest(categoryId, "2026-07", "5000.00"));

    ArgumentCaptor<Budget> captor = ArgumentCaptor.forClass(Budget.class);
    verify(budgetRepository).save(captor.capture());
    assertEquals(new BigDecimal("5000.00"), captor.getValue().getLimitAmount());
  }

  @Test
  @DisplayName("DELETE elimina presupuesto existente")
  void delete_removesBudget() {
    Budget budget =
        Budget.builder()
            .id(budgetId)
            .userId(userId)
            .categoryId(categoryId)
            .yearMonth("2026-07")
            .limitAmount(new BigDecimal("1000.00"))
            .build();
    when(budgetRepository.findByIdAndUserId(budgetId, userId)).thenReturn(Optional.of(budget));

    budgetService.delete(userId, budgetId);

    verify(budgetRepository).delete(budget);
  }

  @Test
  @DisplayName("LIST con yearMonth inválido → BadRequestException")
  void list_invalidYearMonth() {
    assertThrows(BadRequestException.class, () -> budgetService.list(userId, "2026-13", false));
  }

  @Test
  @DisplayName("UPSERT categoría archivada en presupuesto nuevo → BusinessRuleException")
  void upsert_archivedCategoryOnNewBudget() {
    Category archived = category(CategoryKind.EXPENSE);
    archived.setArchived(true);
    when(categoryRepository.findByIdAndUserId(categoryId, userId))
        .thenReturn(Optional.of(archived));
    when(budgetRepository.findByUserIdAndCategoryIdAndYearMonth(userId, categoryId, "2026-07"))
        .thenReturn(Optional.empty());

    assertThrows(
        BusinessRuleException.class,
        () ->
            budgetService.upsert(userId, new BudgetUpsertRequest(categoryId, "2026-07", "100.00")));
  }

  @Test
  @DisplayName("LIST incluye categorías sin presupuesto cuando se pide")
  void list_includeUnbudgeted() {
    when(budgetRepository.findAllWithSpentForMonth(
            eq(userId), eq("2026-07"), any(LocalDate.class), any(LocalDate.class)))
        .thenReturn(List.of());
    when(categoryRepository.findAllForUser(userId, CategoryKind.EXPENSE, false))
        .thenReturn(List.of(category(CategoryKind.EXPENSE)));

    var responses = budgetService.list(userId, "2026-07", true);

    assertEquals(1, responses.size());
    assertEquals(null, responses.getFirst().getLimitAmount());
  }

  @Test
  @DisplayName("UPSERT rechaza monto con más de 2 decimales")
  void upsert_invalidAmountFormat() {
    Category expense = category(CategoryKind.EXPENSE);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expense));

    assertThrows(
        BadRequestException.class,
        () ->
            budgetService.upsert(userId, new BudgetUpsertRequest(categoryId, "2026-07", "10.999")));
  }

  private Category category(CategoryKind kind) {
    return Category.builder()
        .id(categoryId)
        .userId(userId)
        .name("Comida")
        .kind(kind)
        .color("#FF7043")
        .icon("restaurant")
        .archived(false)
        .build();
  }

  private BudgetWithSpentRow spentRow(BigDecimal limit, BigDecimal spent) {
    return new BudgetWithSpentRow() {
      @Override
      public UUID getId() {
        return budgetId;
      }

      @Override
      public UUID getCategoryId() {
        return categoryId;
      }

      @Override
      public String getCategoryName() {
        return "Comida";
      }

      @Override
      public String getCategoryColor() {
        return "#FF7043";
      }

      @Override
      public String getCategoryIcon() {
        return "restaurant";
      }

      @Override
      public String getYearMonth() {
        return "2026-07";
      }

      @Override
      public BigDecimal getLimitAmount() {
        return limit;
      }

      @Override
      public BigDecimal getSpentAmount() {
        return spent;
      }
    };
  }
}

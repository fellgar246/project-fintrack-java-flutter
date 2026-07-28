package com.fintrack.transaction;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fintrack.account.Account;
import com.fintrack.account.AccountRepository;
import com.fintrack.account.AccountType;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.common.error.BadRequestException;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.NotFoundException;
import com.fintrack.transaction.dto.TransactionRequest;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionServiceTest {

  @Mock private TransactionRepository transactionRepository;

  @Mock private AccountRepository accountRepository;

  @Mock private CategoryRepository categoryRepository;

  private TransactionMapper transactionMapper;
  private TransactionService transactionService;

  private final UUID userId = UUID.randomUUID();
  private final UUID accountId = UUID.randomUUID();
  private final UUID destAccountId = UUID.randomUUID();
  private final UUID categoryId = UUID.randomUUID();
  private final UUID txId = UUID.randomUUID();

  @BeforeEach
  void setUp() {
    transactionMapper = new TransactionMapper();
    transactionService =
        new TransactionService(
            transactionRepository, accountRepository, categoryRepository, transactionMapper);
  }

  @Test
  @DisplayName("F3.1: monto ≤ 0 → BadRequestException")
  void f31_amountZeroRejected() {
    stubActiveAccount(accountId, false);
    stubExpenseCategory();

    TransactionRequest request = expenseRequest("0", categoryId);

    assertThrows(BadRequestException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: 3 decimales → BadRequestException")
  void f31_threeDecimalsRejected() {
    stubActiveAccount(accountId, false);
    stubExpenseCategory();

    TransactionRequest request = expenseRequest("12.345", categoryId);

    assertThrows(BadRequestException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: TRANSFER con categoría → BusinessRuleException")
  void f31_transferWithCategoryRejected() {
    stubActiveAccount(accountId, false);
    stubActiveAccount(destAccountId, false);

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.TRANSFER)
            .amount("100.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(categoryId)
            .transferAccountId(destAccountId)
            .build();

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: TRANSFER misma cuenta → BusinessRuleException")
  void f31_transferSameAccountRejected() {
    stubActiveAccount(accountId, false);

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.TRANSFER)
            .amount("100.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .transferAccountId(accountId)
            .build();

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: EXPENSE con categoría INCOME → BusinessRuleException")
  void f31_expenseWithIncomeCategoryRejected() {
    stubActiveAccount(accountId, false);
    Category income = category(CategoryKind.INCOME);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(income));

    TransactionRequest request = expenseRequest("50.00", categoryId);

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: cuenta archivada → BusinessRuleException")
  void f31_archivedAccountRejected() {
    stubActiveAccount(accountId, true);

    TransactionRequest request = expenseRequest("50.00", categoryId);

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: INCOME/EXPENSE sin categoría → BusinessRuleException")
  void f31_missingCategoryRejected() {
    stubActiveAccount(accountId, false);

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("50.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .build();

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: EXPENSE con transferAccountId → BusinessRuleException")
  void f31_expenseWithTransferAccountRejected() {
    stubActiveAccount(accountId, false);
    stubExpenseCategory();

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("50.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(categoryId)
            .transferAccountId(destAccountId)
            .build();

    assertThrows(BusinessRuleException.class, () -> transactionService.create(userId, request));
  }

  @Test
  @DisplayName("F3.1: cambio de tipo en PUT revalida reglas")
  void f31_updateTypeChangeRevalidates() {
    Account account = accountEntity(accountId, false);
    Category expense = category(CategoryKind.EXPENSE);
    Transaction existing =
        Transaction.builder()
            .id(txId)
            .userId(userId)
            .type(TransactionType.EXPENSE)
            .amount(new BigDecimal("50.00"))
            .date(LocalDate.now())
            .account(account)
            .category(expense)
            .createdAt(Instant.now())
            .updatedAt(Instant.now())
            .build();

    when(transactionRepository.findByIdAndUserId(txId, userId)).thenReturn(Optional.of(existing));
    stubActiveAccount(accountId, false);
    when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expense));

    TransactionRequest updateToIncomeWithExpenseCategory =
        TransactionRequest.builder()
            .type(TransactionType.INCOME)
            .amount("50.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(categoryId)
            .build();

    assertThrows(
        BusinessRuleException.class,
        () -> transactionService.update(userId, txId, updateToIncomeWithExpenseCategory));
  }

  @Test
  @DisplayName("CREATE válido persiste transacción")
  void createValidExpense_saves() {
    Account account = accountEntity(accountId, false);
    Category category = category(CategoryKind.EXPENSE);
    when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
    when(categoryRepository.findByIdAndUserId(categoryId, userId))
        .thenReturn(Optional.of(category));

    Transaction saved =
        Transaction.builder()
            .id(txId)
            .userId(userId)
            .type(TransactionType.EXPENSE)
            .amount(new BigDecimal("50.00"))
            .date(LocalDate.now())
            .account(account)
            .category(category)
            .createdAt(Instant.now())
            .updatedAt(Instant.now())
            .build();

    when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);
    when(transactionRepository.findByIdAndUserId(txId, userId)).thenReturn(Optional.of(saved));

    transactionService.create(userId, expenseRequest("50.00", categoryId));

    verify(transactionRepository).save(any(Transaction.class));
  }

  @Test
  @DisplayName("GET inexistente → NotFoundException")
  void getById_notFound() {
    when(transactionRepository.findByIdAndUserId(txId, userId)).thenReturn(Optional.empty());

    assertThrows(NotFoundException.class, () -> transactionService.getById(userId, txId));
  }

  private TransactionRequest expenseRequest(String amount, UUID catId) {
    return TransactionRequest.builder()
        .type(TransactionType.EXPENSE)
        .amount(amount)
        .date(LocalDate.now())
        .accountId(accountId)
        .categoryId(catId)
        .build();
  }

  private void stubActiveAccount(UUID id, boolean archived) {
    when(accountRepository.findByIdAndUserId(id, userId))
        .thenReturn(Optional.of(accountEntity(id, archived)));
  }

  private void stubExpenseCategory() {
    when(categoryRepository.findByIdAndUserId(categoryId, userId))
        .thenReturn(Optional.of(category(CategoryKind.EXPENSE)));
  }

  private Account accountEntity(UUID id, boolean archived) {
    return Account.builder()
        .id(id)
        .userId(userId)
        .name("Cuenta")
        .type(AccountType.CASH)
        .initialBalance(new BigDecimal("100.00"))
        .archived(archived)
        .createdAt(Instant.now())
        .build();
  }

  private Category category(CategoryKind kind) {
    return Category.builder()
        .id(categoryId)
        .userId(userId)
        .name("Cat")
        .kind(kind)
        .color("#FF7043")
        .icon("restaurant")
        .archived(false)
        .build();
  }
}

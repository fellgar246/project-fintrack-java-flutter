package com.fintrack.transaction;

import com.fintrack.account.Account;
import com.fintrack.account.AccountRepository;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.common.error.BadRequestException;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.NotFoundException;
import com.fintrack.transaction.dto.TransactionPageResponse;
import com.fintrack.transaction.dto.TransactionRequest;
import com.fintrack.transaction.dto.TransactionResponse;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TransactionService {

  private static final String NOT_FOUND_MESSAGE = "Transaction not found";
  private static final String ACCOUNT_NOT_FOUND_MESSAGE = "Account not found";
  private static final String CATEGORY_NOT_FOUND_MESSAGE = "Category not found";
  private static final String ARCHIVED_ACCOUNT_MESSAGE = "Account is archived";
  private static final String ARCHIVED_CATEGORY_MESSAGE = "Category is archived";
  private static final String SAME_TRANSFER_ACCOUNT_MESSAGE = "Cannot transfer to the same account";
  private static final String TRANSFER_CATEGORY_MESSAGE = "Transfers must not have a category";
  private static final String TRANSFER_ACCOUNT_REQUIRED_MESSAGE =
      "Transfer destination account is required";
  private static final String TRANSFER_ACCOUNT_FORBIDDEN_MESSAGE =
      "Only transfers may specify a destination account";
  private static final String CATEGORY_REQUIRED_MESSAGE =
      "Category is required for income and expense transactions";
  private static final String CATEGORY_KIND_MISMATCH_MESSAGE =
      "Category kind does not match transaction type";

  private static final BigDecimal MAX_AMOUNT = new BigDecimal("99999999999.99");
  private static final int MAX_PAGE_SIZE = 100;
  private static final int DEFAULT_PAGE_SIZE = 20;
  private static final Set<String> ALLOWED_SORT_PROPERTIES = Set.of("date", "amount", "createdAt");
  private static final Map<String, String> SORT_PROPERTY_MAP =
      Map.of(
          "date", "date",
          "amount", "amount",
          "createdAt", "createdAt");

  private final TransactionRepository transactionRepository;
  private final AccountRepository accountRepository;
  private final CategoryRepository categoryRepository;
  private final TransactionMapper transactionMapper;

  public TransactionService(
      TransactionRepository transactionRepository,
      AccountRepository accountRepository,
      CategoryRepository categoryRepository,
      TransactionMapper transactionMapper) {
    this.transactionRepository = transactionRepository;
    this.accountRepository = accountRepository;
    this.categoryRepository = categoryRepository;
    this.transactionMapper = transactionMapper;
  }

  public TransactionPageResponse list(UUID userId, TransactionListParams params) {
    validateDateRange(params.from(), params.to());

    Specification<Transaction> spec =
        TransactionSpecifications.fromFilter(
            new TransactionFilter(
                userId,
                params.from(),
                params.to(),
                params.accountId(),
                params.categoryId(),
                params.type(),
                params.search()));

    Pageable pageable = buildPageable(params.page(), params.size(), params.sort());
    Page<Transaction> page = transactionRepository.findAll(spec, pageable);

    return TransactionPageResponse.builder()
        .content(page.getContent().stream().map(transactionMapper::toResponse).toList())
        .page(page.getNumber())
        .size(page.getSize())
        .totalElements(page.getTotalElements())
        .totalPages(page.getTotalPages())
        .last(page.isLast())
        .build();
  }

  public TransactionResponse getById(UUID userId, UUID transactionId) {
    Transaction transaction =
        transactionRepository
            .findByIdAndUserId(transactionId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
    return transactionMapper.toResponse(transaction);
  }

  @Transactional
  public TransactionResponse create(UUID userId, TransactionRequest request) {
    ValidatedTransactionInput input = validateAndResolve(userId, request);
    Instant now = Instant.now();

    Transaction transaction =
        Transaction.builder()
            .userId(userId)
            .type(request.getType())
            .amount(input.amount())
            .date(request.getDate())
            .account(input.account())
            .category(input.category())
            .transferAccount(input.transferAccount())
            .note(normalizeNote(request.getNote()))
            .createdAt(now)
            .updatedAt(now)
            .build();

    Transaction saved = transactionRepository.save(transaction);
    return transactionRepository
        .findByIdAndUserId(saved.getId(), userId)
        .map(transactionMapper::toResponse)
        .orElseGet(() -> transactionMapper.toResponse(saved));
  }

  @Transactional
  public TransactionResponse update(UUID userId, UUID transactionId, TransactionRequest request) {
    Transaction transaction =
        transactionRepository
            .findByIdAndUserId(transactionId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));

    ValidatedTransactionInput input = validateAndResolve(userId, request);

    transaction.setType(request.getType());
    transaction.setAmount(input.amount());
    transaction.setDate(request.getDate());
    transaction.setAccount(input.account());
    transaction.setCategory(input.category());
    transaction.setTransferAccount(input.transferAccount());
    transaction.setNote(normalizeNote(request.getNote()));
    transaction.setUpdatedAt(Instant.now());

    transactionRepository.save(transaction);
    return transactionRepository
        .findByIdAndUserId(transactionId, userId)
        .map(transactionMapper::toResponse)
        .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
  }

  @Transactional
  public void delete(UUID userId, UUID transactionId) {
    Transaction transaction =
        transactionRepository
            .findByIdAndUserId(transactionId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
    transactionRepository.delete(transaction);
  }

  private ValidatedTransactionInput validateAndResolve(UUID userId, TransactionRequest request) {
    BigDecimal amount = parseAndValidateAmount(request.getAmount());
    validateDate(request.getDate());

    Account account = resolveActiveAccount(userId, request.getAccountId());

    if (request.getType() == TransactionType.TRANSFER) {
      return validateTransfer(userId, request, amount, account);
    }

    return validateIncomeOrExpense(userId, request, amount, account);
  }

  private ValidatedTransactionInput validateTransfer(
      UUID userId, TransactionRequest request, BigDecimal amount, Account account) {
    if (request.getCategoryId() != null) {
      throw new BusinessRuleException(TRANSFER_CATEGORY_MESSAGE);
    }
    if (request.getTransferAccountId() == null) {
      throw new BusinessRuleException(TRANSFER_ACCOUNT_REQUIRED_MESSAGE);
    }
    if (request.getTransferAccountId().equals(request.getAccountId())) {
      throw new BusinessRuleException(SAME_TRANSFER_ACCOUNT_MESSAGE);
    }

    Account transferAccount = resolveActiveAccount(userId, request.getTransferAccountId());
    return new ValidatedTransactionInput(amount, account, null, transferAccount);
  }

  private ValidatedTransactionInput validateIncomeOrExpense(
      UUID userId, TransactionRequest request, BigDecimal amount, Account account) {
    if (request.getTransferAccountId() != null) {
      throw new BusinessRuleException(TRANSFER_ACCOUNT_FORBIDDEN_MESSAGE);
    }
    if (request.getCategoryId() == null) {
      throw new BusinessRuleException(CATEGORY_REQUIRED_MESSAGE);
    }

    Category category =
        categoryRepository
            .findByIdAndUserId(request.getCategoryId(), userId)
            .orElseThrow(() -> new NotFoundException(CATEGORY_NOT_FOUND_MESSAGE));

    if (Boolean.TRUE.equals(category.getArchived())) {
      throw new BusinessRuleException(ARCHIVED_CATEGORY_MESSAGE);
    }

    CategoryKind expectedKind =
        request.getType() == TransactionType.INCOME ? CategoryKind.INCOME : CategoryKind.EXPENSE;

    if (category.getKind() != expectedKind) {
      throw new BusinessRuleException(CATEGORY_KIND_MISMATCH_MESSAGE);
    }

    return new ValidatedTransactionInput(amount, account, category, null);
  }

  private Account resolveActiveAccount(UUID userId, UUID accountId) {
    Account account =
        accountRepository
            .findByIdAndUserId(accountId, userId)
            .orElseThrow(() -> new NotFoundException(ACCOUNT_NOT_FOUND_MESSAGE));

    if (Boolean.TRUE.equals(account.getArchived())) {
      throw new BusinessRuleException(ARCHIVED_ACCOUNT_MESSAGE);
    }

    return account;
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

    return amount.setScale(2, java.math.RoundingMode.UNNECESSARY);
  }

  private void validateDate(LocalDate date) {
    if (date == null) {
      throw new BadRequestException("Date is required");
    }

    LocalDate maxDate = LocalDate.now().plusYears(1);
    if (date.isAfter(maxDate)) {
      throw new BadRequestException("Date cannot be more than one year in the future");
    }
  }

  private void validateDateRange(LocalDate from, LocalDate to) {
    if (from != null && to != null && from.isAfter(to)) {
      throw new BadRequestException("'from' must not be after 'to'");
    }
  }

  private Pageable buildPageable(int page, int size, String sortParam) {
    int safePage = Math.max(page, 0);
    int safeSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
    Sort sort = parseSort(sortParam).and(Sort.by(Sort.Direction.ASC, "id"));
    return PageRequest.of(safePage, safeSize, sort);
  }

  private Sort parseSort(String sortParam) {
    String raw = sortParam == null || sortParam.isBlank() ? "date,desc" : sortParam.trim();
    String[] parts = raw.split(",", 2);
    if (parts.length != 2) {
      throw new BadRequestException("Invalid sort parameter");
    }

    String property = parts[0].trim();
    String directionRaw = parts[1].trim().toLowerCase();

    if (!ALLOWED_SORT_PROPERTIES.contains(property)) {
      throw new BadRequestException("Invalid sort property: " + property);
    }

    Sort.Direction direction =
        switch (directionRaw) {
          case "asc" -> Sort.Direction.ASC;
          case "desc" -> Sort.Direction.DESC;
          default -> throw new BadRequestException("Invalid sort direction: " + directionRaw);
        };

    return Sort.by(direction, SORT_PROPERTY_MAP.get(property));
  }

  private String normalizeNote(String note) {
    if (note == null) {
      return null;
    }
    String trimmed = note.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private record ValidatedTransactionInput(
      BigDecimal amount, Account account, Category category, Account transferAccount) {}

  public record TransactionListParams(
      int page,
      int size,
      String sort,
      LocalDate from,
      LocalDate to,
      UUID accountId,
      UUID categoryId,
      TransactionType type,
      String search) {}
}

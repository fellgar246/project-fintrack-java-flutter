package com.fintrack.dev;

import com.fintrack.account.Account;
import com.fintrack.account.AccountRepository;
import com.fintrack.account.AccountType;
import com.fintrack.budget.Budget;
import com.fintrack.budget.BudgetRepository;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.transaction.Transaction;
import com.fintrack.transaction.TransactionRepository;
import com.fintrack.transaction.TransactionType;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Profile("dev")
public class DevSeedService {

    private static final DateTimeFormatter YEAR_MONTH_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;

    public DevSeedService(
        AccountRepository accountRepository,
        CategoryRepository categoryRepository,
        TransactionRepository transactionRepository,
        BudgetRepository budgetRepository
    ) {
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.budgetRepository = budgetRepository;
    }

    @Transactional
    public int seedSampleData(UUID userId) {
        List<Account> accounts = ensureAccounts(userId);
        List<Category> expenseCategories = categoryRepository.findAllForUser(userId, CategoryKind.EXPENSE, false);
        List<Category> incomeCategories = categoryRepository.findAllForUser(userId, CategoryKind.INCOME, false);

        if (expenseCategories.isEmpty() || incomeCategories.isEmpty()) {
            throw new IllegalStateException("User must have seeded categories before running dev seed");
        }

        ensureBudgets(userId, expenseCategories);

        Random random = new Random(userId.hashCode());
        int created = 0;
        YearMonth current = YearMonth.now();

        for (int monthOffset = 5; monthOffset >= 0; monthOffset--) {
            YearMonth month = current.minusMonths(monthOffset);
            LocalDate monthStart = month.atDay(1);
            int daysInMonth = month.lengthOfMonth();

            int incomeCount = 1 + random.nextInt(2);
            for (int i = 0; i < incomeCount; i++) {
                transactionRepository.save(buildTransaction(
                    userId,
                    accounts.get(random.nextInt(accounts.size())),
                    incomeCategories.get(random.nextInt(incomeCategories.size())),
                    null,
                    TransactionType.INCOME,
                    randomAmount(random, 8000, 22000),
                    monthStart.plusDays(random.nextInt(daysInMonth))
                ));
                created++;
            }

            int expenseCount = 8 + random.nextInt(12);
            for (int i = 0; i < expenseCount; i++) {
                transactionRepository.save(buildTransaction(
                    userId,
                    accounts.get(random.nextInt(accounts.size())),
                    expenseCategories.get(random.nextInt(expenseCategories.size())),
                    null,
                    TransactionType.EXPENSE,
                    randomAmount(random, 50, 2500),
                    monthStart.plusDays(random.nextInt(daysInMonth))
                ));
                created++;
            }

            if (accounts.size() >= 2 && random.nextBoolean()) {
                Account from = accounts.get(0);
                Account to = accounts.get(1);
                transactionRepository.save(buildTransaction(
                    userId,
                    from,
                    null,
                    to,
                    TransactionType.TRANSFER,
                    randomAmount(random, 500, 3000),
                    monthStart.plusDays(random.nextInt(daysInMonth))
                ));
                created++;
            }
        }

        return created;
    }

    private List<Account> ensureAccounts(UUID userId) {
        List<Account> existing = accountRepository.findByUserIdAndArchivedFalse(userId);

        if (existing.size() >= 2) {
            return existing;
        }

        Instant now = Instant.now();
        if (existing.isEmpty()) {
            accountRepository.save(Account.builder()
                .userId(userId)
                .name("Efectivo")
                .type(AccountType.CASH)
                .initialBalance(new BigDecimal("5000.00"))
                .archived(false)
                .createdAt(now)
                .build());
            accountRepository.save(Account.builder()
                .userId(userId)
                .name("Débito")
                .type(AccountType.DEBIT)
                .initialBalance(new BigDecimal("15000.00"))
                .archived(false)
                .createdAt(now)
                .build());
        } else if (existing.size() == 1) {
            accountRepository.save(Account.builder()
                .userId(userId)
                .name("Ahorro")
                .type(AccountType.SAVINGS)
                .initialBalance(new BigDecimal("10000.00"))
                .archived(false)
                .createdAt(now)
                .build());
        }

        return accountRepository.findByUserIdAndArchivedFalse(userId);
    }

    private void ensureBudgets(UUID userId, List<Category> expenseCategories) {
        String yearMonth = YearMonth.now().format(YEAR_MONTH_FORMAT);
        int index = 0;
        for (Category category : expenseCategories) {
            if (index >= 5) {
                break;
            }
            if (budgetRepository.findByUserIdAndCategoryIdAndYearMonth(userId, category.getId(), yearMonth).isPresent()) {
                index++;
                continue;
            }
            budgetRepository.save(Budget.builder()
                .userId(userId)
                .categoryId(category.getId())
                .yearMonth(yearMonth)
                .limitAmount(new BigDecimal("3000.00").add(new BigDecimal(index * 500L)))
                .build());
            index++;
        }
    }

    private Transaction buildTransaction(
        UUID userId,
        Account account,
        Category category,
        Account transferAccount,
        TransactionType type,
        BigDecimal amount,
        LocalDate date
    ) {
        Instant now = Instant.now();
        return Transaction.builder()
            .userId(userId)
            .account(account)
            .category(category)
            .transferAccount(transferAccount)
            .type(type)
            .amount(amount)
            .date(date)
            .note(type == TransactionType.TRANSFER ? "Transferencia de prueba" : "Movimiento de prueba")
            .createdAt(now)
            .updatedAt(now)
            .build();
    }

    private BigDecimal randomAmount(Random random, int min, int max) {
        int value = min + random.nextInt(max - min + 1);
        return new BigDecimal(value).setScale(2, RoundingMode.UNNECESSARY);
    }
}

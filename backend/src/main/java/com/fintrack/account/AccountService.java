package com.fintrack.account;

import com.fintrack.account.dto.AccountRequest;
import com.fintrack.account.dto.AccountResponse;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.ConflictException;
import com.fintrack.common.error.NotFoundException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountService {

    private static final String NOT_FOUND_MESSAGE = "Account not found";
    private static final String DUPLICATE_NAME_MESSAGE = "An account with that name already exists";
    private static final String ARCHIVED_EDIT_MESSAGE = "Archived accounts cannot be edited";

    private final AccountRepository accountRepository;
    private final AccountMapper accountMapper;

    public AccountService(AccountRepository accountRepository, AccountMapper accountMapper) {
        this.accountRepository = accountRepository;
        this.accountMapper = accountMapper;
    }

    public List<AccountResponse> list(UUID userId, boolean includeArchived) {
        return accountRepository.findAllWithBalance(userId, includeArchived).stream()
            .map(accountMapper::toResponse)
            .toList();
    }

    public AccountResponse getById(UUID userId, UUID accountId) {
        AccountBalanceRow row = accountRepository.findOneWithBalance(userId, accountId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
        return accountMapper.toResponse(row);
    }

    @Transactional
    public AccountResponse create(UUID userId, AccountRequest request) {
        String name = request.getName().trim();
        assertUniqueName(userId, name, null);

        Account account = Account.builder()
            .userId(userId)
            .name(name)
            .type(request.getType())
            .initialBalance(parseAmount(request.getInitialBalance()))
            .archived(false)
            .createdAt(Instant.now())
            .build();

        Account saved = accountRepository.save(account);
        return accountRepository.findOneWithBalance(userId, saved.getId())
            .map(accountMapper::toResponse)
            .orElseGet(() -> accountMapper.toResponse(saved));
    }

    @Transactional
    public AccountResponse update(UUID userId, UUID accountId, AccountRequest request) {
        Account account = accountRepository.findByIdAndUserId(accountId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));

        if (Boolean.TRUE.equals(account.getArchived())) {
            throw new BusinessRuleException(ARCHIVED_EDIT_MESSAGE);
        }

        String name = request.getName().trim();
        assertUniqueName(userId, name, accountId);

        account.setName(name);
        account.setType(request.getType());
        account.setInitialBalance(parseAmount(request.getInitialBalance()));
        accountRepository.save(account);

        return accountRepository.findOneWithBalance(userId, accountId)
            .map(accountMapper::toResponse)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
    }

    /**
     * RB-02: archives when the account has transactions (as source or destination);
     * physically deletes otherwise.
     */
    @Transactional
    public void delete(UUID userId, UUID accountId) {
        Account account = accountRepository.findByIdAndUserId(accountId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));

        if (accountRepository.hasTransactions(userId, accountId)) {
            account.setArchived(true);
            accountRepository.save(account);
        } else {
            accountRepository.delete(account);
        }
    }

    private void assertUniqueName(UUID userId, String name, UUID excludeId) {
        boolean duplicate = excludeId == null
            ? accountRepository.existsByUserIdAndNameIgnoreCase(userId, name)
            : accountRepository.existsByUserIdAndNameIgnoreCaseAndIdNot(userId, name, excludeId);

        if (duplicate) {
            throw new ConflictException(DUPLICATE_NAME_MESSAGE);
        }
    }

    private BigDecimal parseAmount(String raw) {
        return new BigDecimal(raw.trim());
    }
}

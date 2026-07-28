package com.fintrack.account;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fintrack.account.dto.AccountRequest;
import com.fintrack.account.dto.AccountResponse;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.NotFoundException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
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
class AccountServiceTest {

  @Mock private AccountRepository accountRepository;

  private AccountMapper accountMapper;
  private AccountService accountService;

  private final UUID userId = UUID.randomUUID();
  private final UUID accountId = UUID.randomUUID();

  @BeforeEach
  void setUp() {
    accountMapper = new AccountMapper();
    accountService = new AccountService(accountRepository, accountMapper);
  }

  @Test
  @DisplayName("RB-01: saldo devuelto por el repositorio se expone en la respuesta")
  void rb01_balanceFromRepositoryIsReturned() {
    AccountBalanceRow row = balanceRow("1000.00", "749.50");
    when(accountRepository.findOneWithBalance(userId, accountId)).thenReturn(Optional.of(row));

    AccountResponse response = accountService.getById(userId, accountId);

    assertEquals("749.50", response.getCurrentBalance());
    assertEquals("1000.00", response.getInitialBalance());
  }

  @Test
  @DisplayName("RB-01: cuenta sin movimientos → saldo = inicial")
  void rb01_noMovements_balanceEqualsInitial() {
    AccountBalanceRow row = balanceRow("500.00", "500.00");
    when(accountRepository.findOneWithBalance(userId, accountId)).thenReturn(Optional.of(row));

    AccountResponse response = accountService.getById(userId, accountId);

    assertEquals("500.00", response.getCurrentBalance());
  }

  @Test
  @DisplayName("RB-01: saldo negativo permitido")
  void rb01_negativeBalanceAllowed() {
    AccountBalanceRow row = balanceRow("100.00", "-250.75");
    when(accountRepository.findOneWithBalance(userId, accountId)).thenReturn(Optional.of(row));

    AccountResponse response = accountService.getById(userId, accountId);

    assertEquals("-250.75", response.getCurrentBalance());
  }

  @Test
  @DisplayName("RB-02: DELETE con transacciones → archiva")
  void rb02_deleteWithTransactions_archives() {
    Account account = accountEntity(false);
    when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
    when(accountRepository.hasTransactions(userId, accountId)).thenReturn(true);

    accountService.delete(userId, accountId);

    verify(accountRepository).save(account);
    assertEquals(true, account.getArchived());
    verify(accountRepository, never()).delete(any());
  }

  @Test
  @DisplayName("RB-02: DELETE sin transacciones → borra físicamente")
  void rb02_deleteWithoutTransactions_removes() {
    Account account = accountEntity(false);
    when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(account));
    when(accountRepository.hasTransactions(userId, accountId)).thenReturn(false);

    accountService.delete(userId, accountId);

    verify(accountRepository).delete(account);
    verify(accountRepository, never()).save(any());
  }

  @Test
  @DisplayName("Cuenta inexistente → NotFoundException")
  void getById_notFound() {
    when(accountRepository.findOneWithBalance(userId, accountId)).thenReturn(Optional.empty());

    assertThrows(NotFoundException.class, () -> accountService.getById(userId, accountId));
  }

  @Test
  @DisplayName("CREATE persiste cuenta y devuelve saldo inicial")
  void create_persistsAccount() {
    when(accountRepository.existsByUserIdAndNameIgnoreCase(userId, "Nueva")).thenReturn(false);
    when(accountRepository.save(any(Account.class)))
        .thenAnswer(
            inv -> {
              Account a = inv.getArgument(0);
              a.setId(accountId);
              return a;
            });
    when(accountRepository.findOneWithBalance(userId, accountId))
        .thenReturn(Optional.of(balanceRow("100.00", "100.00")));

    AccountRequest request =
        AccountRequest.builder()
            .name("Nueva")
            .type(AccountType.CASH)
            .initialBalance("100.00")
            .build();

    AccountResponse response = accountService.create(userId, request);

    assertEquals("100.00", response.getCurrentBalance());
    verify(accountRepository).save(any(Account.class));
  }

  @Test
  @DisplayName("LIST devuelve cuentas con saldo")
  void list_returnsAccountsWithBalance() {
    when(accountRepository.findAllWithBalance(userId, false))
        .thenReturn(List.of(balanceRow("0.00", "250.00")));

    var responses = accountService.list(userId, false);

    assertEquals(1, responses.size());
    assertEquals("250.00", responses.getFirst().getCurrentBalance());
  }

  @Test
  @DisplayName("UPDATE rechaza cuenta archivada")
  void update_archivedAccountThrows() {
    Account archived = accountEntity(true);
    when(accountRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(archived));

    AccountRequest request =
        AccountRequest.builder().name("X").type(AccountType.CASH).initialBalance("0.00").build();

    assertThrows(
        BusinessRuleException.class, () -> accountService.update(userId, accountId, request));
  }

  private Account accountEntity(boolean archived) {
    return Account.builder()
        .id(accountId)
        .userId(userId)
        .name("Efectivo")
        .type(AccountType.CASH)
        .initialBalance(new BigDecimal("100.00"))
        .archived(archived)
        .createdAt(Instant.now())
        .build();
  }

  private AccountBalanceRow balanceRow(String initial, String current) {
    return new AccountBalanceRow() {
      @Override
      public UUID getId() {
        return accountId;
      }

      @Override
      public String getName() {
        return "Efectivo";
      }

      @Override
      public String getType() {
        return "CASH";
      }

      @Override
      public BigDecimal getInitialBalance() {
        return new BigDecimal(initial);
      }

      @Override
      public BigDecimal getCurrentBalance() {
        return new BigDecimal(current);
      }

      @Override
      public boolean getArchived() {
        return false;
      }

      @Override
      public Instant getCreatedAt() {
        return Instant.now();
      }
    };
  }
}

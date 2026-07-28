package com.fintrack.support;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintrack.account.Account;
import com.fintrack.account.AccountRepository;
import com.fintrack.account.AccountType;
import com.fintrack.account.dto.AccountRequest;
import com.fintrack.category.Category;
import com.fintrack.category.CategoryKind;
import com.fintrack.category.CategoryRepository;
import com.fintrack.transaction.Transaction;
import com.fintrack.transaction.TransactionRepository;
import com.fintrack.transaction.TransactionType;
import com.fintrack.transaction.dto.TransactionRequest;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@Component
public class TestDataFactory {

  private static final String API = "";

  @Autowired private MockMvc mockMvc;

  @Autowired private ObjectMapper objectMapper;

  @Autowired private AccountRepository accountRepository;

  @Autowired private CategoryRepository categoryRepository;

  @Autowired private TransactionRepository transactionRepository;

  public Account anAccount(UUID userId, String name, String initialBalance) {
    Account account =
        Account.builder()
            .userId(userId)
            .name(name)
            .type(AccountType.CASH)
            .initialBalance(new BigDecimal(initialBalance))
            .archived(false)
            .createdAt(Instant.now())
            .build();
    return accountRepository.save(account);
  }

  public Category aCategory(UUID userId, String name, CategoryKind kind) {
    Category category =
        Category.builder()
            .userId(userId)
            .name(name)
            .kind(kind)
            .color("#FF7043")
            .icon("restaurant")
            .archived(false)
            .build();
    return categoryRepository.save(category);
  }

  public Transaction aTransaction(
      UUID userId,
      TransactionType type,
      BigDecimal amount,
      LocalDate date,
      Account account,
      Category category,
      Account transferAccount) {
    Instant now = Instant.now();
    Transaction transaction =
        Transaction.builder()
            .userId(userId)
            .type(type)
            .amount(amount)
            .date(date)
            .account(account)
            .category(category)
            .transferAccount(transferAccount)
            .createdAt(now)
            .updatedAt(now)
            .build();
    return transactionRepository.save(transaction);
  }

  public UUID createAccountViaApi(
      AuthTestHelper.Session session, String name, String initialBalance) throws Exception {
    AccountRequest request =
        AccountRequest.builder()
            .name(name)
            .type(AccountType.CASH)
            .initialBalance(initialBalance)
            .build();

    MvcResult result =
        mockMvc
            .perform(
                post(API + "/accounts")
                    .header("Authorization", session.bearer())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andReturn();

    JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
    return UUID.fromString(body.path("id").asText());
  }

  public UUID createExpenseViaApi(
      AuthTestHelper.Session session,
      UUID accountId,
      UUID categoryId,
      String amount,
      LocalDate date,
      String note)
      throws Exception {
    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount(amount)
            .date(date)
            .accountId(accountId)
            .categoryId(categoryId)
            .note(note)
            .build();

    MvcResult result =
        mockMvc
            .perform(
                post(API + "/transactions")
                    .header("Authorization", session.bearer())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andReturn();

    JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
    return UUID.fromString(body.path("id").asText());
  }

  public Category firstExpenseCategory(UUID userId) {
    return categoryRepository.findAllForUser(userId, CategoryKind.EXPENSE, false).stream()
        .findFirst()
        .orElseThrow();
  }

  public Category firstIncomeCategory(UUID userId) {
    return categoryRepository.findAllForUser(userId, CategoryKind.INCOME, false).stream()
        .findFirst()
        .orElseThrow();
  }
}

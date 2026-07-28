package com.fintrack.transaction;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintrack.account.Account;
import com.fintrack.account.AccountRepository;
import com.fintrack.category.Category;
import com.fintrack.support.AuthTestHelper;
import com.fintrack.support.AuthTestHelper.Session;
import com.fintrack.support.IntegrationTest;
import com.fintrack.support.TestDataFactory;
import com.fintrack.transaction.dto.TransactionRequest;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

class TransactionControllerIT extends IntegrationTest {

  private static final String API = "";

  @Autowired private ObjectMapper objectMapper;

  @Autowired private TestDataFactory testData;

  @Autowired private AccountRepository accountRepository;

  @Test
  @DisplayName("POST EXPENSE válido → 201 y saldo de cuenta refleja el cambio (RB-01)")
  void createExpense_updatesAccountBalance() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "expense@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Efectivo", "1000.00");
    Category category = testData.firstExpenseCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("250.50")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(category.getId())
            .note("Groceries")
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.amount").value("250.50"));

    mockMvc
        .perform(get(API + "/accounts/" + accountId).header("Authorization", session.bearer()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.currentBalance").value("749.50"));
  }

  @Test
  @DisplayName("F3.1: monto ≤ 0 → 400")
  void f31_amountZero_returns400() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "zero@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Cuenta", "100.00");
    Category category = testData.firstExpenseCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("0")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(category.getId())
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.detail", containsString("greater than zero")));
  }

  @Test
  @DisplayName("F3.1: 3 decimales → 400")
  void f31_threeDecimalPlaces_returns400() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "decimals@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Cuenta", "100.00");
    Category category = testData.firstExpenseCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("10.123")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(category.getId())
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isBadRequest());
  }

  @Test
  @DisplayName("F3.1: TRANSFER con categoría → 422")
  void f31_transferWithCategory_returns422() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "txcat@example.com");
    UUID from = testData.createAccountViaApi(session, "Origen", "100.00");
    UUID to = testData.createAccountViaApi(session, "Destino", "0.00");
    Category category = testData.firstExpenseCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.TRANSFER)
            .amount("50.00")
            .date(LocalDate.now())
            .accountId(from)
            .categoryId(category.getId())
            .transferAccountId(to)
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.detail", containsString("must not have a category")));
  }

  @Test
  @DisplayName("F3.1: TRANSFER a la misma cuenta → 422")
  void f31_transferSameAccount_returns422() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "same@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Cuenta", "100.00");

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.TRANSFER)
            .amount("50.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .transferAccountId(accountId)
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.detail", containsString("same account")));
  }

  @Test
  @DisplayName("F3.1: EXPENSE con categoría INCOME → 422")
  void f31_expenseWithIncomeCategory_returns422() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "kind@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Cuenta", "100.00");
    Category incomeCategory = testData.firstIncomeCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("25.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(incomeCategory.getId())
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.detail", containsString("does not match")));
  }

  @Test
  @DisplayName("F3.1: cuenta archivada → 422")
  void f31_archivedAccount_returns422() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "archived@example.com");
    Account account = testData.anAccount(session.userId(), "Archivada", "100.00");
    account.setArchived(true);
    accountRepository.save(account);
    Category category = testData.firstExpenseCategory(session.userId());

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("10.00")
            .date(LocalDate.now())
            .accountId(account.getId())
            .categoryId(category.getId())
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.detail", containsString("archived")));
  }

  @Test
  @DisplayName("GET paginado: filtros from/to, accountId, type, search")
  void list_filtersWork() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "filters@example.com");
    UUID accountA = testData.createAccountViaApi(session, "A", "500.00");
    UUID accountB = testData.createAccountViaApi(session, "B", "0.00");
    Category expense = testData.firstExpenseCategory(session.userId());
    Category income = testData.firstIncomeCategory(session.userId());

    LocalDate today = LocalDate.now();
    testData.createExpenseViaApi(
        session, accountA, expense.getId(), "100.00", today, "coffee shop");
    testData.createExpenseViaApi(
        session, accountA, expense.getId(), "50.00", today.minusDays(5), "other");

    TransactionRequest incomeReq =
        TransactionRequest.builder()
            .type(TransactionType.INCOME)
            .amount("200.00")
            .date(today)
            .accountId(accountB)
            .categoryId(income.getId())
            .build();
    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(incomeReq)))
        .andExpect(status().isCreated());

    mockMvc
        .perform(
            get(API + "/transactions")
                .header("Authorization", session.bearer())
                .param("type", "EXPENSE"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.totalElements").value(2));

    mockMvc
        .perform(
            get(API + "/transactions")
                .header("Authorization", session.bearer())
                .param("accountId", accountA.toString()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.totalElements").value(2));

    mockMvc
        .perform(
            get(API + "/transactions")
                .header("Authorization", session.bearer())
                .param("search", "coffee"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.totalElements").value(1));

    mockMvc
        .perform(
            get(API + "/transactions")
                .header("Authorization", session.bearer())
                .param("from", today.minusDays(1).toString())
                .param("to", today.toString()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.totalElements").value(2));
  }

  @Test
  @DisplayName("Paginación estable: 3 páginas no repiten ni pierden filas")
  void list_stablePagination() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "pages@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Pagos", "10000.00");
    Category category = testData.firstExpenseCategory(session.userId());

    LocalDate base = LocalDate.now().minusDays(30);
    for (int i = 0; i < 25; i++) {
      testData.createExpenseViaApi(
          session, accountId, category.getId(), "10.00", base.plusDays(i), "tx-" + i);
    }

    Set<String> seen = new HashSet<>();
    int page = 0;
    int total = 0;

    while (true) {
      var result =
          mockMvc
              .perform(
                  get(API + "/transactions")
                      .header("Authorization", session.bearer())
                      .param("page", String.valueOf(page))
                      .param("size", "10"))
              .andExpect(status().isOk())
              .andReturn();

      JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
      if (page == 0) {
        total = body.path("totalElements").asInt();
      }
      JsonNode content = body.path("content");
      for (JsonNode item : content) {
        String id = item.path("id").asText();
        assertTrue(seen.add(id), "Duplicate id on page " + page + ": " + id);
      }
      if (body.path("last").asBoolean()) {
        break;
      }
      page++;
    }

    assertEquals(25, total);
    assertEquals(25, seen.size());
    assertEquals(2, page);
  }

  @Test
  @DisplayName("DELETE → 204 y saldo se recalcula")
  void delete_recalculatesBalance() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "delete@example.com");
    UUID accountId = testData.createAccountViaApi(session, "Cuenta", "500.00");
    Category category = testData.firstExpenseCategory(session.userId());

    UUID txId =
        testData.createExpenseViaApi(
            session, accountId, category.getId(), "100.00", LocalDate.now(), "temp");

    mockMvc
        .perform(delete(API + "/transactions/" + txId).header("Authorization", session.bearer()))
        .andExpect(status().isNoContent());

    mockMvc
        .perform(get(API + "/accounts/" + accountId).header("Authorization", session.bearer()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.currentBalance").value("500.00"));
  }

  @Test
  @DisplayName("RB-05: transacción de otro usuario → 404 en GET, PUT y DELETE")
  void rb05_otherUsersTransaction_returns404() throws Exception {
    Session owner = AuthTestHelper.register(mockMvc, objectMapper, "owner@example.com");
    Session intruder = AuthTestHelper.register(mockMvc, objectMapper, "intruder@example.com");

    UUID accountId = testData.createAccountViaApi(owner, "Cuenta", "100.00");
    Category category = testData.firstExpenseCategory(owner.userId());
    UUID txId =
        testData.createExpenseViaApi(
            owner, accountId, category.getId(), "10.00", LocalDate.now(), "private");

    mockMvc
        .perform(get(API + "/transactions/" + txId).header("Authorization", intruder.bearer()))
        .andExpect(status().isNotFound());

    TransactionRequest update =
        TransactionRequest.builder()
            .type(TransactionType.EXPENSE)
            .amount("20.00")
            .date(LocalDate.now())
            .accountId(accountId)
            .categoryId(category.getId())
            .build();

    mockMvc
        .perform(
            put(API + "/transactions/" + txId)
                .header("Authorization", intruder.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(update)))
        .andExpect(status().isNotFound());

    mockMvc
        .perform(delete(API + "/transactions/" + txId).header("Authorization", intruder.bearer()))
        .andExpect(status().isNotFound());
  }

  @Test
  @DisplayName("RB-01: transferencias entrantes y salientes ajustan saldo")
  void rb01_transferUpdatesBothAccountBalances() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "transfer@example.com");
    UUID from = testData.createAccountViaApi(session, "Origen", "1000.00");
    UUID to = testData.createAccountViaApi(session, "Destino", "200.00");

    TransactionRequest request =
        TransactionRequest.builder()
            .type(TransactionType.TRANSFER)
            .amount("300.00")
            .date(LocalDate.now())
            .accountId(from)
            .transferAccountId(to)
            .build();

    mockMvc
        .perform(
            post(API + "/transactions")
                .header("Authorization", session.bearer())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
        .andExpect(status().isCreated());

    mockMvc
        .perform(get(API + "/accounts/" + from).header("Authorization", session.bearer()))
        .andExpect(jsonPath("$.currentBalance").value("700.00"));

    mockMvc
        .perform(get(API + "/accounts/" + to).header("Authorization", session.bearer()))
        .andExpect(jsonPath("$.currentBalance").value("500.00"));
  }
}

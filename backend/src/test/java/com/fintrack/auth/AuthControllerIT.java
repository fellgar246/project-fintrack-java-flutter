package com.fintrack.auth;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintrack.auth.dto.LoginRequest;
import com.fintrack.auth.dto.RegisterRequest;
import com.fintrack.category.CategoryRepository;
import com.fintrack.support.AuthTestHelper;
import com.fintrack.support.AuthTestHelper.Session;
import com.fintrack.support.IntegrationTest;
import com.fintrack.support.TestDataFactory;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

class AuthControllerIT extends IntegrationTest {

  private static final String API = "";

  @Autowired private ObjectMapper objectMapper;

  @Autowired private CategoryRepository categoryRepository;

  @Autowired private TestDataFactory testData;

  @Test
  @DisplayName("Registro exitoso → 201, tokens presentes, 12 categorías default")
  void register_success_createsDefaultCategories() throws Exception {
    RegisterRequest body = new RegisterRequest("alice@example.com", "password123", "Alice");

    var result =
        mockMvc
            .perform(
                post(API + "/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.tokens.accessToken").value(notNullValue()))
            .andExpect(jsonPath("$.tokens.refreshToken").value(notNullValue()))
            .andExpect(jsonPath("$.user.email").value("alice@example.com"))
            .andReturn();

    var root = objectMapper.readTree(result.getResponse().getContentAsString());
    UUID userId = UUID.fromString(root.path("user").path("id").asText());
    long categoryCount = categoryRepository.findAllForUser(userId, null, true).size();
    org.junit.jupiter.api.Assertions.assertEquals(12, categoryCount);
  }

  @Test
  @DisplayName("Email duplicado (distinta capitalización) → 409 Problem Details")
  void register_duplicateEmailDifferentCase_returns409() throws Exception {
    AuthTestHelper.register(mockMvc, objectMapper, "user@example.com");

    RegisterRequest duplicate = new RegisterRequest("User@Example.com", "password123", "Other");

    mockMvc
        .perform(
            post(API + "/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(duplicate)))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status").value(409))
        .andExpect(jsonPath("$.detail").value("Email already registered"));
  }

  @Test
  @DisplayName("Password < 8 → 400 con errors[]")
  void register_shortPassword_returns400WithErrors() throws Exception {
    RegisterRequest body = new RegisterRequest("short@example.com", "abc", "User");

    mockMvc
        .perform(
            post(API + "/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(body)))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.errors", hasSize(1)))
        .andExpect(jsonPath("$.errors[0].field").value("password"));
  }

  @Test
  @DisplayName("Login correcto → 200; password incorrecta → 401 genérico")
  void login_validAndInvalidCredentials() throws Exception {
    AuthTestHelper.register(mockMvc, objectMapper, "login@example.com");

    LoginRequest valid = new LoginRequest("login@example.com", "password123");
    mockMvc
        .perform(
            post(API + "/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(valid)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tokens.accessToken").value(notNullValue()));

    LoginRequest invalid = new LoginRequest("login@example.com", "wrong-password");
    mockMvc
        .perform(
            post(API + "/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalid)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.detail").value("Credenciales inválidas"));
  }

  @Test
  @DisplayName("Endpoint protegido sin token → 401; con token válido → 200")
  void protectedEndpoint_requiresBearerToken() throws Exception {
    mockMvc.perform(get(API + "/accounts")).andExpect(status().isUnauthorized());

    Session session = AuthTestHelper.register(mockMvc, objectMapper, "protected@example.com");

    mockMvc
        .perform(get(API + "/accounts").header("Authorization", session.bearer()))
        .andExpect(status().isOk());
  }

  @Test
  @DisplayName("Refresh rota el token: el viejo deja de servir → 401")
  void refresh_rotatesToken_oldRefreshTokenRejected() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "refresh@example.com");
    String oldRefresh = session.refreshToken();

    Session rotated = AuthTestHelper.refresh(mockMvc, objectMapper, oldRefresh);

    mockMvc
        .perform(
            post(API + "/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    objectMapper.writeValueAsString(
                        new com.fintrack.auth.dto.RefreshRequest(oldRefresh))))
        .andExpect(status().isUnauthorized());

    mockMvc
        .perform(get(API + "/accounts").header("Authorization", "Bearer " + rotated.accessToken()))
        .andExpect(status().isOk());
  }

  @Test
  @DisplayName("Logout revoca; segundo logout → 204 (idempotente)")
  void logout_idempotent() throws Exception {
    Session session = AuthTestHelper.register(mockMvc, objectMapper, "logout@example.com");

    AuthTestHelper.logout(mockMvc, objectMapper, session.refreshToken());
    AuthTestHelper.logout(mockMvc, objectMapper, session.refreshToken());
  }

  @Test
  @DisplayName("RB-05: usuario A no puede leer recursos del usuario B → 404")
  void rb05_userCannotAccessOtherUsersAccount() throws Exception {
    Session userA = AuthTestHelper.register(mockMvc, objectMapper, "user-a@example.com");
    Session userB = AuthTestHelper.register(mockMvc, objectMapper, "user-b@example.com");

    UUID accountId = testData.createAccountViaApi(userA, "Cuenta A", "100.00");

    mockMvc
        .perform(get(API + "/accounts/" + accountId).header("Authorization", userB.bearer()))
        .andExpect(status().isNotFound());
  }
}

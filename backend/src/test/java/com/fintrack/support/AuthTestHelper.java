package com.fintrack.support;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintrack.auth.dto.LoginRequest;
import com.fintrack.auth.dto.LogoutRequest;
import com.fintrack.auth.dto.RefreshRequest;
import com.fintrack.auth.dto.RegisterRequest;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/** Registers users via the real auth API and returns bearer headers for protected endpoints. */
public final class AuthTestHelper {

  private static final String API = "";

  private AuthTestHelper() {}

  public record Session(UUID userId, String email, String accessToken, String refreshToken) {
    public String bearer() {
      return "Bearer " + accessToken;
    }
  }

  public static Session register(MockMvc mockMvc, ObjectMapper mapper, String email)
      throws Exception {
    return register(mockMvc, mapper, email, "password123", "Test User");
  }

  public static Session register(
      MockMvc mockMvc, ObjectMapper mapper, String email, String password, String name)
      throws Exception {
    RegisterRequest body = new RegisterRequest(email, password, name);

    MvcResult result =
        mockMvc
            .perform(
                post(API + "/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn();

    return parseAuthResponse(mapper, result);
  }

  public static Session login(MockMvc mockMvc, ObjectMapper mapper, String email, String password)
      throws Exception {
    LoginRequest body = new LoginRequest(email, password);

    MvcResult result =
        mockMvc
            .perform(
                post(API + "/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(mapper.writeValueAsString(body)))
            .andExpect(status().isOk())
            .andReturn();

    return parseAuthResponse(mapper, result);
  }

  public static Session refresh(MockMvc mockMvc, ObjectMapper mapper, String refreshToken)
      throws Exception {
    RefreshRequest body = new RefreshRequest(refreshToken);

    MvcResult result =
        mockMvc
            .perform(
                post(API + "/auth/refresh")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(mapper.writeValueAsString(body)))
            .andExpect(status().isOk())
            .andReturn();

    JsonNode root = mapper.readTree(result.getResponse().getContentAsString());
    JsonNode tokens = root.path("tokens");
    if (tokens.isMissingNode()) {
      tokens = root;
    }

    return new Session(
        null, null, tokens.path("accessToken").asText(), tokens.path("refreshToken").asText());
  }

  public static void logout(MockMvc mockMvc, ObjectMapper mapper, String refreshToken)
      throws Exception {
    LogoutRequest body = new LogoutRequest(refreshToken);

    mockMvc
        .perform(
            post(API + "/auth/logout")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
        .andExpect(status().isNoContent());
  }

  private static Session parseAuthResponse(ObjectMapper mapper, MvcResult result) throws Exception {
    JsonNode root = mapper.readTree(result.getResponse().getContentAsString());
    JsonNode user = root.path("user");
    JsonNode tokens = root.path("tokens");

    return new Session(
        UUID.fromString(user.path("id").asText()),
        user.path("email").asText(),
        tokens.path("accessToken").asText(),
        tokens.path("refreshToken").asText());
  }
}

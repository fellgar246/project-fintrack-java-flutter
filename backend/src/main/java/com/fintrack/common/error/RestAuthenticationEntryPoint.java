package com.fintrack.common.error;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

/**
 * Handles 401s that Spring Security itself raises (missing/invalid token on a protected route)
 * before the request ever reaches a controller. {@code @RestControllerAdvice} cannot see these —
 * this is the only place they can be put in Problem Details format.
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

  private final ProblemDetailsWriter writer;

  public RestAuthenticationEntryPoint(ProblemDetailsWriter writer) {
    this.writer = writer;
  }

  @Override
  public void commence(
      HttpServletRequest request,
      HttpServletResponse response,
      AuthenticationException authException)
      throws IOException {
    writer.write(
        response,
        request,
        HttpServletResponse.SC_UNAUTHORIZED,
        "Unauthorized",
        "Authentication is required to access this resource");
  }
}

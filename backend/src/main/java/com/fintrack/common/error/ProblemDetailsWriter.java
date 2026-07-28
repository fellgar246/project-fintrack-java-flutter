package com.fintrack.common.error;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;

/**
 * Serializes a Problem Details body directly onto the servlet response. Used by {@link
 * RestAuthenticationEntryPoint} and {@link RestAccessDeniedHandler}, which run inside Spring
 * Security's filter chain before a controller (and therefore {@code @RestControllerAdvice}) ever
 * gets involved.
 */
@Component
public class ProblemDetailsWriter {

  private static final String PROBLEM_JSON = "application/problem+json";

  private final ObjectMapper objectMapper;

  public ProblemDetailsWriter(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public void write(
      HttpServletResponse response,
      HttpServletRequest request,
      int status,
      String title,
      String detail)
      throws IOException {
    response.setStatus(status);
    response.setContentType(PROBLEM_JSON);

    ErrorResponse body =
        ErrorResponse.builder()
            .type("about:blank")
            .title(title)
            .status(status)
            .detail(detail)
            .instance(request.getRequestURI())
            .build();

    objectMapper.writeValue(response.getWriter(), body);
  }
}

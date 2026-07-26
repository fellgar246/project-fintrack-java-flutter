package com.fintrack.common.error;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

/**
 * Mirrors {@link RestAuthenticationEntryPoint} for the 403 case (authenticated, but not
 * authorized) — same reasoning: it runs inside the security filter chain, not a controller.
 */
@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {

    private final ProblemDetailsWriter writer;

    public RestAccessDeniedHandler(ProblemDetailsWriter writer) {
        this.writer = writer;
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException)
        throws IOException {
        writer.write(
            response,
            request,
            HttpServletResponse.SC_FORBIDDEN,
            "Forbidden",
            "You don't have permission to access this resource"
        );
    }
}

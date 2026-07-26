package com.fintrack.config;

import java.util.UUID;

/**
 * Authentication principal set by {@code JwtAuthFilter}. Controllers read it via
 * {@code @AuthenticationPrincipal CurrentUser currentUser} instead of ever trusting a
 * client-supplied userId (RB-05).
 */
public record CurrentUser(UUID id, String email) {
}

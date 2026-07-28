package com.fintrack.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Issues, rotates and revokes refresh tokens. The raw token only ever exists in memory and in the
 * response sent to the client; the database stores just its SHA-256 hash, so a leaked database dump
 * doesn't hand out usable tokens.
 */
@Service
public class RefreshTokenService {

  private static final int TOKEN_BYTES = 32;
  private static final String INVALID_TOKEN_MESSAGE = "Invalid refresh token";

  private final RefreshTokenRepository repository;
  private final long refreshTtlDays;
  private final SecureRandom secureRandom = new SecureRandom();

  public RefreshTokenService(
      RefreshTokenRepository repository,
      @Value("${app.jwt.refresh-ttl-days}") long refreshTtlDays) {
    this.repository = repository;
    this.refreshTtlDays = refreshTtlDays;
  }

  @Transactional
  public String issue(UUID userId) {
    String rawToken = generateRawToken();
    RefreshToken entity =
        RefreshToken.builder()
            .userId(userId)
            .tokenHash(hash(rawToken))
            .expiresAt(Instant.now().plus(refreshTtlDays, ChronoUnit.DAYS))
            .revoked(false)
            .build();
    repository.save(entity);
    return rawToken;
  }

  /**
   * Validates the raw token (exists, not revoked, not expired) and revokes it. Returns the owning
   * userId so the caller can issue a fresh pair. Throws {@link BadCredentialsException} for any
   * invalid/reused/expired token.
   */
  @Transactional
  public UUID rotate(String rawToken) {
    RefreshToken existing = findValid(rawToken);
    existing.setRevoked(true);
    repository.save(existing);
    return existing.getUserId();
  }

  // Idempotent: revoking an unknown or already-revoked token is a no-op, not an error.
  @Transactional
  public void revoke(String rawToken) {
    repository
        .findByTokenHash(hash(rawToken))
        .ifPresent(
            token -> {
              token.setRevoked(true);
              repository.save(token);
            });
  }

  private RefreshToken findValid(String rawToken) {
    RefreshToken token =
        repository
            .findByTokenHash(hash(rawToken))
            .orElseThrow(() -> new BadCredentialsException(INVALID_TOKEN_MESSAGE));

    if (Boolean.TRUE.equals(token.getRevoked()) || token.getExpiresAt().isBefore(Instant.now())) {
      throw new BadCredentialsException(INVALID_TOKEN_MESSAGE);
    }

    return token;
  }

  private String generateRawToken() {
    byte[] bytes = new byte[TOKEN_BYTES];
    secureRandom.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  private String hash(String rawToken) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      return HexFormat.of().formatHex(digest.digest(rawToken.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException ex) {
      throw new IllegalStateException("SHA-256 is not available", ex);
    }
  }
}

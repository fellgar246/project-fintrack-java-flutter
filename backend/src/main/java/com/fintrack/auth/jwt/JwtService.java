package com.fintrack.auth.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Signs and validates HS256 access tokens. The signing key is derived from {@code app.jwt.secret};
 * a secret shorter than 256 bits (32 bytes) fails the app at startup instead of silently signing
 * tokens with a weak key.
 */
@Service
public class JwtService {

  private static final String EMAIL_CLAIM = "email";
  private static final int MIN_SECRET_BYTES = 32;

  private final SecretKey key;
  private final long accessTtlMinutes;

  public JwtService(
      @Value("${app.jwt.secret}") String secret,
      @Value("${app.jwt.access-ttl-min}") long accessTtlMinutes) {
    byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
    if (keyBytes.length < MIN_SECRET_BYTES) {
      throw new IllegalStateException(
          "app.jwt.secret must be at least 256 bits (32 bytes) long, got "
              + keyBytes.length
              + " bytes");
    }
    this.key = Keys.hmacShaKeyFor(keyBytes);
    this.accessTtlMinutes = accessTtlMinutes;
  }

  public String generateAccessToken(UUID userId, String email) {
    Instant now = Instant.now();
    return Jwts.builder()
        .subject(userId.toString())
        .claim(EMAIL_CLAIM, email)
        .issuedAt(Date.from(now))
        .expiration(Date.from(now.plus(accessTtlMinutes, ChronoUnit.MINUTES)))
        .signWith(key, Jwts.SIG.HS256)
        .compact();
  }

  /**
   * Parses and validates the token's signature and expiration. Throws {@link JwtException} (or
   * {@link IllegalArgumentException} for a blank token) if the token is invalid.
   */
  public Claims parseClaims(String token) {
    return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
  }

  public UUID extractUserId(Claims claims) {
    return UUID.fromString(claims.getSubject());
  }

  public String extractEmail(Claims claims) {
    return claims.get(EMAIL_CLAIM, String.class);
  }
}

package com.fintrack.auth;

import com.fintrack.auth.dto.AuthResponse;
import com.fintrack.auth.dto.LoginRequest;
import com.fintrack.auth.dto.LogoutRequest;
import com.fintrack.auth.dto.RefreshRequest;
import com.fintrack.auth.dto.RegisterRequest;
import com.fintrack.auth.dto.TokensResponse;
import com.fintrack.auth.dto.UserResponse;
import com.fintrack.auth.jwt.JwtService;
import com.fintrack.category.CategorySeedService;
import com.fintrack.common.error.ConflictException;
import com.fintrack.user.User;
import com.fintrack.user.UserRepository;
import java.time.Instant;
import java.util.Locale;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Orchestrates registration, login, refresh and logout. The tricky parts live here on purpose: the
 * transactional boundary between creating a user and seeding their default categories, normalizing
 * the email before checking uniqueness, and turning a raced UNIQUE-constraint violation into a 409
 * instead of letting it surface as a 500.
 */
@Service
public class AuthService {

  private static final String DEFAULT_BASE_CURRENCY = "MXN";
  private static final String EMAIL_CONFLICT_MESSAGE = "Email already registered";
  private static final String INVALID_CREDENTIALS_MESSAGE = "Credenciales inválidas";

  private final UserRepository userRepository;
  private final CategorySeedService categorySeedService;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;
  private final RefreshTokenService refreshTokenService;

  public AuthService(
      UserRepository userRepository,
      CategorySeedService categorySeedService,
      PasswordEncoder passwordEncoder,
      JwtService jwtService,
      RefreshTokenService refreshTokenService) {
    this.userRepository = userRepository;
    this.categorySeedService = categorySeedService;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
    this.refreshTokenService = refreshTokenService;
  }

  /**
   * Creates the user and seeds their default categories in the same transaction: if the seed fails,
   * the user insert is rolled back too. The email uniqueness check is best-effort (existsByEmail)
   * plus a hard backstop: the pre-check can't close a race between two concurrent registrations, so
   * a caught {@link DataIntegrityViolationException} from the DB's UNIQUE constraint is what
   * actually guarantees a 409 instead of a 500.
   */
  @Transactional
  public AuthResponse register(RegisterRequest request) {
    String normalizedEmail = normalizeEmail(request.getEmail());

    if (userRepository.existsByEmail(normalizedEmail)) {
      throw new ConflictException(EMAIL_CONFLICT_MESSAGE);
    }

    User user =
        User.builder()
            .email(normalizedEmail)
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .name(request.getName())
            .baseCurrency(DEFAULT_BASE_CURRENCY)
            .createdAt(Instant.now())
            .build();

    try {
      user = userRepository.saveAndFlush(user);
    } catch (DataIntegrityViolationException ex) {
      throw new ConflictException(EMAIL_CONFLICT_MESSAGE);
    }

    categorySeedService.seedDefaultCategories(user.getId());

    return new AuthResponse(toUserResponse(user), issueTokens(user));
  }

  public AuthResponse login(LoginRequest request) {
    String normalizedEmail = normalizeEmail(request.getEmail());

    User user =
        userRepository
            .findByEmail(normalizedEmail)
            .filter(
                candidate ->
                    passwordEncoder.matches(request.getPassword(), candidate.getPasswordHash()))
            .orElseThrow(() -> new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE));

    return new AuthResponse(toUserResponse(user), issueTokens(user));
  }

  @Transactional
  public TokensResponse refresh(RefreshRequest request) {
    var userId = refreshTokenService.rotate(request.getRefreshToken());
    User user =
        userRepository
            .findById(userId)
            .orElseThrow(() -> new BadCredentialsException(INVALID_CREDENTIALS_MESSAGE));
    return issueTokens(user);
  }

  public void logout(LogoutRequest request) {
    refreshTokenService.revoke(request.getRefreshToken());
  }

  private TokensResponse issueTokens(User user) {
    String accessToken = jwtService.generateAccessToken(user.getId(), user.getEmail());
    String refreshToken = refreshTokenService.issue(user.getId());
    return new TokensResponse(accessToken, refreshToken);
  }

  private String normalizeEmail(String email) {
    return email.trim().toLowerCase(Locale.ROOT);
  }

  private UserResponse toUserResponse(User user) {
    return new UserResponse(
        user.getId(), user.getEmail(), user.getName(), user.getBaseCurrency(), user.getCreatedAt());
  }
}

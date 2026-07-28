package com.fintrack.dev;

import com.fintrack.config.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import org.springframework.context.annotation.Profile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dev")
@Profile("dev")
@Tag(name = "Dev")
public class DevSeedController {

  private final DevSeedService devSeedService;

  public DevSeedController(DevSeedService devSeedService) {
    this.devSeedService = devSeedService;
  }

  @PostMapping("/seed")
  @Operation(
      description =
          "Seeds 6 months of sample transactions for the authenticated user (dev profile only).")
  public Map<String, Object> seed(@AuthenticationPrincipal CurrentUser currentUser) {
    int created = devSeedService.seedSampleData(currentUser.id());
    return Map.of("transactionsCreated", created);
  }
}

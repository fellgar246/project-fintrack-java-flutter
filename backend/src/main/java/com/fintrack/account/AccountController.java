package com.fintrack.account;

import com.fintrack.account.dto.AccountRequest;
import com.fintrack.account.dto.AccountResponse;
import com.fintrack.config.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/accounts")
@Tag(name = "Accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping
    public List<AccountResponse> list(
        @AuthenticationPrincipal CurrentUser currentUser,
        @RequestParam(defaultValue = "false") boolean includeArchived
    ) {
        return accountService.list(currentUser.id(), includeArchived);
    }

    @PostMapping
    public ResponseEntity<AccountResponse> create(
        @AuthenticationPrincipal CurrentUser currentUser,
        @Valid @RequestBody AccountRequest request
    ) {
        AccountResponse response = accountService.create(currentUser.id(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public AccountResponse getById(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id
    ) {
        return accountService.getById(currentUser.id(), id);
    }

    @PutMapping("/{id}")
    public AccountResponse update(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id,
        @Valid @RequestBody AccountRequest request
    ) {
        return accountService.update(currentUser.id(), id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(
        summary = "Delete or archive an account",
        description = """
            RB-02: if the account has any transactions (as source or transfer destination) it is \
            archived (archived=true) and hidden from the default list; otherwise it is physically \
            deleted from the database. Always returns 204.
            """
    )
    @ApiResponse(responseCode = "204", description = "Account deleted or archived")
    public ResponseEntity<Void> delete(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id
    ) {
        accountService.delete(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}

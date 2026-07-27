package com.fintrack.transaction;

import com.fintrack.config.CurrentUser;
import com.fintrack.transaction.dto.TransactionPageResponse;
import com.fintrack.transaction.dto.TransactionRequest;
import com.fintrack.transaction.dto.TransactionResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
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
@RequestMapping("/transactions")
@Tag(name = "Transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping
    @Operation(
        summary = "List transactions with pagination and filters",
        description = """
            Returns a stable paginated envelope. Sort always includes `id` as a tie-breaker. \
            `accountId` matches the source account or the transfer destination.
            """
    )
    public TransactionPageResponse list(
        @AuthenticationPrincipal CurrentUser currentUser,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(defaultValue = "date,desc") String sort,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
        @RequestParam(required = false) UUID accountId,
        @RequestParam(required = false) UUID categoryId,
        @RequestParam(required = false) TransactionType type,
        @RequestParam(required = false) String search
    ) {
        return transactionService.list(currentUser.id(), new TransactionService.TransactionListParams(
            page,
            size,
            sort,
            from,
            to,
            accountId,
            categoryId,
            type,
            search
        ));
    }

    @PostMapping
    @Operation(summary = "Create a transaction")
    @ApiResponse(responseCode = "201", description = "Transaction created")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
        content = @Content(
            examples = @ExampleObject(
                name = "Expense",
                value = """
                    {
                      "type": "EXPENSE",
                      "amount": "1234.50",
                      "date": "2026-07-25",
                      "accountId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                      "categoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa7",
                      "transferAccountId": null,
                      "note": "Groceries"
                    }
                    """
            )
        )
    )
    public ResponseEntity<TransactionResponse> create(
        @AuthenticationPrincipal CurrentUser currentUser,
        @Valid @RequestBody TransactionRequest request
    ) {
        TransactionResponse response = transactionService.create(currentUser.id(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public TransactionResponse getById(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id
    ) {
        return transactionService.getById(currentUser.id(), id);
    }

    @PutMapping("/{id}")
    @Operation(
        summary = "Update a transaction",
        description = "Allows changing the transaction type; all RB-03 rules are revalidated."
    )
    public TransactionResponse update(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id,
        @Valid @RequestBody TransactionRequest request
    ) {
        return transactionService.update(currentUser.id(), id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a transaction", description = "Hard delete (RB-04). Always returns 204.")
    @ApiResponse(responseCode = "204", description = "Transaction deleted")
    public ResponseEntity<Void> delete(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id
    ) {
        transactionService.delete(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}

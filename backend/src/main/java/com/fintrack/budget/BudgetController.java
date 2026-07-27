package com.fintrack.budget;

import com.fintrack.budget.dto.BudgetResponse;
import com.fintrack.budget.dto.BudgetUpsertRequest;
import com.fintrack.config.CurrentUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/budgets")
@Tag(name = "Budgets")
public class BudgetController {

    private final BudgetService budgetService;

    public BudgetController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @GetMapping
    @Operation(description = "Lists budgets for a month with spent amounts. Defaults to the current month.")
    public List<BudgetResponse> list(
        @AuthenticationPrincipal CurrentUser currentUser,
        @RequestParam(required = false) String yearMonth,
        @RequestParam(defaultValue = "false") boolean includeUnbudgeted
    ) {
        return budgetService.list(currentUser.id(), yearMonth, includeUnbudgeted);
    }

    @PutMapping
    @Operation(
        summary = "Create or update a budget",
        description = "Upserts by (categoryId, yearMonth). Returns 200 for both create and update (no 201)."
    )
    @ApiResponse(responseCode = "200", description = "Budget created or updated")
    public BudgetResponse upsert(
        @AuthenticationPrincipal CurrentUser currentUser,
        @Valid @RequestBody BudgetUpsertRequest request
    ) {
        return budgetService.upsert(currentUser.id(), request);
    }

    @DeleteMapping("/{id}")
    @ApiResponse(responseCode = "204", description = "Budget deleted")
    public ResponseEntity<Void> delete(
        @AuthenticationPrincipal CurrentUser currentUser,
        @PathVariable UUID id
    ) {
        budgetService.delete(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}

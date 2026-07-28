package com.fintrack.category;

import com.fintrack.category.dto.CategoryRequest;
import com.fintrack.category.dto.CategoryResponse;
import com.fintrack.category.dto.CategoryUpdateRequest;
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
@RequestMapping("/categories")
@Tag(name = "Categories")
public class CategoryController {

  private final CategoryService categoryService;

  public CategoryController(CategoryService categoryService) {
    this.categoryService = categoryService;
  }

  @GetMapping
  public List<CategoryResponse> list(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestParam(required = false) CategoryKind kind,
      @RequestParam(defaultValue = "false") boolean includeArchived) {
    return categoryService.list(currentUser.id(), kind, includeArchived);
  }

  @PostMapping
  public ResponseEntity<CategoryResponse> create(
      @AuthenticationPrincipal CurrentUser currentUser,
      @Valid @RequestBody CategoryRequest request) {
    CategoryResponse response = categoryService.create(currentUser.id(), request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/{id}")
  public CategoryResponse getById(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
    return categoryService.getById(currentUser.id(), id);
  }

  @PutMapping("/{id}")
  @Operation(
      description = "Updates name, color and icon. `kind` is immutable and must not be changed.")
  public CategoryResponse update(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID id,
      @Valid @RequestBody CategoryUpdateRequest request) {
    return categoryService.update(currentUser.id(), id, request);
  }

  @DeleteMapping("/{id}")
  @Operation(
      summary = "Delete or archive a category",
      description =
          """
            RB-02: if the category has any transactions or budgets it is archived (archived=true) \
            and hidden from the default list; otherwise it is physically deleted. Always returns 204.
            """)
  @ApiResponse(responseCode = "204", description = "Category deleted or archived")
  public ResponseEntity<Void> delete(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
    categoryService.delete(currentUser.id(), id);
    return ResponseEntity.noContent().build();
  }
}

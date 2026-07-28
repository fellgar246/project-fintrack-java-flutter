package com.fintrack.category;

import com.fintrack.category.dto.CategoryRequest;
import com.fintrack.category.dto.CategoryResponse;
import com.fintrack.category.dto.CategoryUpdateRequest;
import com.fintrack.common.error.BusinessRuleException;
import com.fintrack.common.error.ConflictException;
import com.fintrack.common.error.NotFoundException;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CategoryService {

  private static final String NOT_FOUND_MESSAGE = "Category not found";
  private static final String DUPLICATE_NAME_MESSAGE =
      "A category with that name already exists for this kind";
  private static final String ARCHIVED_EDIT_MESSAGE = "Archived categories cannot be edited";

  private final CategoryRepository categoryRepository;
  private final CategoryMapper categoryMapper;

  public CategoryService(CategoryRepository categoryRepository, CategoryMapper categoryMapper) {
    this.categoryRepository = categoryRepository;
    this.categoryMapper = categoryMapper;
  }

  public List<CategoryResponse> list(UUID userId, CategoryKind kind, boolean includeArchived) {
    return categoryRepository.findAllForUser(userId, kind, includeArchived).stream()
        .map(categoryMapper::toResponse)
        .toList();
  }

  public CategoryResponse getById(UUID userId, UUID categoryId) {
    Category category =
        categoryRepository
            .findByIdAndUserId(categoryId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));
    return categoryMapper.toResponse(category);
  }

  @Transactional
  public CategoryResponse create(UUID userId, CategoryRequest request) {
    String name = request.getName().trim();
    assertUniqueName(userId, name, request.getKind(), null);

    Category category =
        Category.builder()
            .userId(userId)
            .name(name)
            .kind(request.getKind())
            .color(request.getColor().toUpperCase())
            .icon(request.getIcon())
            .archived(false)
            .build();

    category = categoryRepository.save(category);
    return categoryMapper.toResponse(category);
  }

  @Transactional
  public CategoryResponse update(UUID userId, UUID categoryId, CategoryUpdateRequest request) {
    Category category =
        categoryRepository
            .findByIdAndUserId(categoryId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));

    if (Boolean.TRUE.equals(category.getArchived())) {
      throw new BusinessRuleException(ARCHIVED_EDIT_MESSAGE);
    }

    String name = request.getName().trim();
    assertUniqueName(userId, name, category.getKind(), categoryId);

    category.setName(name);
    category.setColor(request.getColor().toUpperCase());
    category.setIcon(request.getIcon());
    categoryRepository.save(category);

    return categoryMapper.toResponse(category);
  }

  /**
   * RB-02: archives when the category has transactions or budgets; physically deletes otherwise.
   */
  @Transactional
  public void delete(UUID userId, UUID categoryId) {
    Category category =
        categoryRepository
            .findByIdAndUserId(categoryId, userId)
            .orElseThrow(() -> new NotFoundException(NOT_FOUND_MESSAGE));

    if (categoryRepository.hasTransactions(userId, categoryId)
        || categoryRepository.hasBudgets(userId, categoryId)) {
      category.setArchived(true);
      categoryRepository.save(category);
    } else {
      categoryRepository.delete(category);
    }
  }

  private void assertUniqueName(UUID userId, String name, CategoryKind kind, UUID excludeId) {
    boolean duplicate =
        excludeId == null
            ? categoryRepository.existsByUserIdAndNameIgnoreCaseAndKind(userId, name, kind)
            : categoryRepository.existsByUserIdAndNameIgnoreCaseAndKindAndIdNot(
                userId, name, kind, excludeId);

    if (duplicate) {
      throw new ConflictException(DUPLICATE_NAME_MESSAGE);
    }
  }
}

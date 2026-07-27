package com.fintrack.category;

import com.fintrack.category.dto.CategoryResponse;
import org.springframework.stereotype.Component;

@Component
public class CategoryMapper {

    public CategoryResponse toResponse(Category category) {
        return CategoryResponse.builder()
            .id(category.getId())
            .name(category.getName())
            .kind(category.getKind())
            .color(category.getColor())
            .icon(category.getIcon())
            .archived(category.getArchived())
            .build();
    }
}

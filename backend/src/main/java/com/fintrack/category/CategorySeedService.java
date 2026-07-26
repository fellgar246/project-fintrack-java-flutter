package com.fintrack.category;

import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class CategorySeedService {

    private final CategoryRepository categoryRepository;

    public CategorySeedService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    // Seeds 12 default categories for a newly registered user.
    public void seedDefaultCategories(UUID userId) {
        // EXPENSE categories
        seedCategory(userId, "Comida", "EXPENSE", "#FF7043", "restaurant");
        seedCategory(userId, "Transporte", "EXPENSE", "#42A5F5", "directions_bus");
        seedCategory(userId, "Renta", "EXPENSE", "#8D6E63", "home");
        seedCategory(userId, "Servicios", "EXPENSE", "#FFCA28", "bolt");
        seedCategory(userId, "Salud", "EXPENSE", "#EF5350", "local_hospital");
        seedCategory(userId, "Entretenimiento", "EXPENSE", "#AB47BC", "movie");
        seedCategory(userId, "Compras", "EXPENSE", "#26A69A", "shopping_bag");
        seedCategory(userId, "Educación", "EXPENSE", "#5C6BC0", "school");

        // INCOME categories
        seedCategory(userId, "Salario", "INCOME", "#4CAF50", "payments");
        seedCategory(userId, "Freelance", "INCOME", "#66BB6A", "work");
        seedCategory(userId, "Inversiones", "INCOME", "#9CCC65", "trending_up");
        seedCategory(userId, "Otros ingresos", "INCOME", "#26C6DA", "add_circle");
    }

    private void seedCategory(UUID userId, String name, String kind, String color, String icon) {
        Category category = Category.builder()
            .userId(userId)
            .name(name)
            .kind(kind)
            .color(color)
            .icon(icon)
            .archived(false)
            .build();
        categoryRepository.save(category);
    }
}

package com.fintrack.budget;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(
    name = "budgets",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"user_id", "category_id", "year_month"},
        name = "uq_budgets_user_category_month"
    )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Budget {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "year_month", nullable = false, length = 7)
    private String yearMonth;

    @Column(name = "limit_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal limitAmount;
}

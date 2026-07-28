package com.fintrack.transaction;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface TransactionRepository
    extends JpaRepository<Transaction, UUID>, JpaSpecificationExecutor<Transaction> {

  @EntityGraph(Transaction.WITH_RELATIONS)
  Optional<Transaction> findByIdAndUserId(UUID id, UUID userId);

  @Override
  @EntityGraph(Transaction.WITH_RELATIONS)
  Page<Transaction> findAll(Specification<Transaction> spec, Pageable pageable);
}

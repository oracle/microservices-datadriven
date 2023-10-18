package com.example.dra.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.NoRepositoryBean;

@NoRepositoryBean
public interface BaseJpaRepository<T, ID> extends JpaRepository<T, ID> {
    default T findOne(ID id) {
        return (T) findById(id).orElse(null);
    }
}


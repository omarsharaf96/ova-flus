package com.ovaflus.app.di

import com.ovaflus.app.data.repositories.BudgetRepository
import com.ovaflus.app.data.repositories.BudgetRepositoryImpl
import com.ovaflus.app.data.repositories.PortfolioRepository
import com.ovaflus.app.data.repositories.PortfolioRepositoryImpl
import com.ovaflus.app.data.repositories.TransactionRepository
import com.ovaflus.app.data.repositories.TransactionRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindBudgetRepository(impl: BudgetRepositoryImpl): BudgetRepository

    @Binds
    @Singleton
    abstract fun bindTransactionRepository(impl: TransactionRepositoryImpl): TransactionRepository

    @Binds
    @Singleton
    abstract fun bindPortfolioRepository(impl: PortfolioRepositoryImpl): PortfolioRepository
}

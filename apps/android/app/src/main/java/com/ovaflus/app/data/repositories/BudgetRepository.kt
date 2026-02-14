package com.ovaflus.app.data.repositories

import com.ovaflus.app.data.local.dao.BudgetDao
import com.ovaflus.app.data.remote.ApiService
import com.ovaflus.app.domain.models.Budget
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

interface BudgetRepository {
    suspend fun getBudgets(): List<Budget>
    fun observeBudgets(): Flow<List<Budget>>
    suspend fun getBudgetById(id: String): Budget?
    suspend fun createBudget(budget: Budget)
    suspend fun updateBudget(budget: Budget)
    suspend fun deleteBudget(id: String)
}

class BudgetRepositoryImpl @Inject constructor(
    private val budgetDao: BudgetDao,
    private val apiService: ApiService,
) : BudgetRepository {

    override suspend fun getBudgets(): List<Budget> {
        return try {
            val remoteBudgets = apiService.getBudgets()
            budgetDao.insertAll(remoteBudgets)
            remoteBudgets
        } catch (e: Exception) {
            budgetDao.getAllBudgets()
        }
    }

    override fun observeBudgets(): Flow<List<Budget>> {
        return budgetDao.observeAllBudgets()
    }

    override suspend fun getBudgetById(id: String): Budget? {
        return budgetDao.getBudgetById(id)
    }

    override suspend fun createBudget(budget: Budget) {
        apiService.createBudget(budget)
        budgetDao.insert(budget)
    }

    override suspend fun updateBudget(budget: Budget) {
        apiService.updateBudget(budget.id, budget)
        budgetDao.update(budget)
    }

    override suspend fun deleteBudget(id: String) {
        apiService.deleteBudget(id)
        budgetDao.deleteById(id)
    }
}

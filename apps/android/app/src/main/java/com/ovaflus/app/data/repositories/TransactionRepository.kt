package com.ovaflus.app.data.repositories

import com.ovaflus.app.data.local.dao.TransactionDao
import com.ovaflus.app.data.remote.ApiService
import com.ovaflus.app.domain.models.Transaction
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

interface TransactionRepository {
    suspend fun getTransactions(budgetId: String? = null): List<Transaction>
    fun observeTransactions(): Flow<List<Transaction>>
    suspend fun addTransaction(transaction: Transaction)
    suspend fun deleteTransaction(id: String)
}

class TransactionRepositoryImpl @Inject constructor(
    private val transactionDao: TransactionDao,
    private val apiService: ApiService,
) : TransactionRepository {

    override suspend fun getTransactions(budgetId: String?): List<Transaction> {
        return try {
            val remote = apiService.getTransactions(budgetId)
            transactionDao.insertAll(remote)
            remote
        } catch (e: Exception) {
            if (budgetId != null) {
                transactionDao.getTransactionsByBudget(budgetId)
            } else {
                transactionDao.getAllTransactions()
            }
        }
    }

    override fun observeTransactions(): Flow<List<Transaction>> {
        return transactionDao.observeAllTransactions()
    }

    override suspend fun addTransaction(transaction: Transaction) {
        apiService.createTransaction(transaction)
        transactionDao.insert(transaction)
    }

    override suspend fun deleteTransaction(id: String) {
        apiService.deleteTransaction(id)
        transactionDao.deleteById(id)
    }
}

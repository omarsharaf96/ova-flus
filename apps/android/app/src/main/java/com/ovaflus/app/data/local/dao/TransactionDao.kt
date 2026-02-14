package com.ovaflus.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.ovaflus.app.domain.models.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface TransactionDao {

    @Query("SELECT * FROM transactions ORDER BY date DESC")
    suspend fun getAllTransactions(): List<Transaction>

    @Query("SELECT * FROM transactions ORDER BY date DESC")
    fun observeAllTransactions(): Flow<List<Transaction>>

    @Query("SELECT * FROM transactions WHERE budgetId = :budgetId ORDER BY date DESC")
    suspend fun getTransactionsByBudget(budgetId: String): List<Transaction>

    @Query("SELECT * FROM transactions WHERE budgetId = :budgetId ORDER BY date DESC")
    fun observeTransactionsByBudget(budgetId: String): Flow<List<Transaction>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: Transaction)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(transactions: List<Transaction>)

    @Query("DELETE FROM transactions WHERE id = :id")
    suspend fun deleteById(id: String)
}

package com.ovaflus.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.ovaflus.app.data.local.dao.BudgetDao
import com.ovaflus.app.data.local.dao.TransactionDao
import com.ovaflus.app.domain.models.Budget
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.domain.models.Portfolio
import com.ovaflus.app.domain.models.Transaction
import com.ovaflus.app.domain.models.User

@Database(
    entities = [
        User::class,
        Budget::class,
        Transaction::class,
        Portfolio::class,
        Holding::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun budgetDao(): BudgetDao
    abstract fun transactionDao(): TransactionDao
}

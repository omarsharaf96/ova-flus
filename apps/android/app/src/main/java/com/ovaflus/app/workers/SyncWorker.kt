package com.ovaflus.app.workers

import android.content.Context
import android.util.Log
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.ovaflus.app.data.repositories.BudgetRepository
import com.ovaflus.app.data.repositories.TransactionRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject

@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted workerParams: WorkerParameters,
    private val budgetRepository: BudgetRepository,
    private val transactionRepository: TransactionRepository,
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            Log.i(TAG, "Starting background sync")
            budgetRepository.getBudgets()
            transactionRepository.getTransactions()
            Log.i(TAG, "Background sync completed")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Background sync failed", e)
            if (runAttemptCount < MAX_RETRIES) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }

    companion object {
        private const val TAG = "SyncWorker"
        private const val MAX_RETRIES = 3
        const val WORK_NAME = "ovaflus_sync"
    }
}

package com.ovaflus.app.domain.usecases

import com.ovaflus.app.data.repositories.TransactionRepository
import com.ovaflus.app.domain.models.Transaction
import javax.inject.Inject

class AddTransactionUseCase @Inject constructor(
    private val transactionRepository: TransactionRepository,
) {
    suspend operator fun invoke(transaction: Transaction) {
        transactionRepository.addTransaction(transaction)
    }
}

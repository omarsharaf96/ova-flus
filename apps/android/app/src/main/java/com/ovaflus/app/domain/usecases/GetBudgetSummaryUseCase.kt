package com.ovaflus.app.domain.usecases

import com.ovaflus.app.data.repositories.BudgetRepository
import com.ovaflus.app.domain.models.Budget
import javax.inject.Inject

class GetBudgetSummaryUseCase @Inject constructor(
    private val budgetRepository: BudgetRepository,
) {
    suspend operator fun invoke(): List<Budget> {
        return budgetRepository.getBudgets()
    }
}

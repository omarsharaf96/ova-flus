package com.ovaflus.app.ui.screens.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ovaflus.app.domain.models.Budget
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.domain.models.Transaction
import com.ovaflus.app.domain.usecases.GetBudgetSummaryUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DashboardUiState(
    val userName: String = "",
    val totalBalance: Double = 0.0,
    val budgets: List<Budget> = emptyList(),
    val recentTransactions: List<Transaction> = emptyList(),
    val topHoldings: List<Holding> = emptyList(),
    val portfolioTotalValue: Double = 0.0,
    val portfolioDayChange: Double = 0.0,
    val isLoading: Boolean = true,
    val error: String? = null,
)

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val getBudgetSummaryUseCase: GetBudgetSummaryUseCase,
) : ViewModel() {

    private val _uiState = MutableStateFlow(DashboardUiState())
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()

    init {
        fetchDashboard()
    }

    fun fetchDashboard() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val budgets = getBudgetSummaryUseCase()
                _uiState.value = _uiState.value.copy(
                    budgets = budgets,
                    isLoading = false,
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "An error occurred",
                )
            }
        }
    }
}

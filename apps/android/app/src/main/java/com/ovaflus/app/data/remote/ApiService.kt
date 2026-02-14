package com.ovaflus.app.data.remote

import com.ovaflus.app.domain.models.Budget
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.domain.models.Portfolio
import com.ovaflus.app.domain.models.StockQuote
import com.ovaflus.app.domain.models.Transaction
import com.ovaflus.app.domain.models.User
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

interface ApiService {

    // Auth
    @GET("auth/me")
    suspend fun getCurrentUser(): User

    // Budgets
    @GET("budgets")
    suspend fun getBudgets(): List<Budget>

    @GET("budgets/{id}")
    suspend fun getBudgetById(@Path("id") id: String): Budget

    @POST("budgets")
    suspend fun createBudget(@Body budget: Budget): Budget

    @PUT("budgets/{id}")
    suspend fun updateBudget(@Path("id") id: String, @Body budget: Budget): Budget

    @DELETE("budgets/{id}")
    suspend fun deleteBudget(@Path("id") id: String)

    // Transactions
    @GET("transactions")
    suspend fun getTransactions(@Query("budgetId") budgetId: String? = null): List<Transaction>

    @POST("transactions")
    suspend fun createTransaction(@Body transaction: Transaction): Transaction

    @DELETE("transactions/{id}")
    suspend fun deleteTransaction(@Path("id") id: String)

    // Portfolios
    @GET("portfolios")
    suspend fun getPortfolios(): List<Portfolio>

    @GET("portfolios/{id}")
    suspend fun getPortfolioById(@Path("id") id: String): Portfolio

    @GET("portfolios/{id}/holdings")
    suspend fun getHoldings(@Path("id") portfolioId: String): List<Holding>

    // Stocks
    @GET("stocks/{symbol}/quote")
    suspend fun getStockQuote(@Path("symbol") symbol: String): StockQuote

    @GET("stocks/search")
    suspend fun searchStocks(@Query("q") query: String): List<StockQuote>
}

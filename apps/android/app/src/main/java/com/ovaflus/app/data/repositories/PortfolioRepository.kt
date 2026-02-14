package com.ovaflus.app.data.repositories

import com.ovaflus.app.data.remote.ApiService
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.domain.models.Portfolio
import com.ovaflus.app.domain.models.StockQuote
import javax.inject.Inject

interface PortfolioRepository {
    suspend fun getPortfolios(): List<Portfolio>
    suspend fun getPortfolioById(id: String): Portfolio?
    suspend fun getHoldings(portfolioId: String): List<Holding>
    suspend fun getStockQuote(symbol: String): StockQuote
}

class PortfolioRepositoryImpl @Inject constructor(
    private val apiService: ApiService,
) : PortfolioRepository {

    override suspend fun getPortfolios(): List<Portfolio> {
        return apiService.getPortfolios()
    }

    override suspend fun getPortfolioById(id: String): Portfolio? {
        return apiService.getPortfolioById(id)
    }

    override suspend fun getHoldings(portfolioId: String): List<Holding> {
        return apiService.getHoldings(portfolioId)
    }

    override suspend fun getStockQuote(symbol: String): StockQuote {
        return apiService.getStockQuote(symbol)
    }
}

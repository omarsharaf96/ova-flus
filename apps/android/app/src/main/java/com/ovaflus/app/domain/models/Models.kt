package com.ovaflus.app.domain.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName

@Entity(tableName = "users")
data class User(
    @PrimaryKey val id: String,
    val email: String,
    @SerializedName("display_name") val displayName: String,
    val tier: String = "free",
    @SerializedName("created_at") val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "budgets")
data class Budget(
    @PrimaryKey val id: String,
    @SerializedName("user_id") val userId: String = "",
    val name: String,
    val limit: Double,
    val spent: Double = 0.0,
    val period: String = "monthly",
    val category: String = "",
    @SerializedName("start_date") val startDate: Long = System.currentTimeMillis(),
    @SerializedName("end_date") val endDate: Long = System.currentTimeMillis(),
)

data class BudgetCategory(
    val id: String,
    val name: String,
    val icon: String,
    val color: String,
)

@Entity(tableName = "transactions")
data class Transaction(
    @PrimaryKey val id: String,
    @SerializedName("user_id") val userId: String = "",
    @SerializedName("budget_id") val budgetId: String = "",
    val amount: Double,
    val description: String,
    val category: String,
    val date: Long = System.currentTimeMillis(),
    val type: String = "expense",
    val note: String = "",
)

@Entity(tableName = "portfolios")
data class Portfolio(
    @PrimaryKey val id: String,
    @SerializedName("user_id") val userId: String = "",
    val name: String,
    @SerializedName("total_value") val totalValue: Double = 0.0,
    @SerializedName("day_change") val dayChange: Double = 0.0,
    @SerializedName("day_change_percent") val dayChangePercent: Double = 0.0,
)

@Entity(tableName = "holdings")
data class Holding(
    @PrimaryKey val id: String,
    @SerializedName("portfolio_id") val portfolioId: String = "",
    val symbol: String,
    val shares: Double,
    @SerializedName("avg_cost") val avgCost: Double,
    @SerializedName("current_price") val currentPrice: Double = 0.0,
    @SerializedName("current_value") val currentValue: Double = 0.0,
    @SerializedName("day_change_percent") val dayChangePercent: Double = 0.0,
)

data class StockQuote(
    val symbol: String,
    val price: Double,
    val change: Double,
    @SerializedName("change_percent") val changePercent: Double,
    val open: Double = 0.0,
    val high: Double = 0.0,
    val low: Double = 0.0,
    val volume: Long = 0,
    @SerializedName("market_cap") val marketCap: Long = 0,
    @SerializedName("pe_ratio") val peRatio: Double = 0.0,
    @SerializedName("week_52_high") val week52High: Double = 0.0,
    @SerializedName("week_52_low") val week52Low: Double = 0.0,
)

package com.ovaflus.app.ui.screens.stocks

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.ui.components.HoldingRow
import com.ovaflus.app.ui.navigation.Screen
import com.ovaflus.app.ui.screens.dashboard.DashboardViewModel
import com.ovaflus.app.ui.theme.NegativeRed
import com.ovaflus.app.ui.theme.PositiveGreen
import java.text.NumberFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortfolioScreen(
    navController: NavController,
    viewModel: DashboardViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()
    val currencyFormat = NumberFormat.getCurrencyInstance(Locale.US)

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Portfolio") })
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Total value header
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer,
                    ),
                ) {
                    Column(modifier = Modifier.padding(20.dp)) {
                        Text(
                            text = "Total Portfolio Value",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = currencyFormat.format(uiState.portfolioTotalValue),
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold,
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Row {
                            val changeColor = if (uiState.portfolioDayChange >= 0)
                                PositiveGreen else NegativeRed
                            val prefix = if (uiState.portfolioDayChange >= 0) "+" else ""
                            Text(
                                text = "${prefix}${currencyFormat.format(uiState.portfolioDayChange)} today",
                                style = MaterialTheme.typography.bodyMedium,
                                color = changeColor,
                            )
                        }
                    }
                }
            }

            // Simple bar chart
            item {
                PortfolioBarChart(holdings = uiState.topHoldings)
            }

            // Holdings list
            item {
                Text(
                    text = "Holdings",
                    style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }
            items(uiState.topHoldings) { holding ->
                HoldingRow(holding = holding) {
                    navController.navigate(Screen.StockDetail.createRoute(holding.symbol))
                }
            }

            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

@Composable
private fun PortfolioBarChart(holdings: List<Holding>) {
    if (holdings.isEmpty()) return

    val barColor = MaterialTheme.colorScheme.primary
    val maxValue = holdings.maxOfOrNull { it.currentValue } ?: 1.0

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(150.dp)
            .padding(vertical = 8.dp),
    ) {
        val barWidth = size.width / (holdings.size * 2f)
        holdings.forEachIndexed { index, holding ->
            val barHeight = (holding.currentValue / maxValue * size.height).toFloat()
            drawRect(
                color = barColor,
                topLeft = Offset(
                    x = index * barWidth * 2 + barWidth / 2,
                    y = size.height - barHeight,
                ),
                size = Size(barWidth, barHeight),
            )
        }
    }
}

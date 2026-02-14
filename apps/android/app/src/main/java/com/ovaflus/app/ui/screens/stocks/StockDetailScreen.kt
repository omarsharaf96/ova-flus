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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.ovaflus.app.ui.theme.NegativeRed
import com.ovaflus.app.ui.theme.PositiveGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StockDetailScreen(
    symbol: String,
    navController: NavController,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(symbol) },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Price header
            item {
                Column {
                    Text(
                        text = symbol,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "$0.00",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = "+$0.00 (0.00%)",
                        style = MaterialTheme.typography.bodyLarge,
                        color = PositiveGreen,
                    )
                }
            }

            // Candlestick chart placeholder
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    CandlestickChartPlaceholder()
                }
            }

            // Key stats
            item {
                Text(
                    text = "Key Statistics",
                    style = MaterialTheme.typography.titleLarge,
                )
            }
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        StatRow("Open", "$0.00")
                        StatRow("High", "$0.00")
                        StatRow("Low", "$0.00")
                        StatRow("Volume", "0")
                        StatRow("Market Cap", "$0")
                        StatRow("P/E Ratio", "0.00")
                        StatRow("52W High", "$0.00")
                        StatRow("52W Low", "$0.00")
                    }
                }
            }

            // News section
            item {
                Text(
                    text = "Related News",
                    style = MaterialTheme.typography.titleLarge,
                )
            }
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "No news available",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

@Composable
private fun CandlestickChartPlaceholder() {
    val lineColor = MaterialTheme.colorScheme.primary

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .padding(16.dp),
    ) {
        // Placeholder chart lines
        val points = listOf(0.3f, 0.5f, 0.4f, 0.6f, 0.55f, 0.7f, 0.65f, 0.8f)
        val stepX = size.width / (points.size - 1)

        for (i in 0 until points.size - 1) {
            drawLine(
                color = lineColor,
                start = Offset(i * stepX, size.height * (1 - points[i])),
                end = Offset((i + 1) * stepX, size.height * (1 - points[i + 1])),
                strokeWidth = 3f,
            )
        }
    }
}

@Composable
private fun StatRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
        )
    }
}

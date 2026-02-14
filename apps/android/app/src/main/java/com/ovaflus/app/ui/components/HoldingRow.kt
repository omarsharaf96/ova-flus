package com.ovaflus.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ovaflus.app.domain.models.Holding
import com.ovaflus.app.ui.theme.NegativeRed
import com.ovaflus.app.ui.theme.PositiveGreen
import java.text.NumberFormat
import java.util.Locale

@Composable
fun HoldingRow(
    holding: Holding,
    onClick: () -> Unit,
) {
    val currencyFormat = NumberFormat.getCurrencyInstance(Locale.US)
    val changeColor = if (holding.dayChangePercent >= 0) PositiveGreen else NegativeRed
    val changePrefix = if (holding.dayChangePercent >= 0) "+" else ""

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = holding.symbol,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = "${holding.shares} shares",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = currencyFormat.format(holding.currentValue),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = "${changePrefix}${String.format("%.2f", holding.dayChangePercent)}%",
                    style = MaterialTheme.typography.bodySmall,
                    color = changeColor,
                )
            }
        }
    }
}

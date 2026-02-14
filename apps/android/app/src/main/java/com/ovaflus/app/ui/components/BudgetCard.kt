package com.ovaflus.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ovaflus.app.domain.models.Budget
import com.ovaflus.app.ui.theme.NegativeRed
import com.ovaflus.app.ui.theme.PositiveGreen
import com.ovaflus.app.ui.theme.WarningOrange
import java.text.NumberFormat
import java.util.Locale

@Composable
fun BudgetCard(
    budget: Budget,
    onClick: () -> Unit,
) {
    val currencyFormat = NumberFormat.getCurrencyInstance(Locale.US)
    val progress = if (budget.limit > 0) (budget.spent / budget.limit).toFloat() else 0f
    val progressColor = when {
        progress >= 1f -> NegativeRed
        progress >= 0.8f -> WarningOrange
        else -> PositiveGreen
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = budget.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = "${currencyFormat.format(budget.spent)} / ${currencyFormat.format(budget.limit)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { progress.coerceIn(0f, 1f) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = progressColor,
                trackColor = MaterialTheme.colorScheme.surfaceVariant,
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "${(progress * 100).toInt()}% used",
                style = MaterialTheme.typography.bodySmall,
                color = progressColor,
            )
        }
    }
}

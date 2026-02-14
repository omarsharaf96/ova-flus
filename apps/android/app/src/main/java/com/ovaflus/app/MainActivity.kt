package com.ovaflus.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.navigation.compose.rememberNavController
import com.ovaflus.app.ui.navigation.OvaFlusNavHost
import com.ovaflus.app.ui.theme.OvaFlusTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            OvaFlusTheme {
                val navController = rememberNavController()
                OvaFlusNavHost(navController = navController)
            }
        }
    }
}

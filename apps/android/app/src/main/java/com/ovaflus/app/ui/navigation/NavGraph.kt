package com.ovaflus.app.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.navArgument
import com.ovaflus.app.ui.screens.auth.LoginScreen
import com.ovaflus.app.ui.screens.budget.BudgetScreen
import com.ovaflus.app.ui.screens.dashboard.DashboardScreen
import com.ovaflus.app.ui.screens.profile.ProfileScreen
import com.ovaflus.app.ui.screens.profile.SettingsScreen
import com.ovaflus.app.ui.screens.stocks.PortfolioScreen
import com.ovaflus.app.ui.screens.stocks.StockDetailScreen

sealed class Screen(val route: String) {
    // Auth routes
    data object Login : Screen("auth/login")
    data object Register : Screen("auth/register")

    // Main routes
    data object Dashboard : Screen("main/dashboard")
    data object Budget : Screen("main/budget")
    data object BudgetDetail : Screen("main/budget/{id}") {
        fun createRoute(id: String) = "main/budget/$id"
    }
    data object Stocks : Screen("main/stocks")
    data object PortfolioDetail : Screen("main/portfolio/{id}") {
        fun createRoute(id: String) = "main/portfolio/$id"
    }
    data object StockDetail : Screen("main/stock/{symbol}") {
        fun createRoute(symbol: String) = "main/stock/$symbol"
    }
    data object Watchlist : Screen("main/watchlist")
    data object Profile : Screen("main/profile")
    data object Settings : Screen("main/settings")
}

data class BottomNavItem(
    val label: String,
    val icon: ImageVector,
    val route: String,
)

val bottomNavItems = listOf(
    BottomNavItem("Dashboard", Icons.Default.Home, Screen.Dashboard.route),
    BottomNavItem("Budget", Icons.Default.List, Screen.Budget.route),
    BottomNavItem("Stocks", Icons.Default.ShowChart, Screen.Stocks.route),
    BottomNavItem("Profile", Icons.Default.AccountCircle, Screen.Profile.route),
)

@Composable
fun OvaFlusNavHost(navController: NavHostController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val showBottomBar = currentRoute in bottomNavItems.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        NavigationBarItem(
                            icon = { Icon(item.icon, contentDescription = item.label) },
                            label = { Text(item.label) },
                            selected = currentRoute == item.route,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(Screen.Dashboard.route) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Login.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            // Auth
            composable(Screen.Login.route) {
                LoginScreen(navController = navController)
            }
            composable(Screen.Register.route) {
                // TODO: RegisterScreen
            }

            // Main
            composable(Screen.Dashboard.route) {
                DashboardScreen(navController = navController)
            }
            composable(Screen.Budget.route) {
                BudgetScreen(navController = navController)
            }
            composable(
                route = Screen.BudgetDetail.route,
                arguments = listOf(navArgument("id") { type = NavType.StringType })
            ) {
                // TODO: BudgetDetailScreen
            }
            composable(Screen.Stocks.route) {
                PortfolioScreen(navController = navController)
            }
            composable(
                route = Screen.PortfolioDetail.route,
                arguments = listOf(navArgument("id") { type = NavType.StringType })
            ) {
                // TODO: PortfolioDetailScreen
            }
            composable(
                route = Screen.StockDetail.route,
                arguments = listOf(navArgument("symbol") { type = NavType.StringType })
            ) { backStackEntry ->
                val symbol = backStackEntry.arguments?.getString("symbol") ?: ""
                StockDetailScreen(symbol = symbol, navController = navController)
            }
            composable(Screen.Watchlist.route) {
                // TODO: WatchlistScreen
            }
            composable(Screen.Profile.route) {
                ProfileScreen(navController = navController)
            }
            composable(Screen.Settings.route) {
                SettingsScreen(navController = navController)
            }
        }
    }
}

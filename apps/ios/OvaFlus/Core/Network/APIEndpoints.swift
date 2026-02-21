import Foundation

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

enum APIEndpoint {
    // Auth
    case signIn(email: String, password: String)
    case signUp(email: String, password: String, name: String)
    case refreshToken(refreshToken: String)

    // Budgets
    case getBudgets
    case createBudget(Budget)
    case updateBudget(Budget)
    case deleteBudget(id: String)

    // Transactions
    case getTransactions(budgetId: String)
    case getRecentTransactions
    case createTransaction(Transaction)
    case deleteTransaction(id: String)

    // Portfolio
    case getPortfolio
    case getStockQuote(symbol: String)
    case getWatchlist
    case addToWatchlist(symbol: String)
    case removeFromWatchlist(symbol: String)
    case getStockNews(symbol: String)

    // Stock Search
    case searchStocks(query: String)

    // Portfolio Holdings
    case addHolding(symbol: String, shares: Double, averageCost: Double, purchaseDate: Date)
    case removeHolding(id: String)

    // User
    case getProfile
    case updateProfile(User)

    // Plaid
    case plaidCreateLinkToken
    case plaidExchangeToken(publicToken: String, institutionId: String, institutionName: String, accounts: [[String: String]])
    case plaidGetAccounts
    case plaidSyncTransactions
    case plaidUnlinkAccount(itemId: String)

    var path: String {
        switch self {
        case .signIn: return "/auth/signin"
        case .signUp: return "/auth/signup"
        case .refreshToken: return "/auth/refresh"
        case .getBudgets, .createBudget: return "/budgets"
        case .updateBudget(let budget): return "/budgets/\(budget.id)"
        case .deleteBudget(let id): return "/budgets/\(id)"
        case .getTransactions(let budgetId): return "/budgets/\(budgetId)/transactions"
        case .getRecentTransactions: return "/transactions/recent"
        case .createTransaction: return "/transactions"
        case .deleteTransaction(let id): return "/transactions/\(id)"
        case .getPortfolio: return "/portfolio"
        case .getStockQuote(let symbol): return "/stocks/\(symbol)"
        case .getWatchlist: return "/watchlist"
        case .addToWatchlist, .removeFromWatchlist: return "/watchlist"
        case .getStockNews(let symbol): return "/stocks/\(symbol)/news"
        case .searchStocks(let query): return "/stocks/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        case .addHolding: return "/portfolio/holdings"
        case .removeHolding(let id): return "/portfolio/holdings/\(id)"
        case .getProfile, .updateProfile: return "/profile"
        case .plaidCreateLinkToken: return "/plaid/link-token"
        case .plaidExchangeToken: return "/plaid/exchange-token"
        case .plaidGetAccounts: return "/plaid/accounts"
        case .plaidSyncTransactions: return "/plaid/sync"
        case .plaidUnlinkAccount(let itemId): return "/plaid/accounts/\(itemId)"
        }
    }

    var method: String {
        switch self {
        case .signIn, .signUp, .refreshToken, .createBudget, .createTransaction, .addToWatchlist, .addHolding:
            return "POST"
        case .updateBudget, .updateProfile:
            return "PUT"
        case .deleteBudget, .deleteTransaction, .removeFromWatchlist, .removeHolding, .plaidUnlinkAccount:
            return "DELETE"
        case .plaidCreateLinkToken, .plaidExchangeToken, .plaidSyncTransactions:
            return "POST"
        default:
            return "GET"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .signIn(let email, let password):
            return AnyEncodable(["email": email, "password": password])
        case .signUp(let email, let password, let name):
            return AnyEncodable(["email": email, "password": password, "name": name])
        case .refreshToken(let refreshToken):
            return AnyEncodable(["refresh_token": refreshToken])
        case .createBudget(let budget), .updateBudget(let budget):
            return AnyEncodable(budget)
        case .createTransaction(let transaction):
            return AnyEncodable(transaction)
        case .addToWatchlist(let symbol):
            return AnyEncodable(["symbol": symbol])
        case .updateProfile(let user):
            return AnyEncodable(user)
        case .addHolding(let symbol, let shares, let averageCost, let purchaseDate):
            let formatter = ISO8601DateFormatter()
            return AnyEncodable([
                "symbol": AnyEncodable(symbol),
                "shares": AnyEncodable(shares),
                "averageCost": AnyEncodable(averageCost),
                "purchaseDate": AnyEncodable(formatter.string(from: purchaseDate))
            ])
        case .plaidExchangeToken(let publicToken, let institutionId, let institutionName, let accounts):
            return AnyEncodable([
                "public_token": AnyEncodable(publicToken),
                "institution_id": AnyEncodable(institutionId),
                "institution_name": AnyEncodable(institutionName),
                "accounts": AnyEncodable(accounts)
            ])
        default:
            return nil
        }
    }
}

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

    // User
    case getProfile
    case updateProfile(User)

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
        case .getProfile, .updateProfile: return "/profile"
        }
    }

    var method: String {
        switch self {
        case .signIn, .signUp, .refreshToken, .createBudget, .createTransaction, .addToWatchlist:
            return "POST"
        case .updateBudget, .updateProfile:
            return "PUT"
        case .deleteBudget, .deleteTransaction, .removeFromWatchlist:
            return "DELETE"
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
            return AnyEncodable(["refreshToken": refreshToken])
        case .createBudget(let budget), .updateBudget(let budget):
            return AnyEncodable(budget)
        case .createTransaction(let transaction):
            return AnyEncodable(transaction)
        case .addToWatchlist(let symbol):
            return AnyEncodable(["symbol": symbol])
        case .updateProfile(let user):
            return AnyEncodable(user)
        default:
            return nil
        }
    }
}

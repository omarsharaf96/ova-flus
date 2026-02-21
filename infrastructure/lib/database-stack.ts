import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

export interface DatabaseTables {
  users: dynamodb.Table;
  budgets: dynamodb.Table;
  transactions: dynamodb.Table;
  portfolio: dynamodb.Table;
  watchlist: dynamodb.Table;
  goals: dynamodb.Table;
  plaidItems: dynamodb.Table;
}

export class DatabaseStack extends cdk.Stack {
  public readonly tables: DatabaseTables;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Users table — PK: user_id, GSI on email
    const users = new dynamodb.Table(this, 'UsersTable', {
      tableName: 'ovaflus-users',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    users.addGlobalSecondaryIndex({
      indexName: 'email-index',
      partitionKey: { name: 'email', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Budgets table — PK: user_id, SK: budget_id
    const budgets = new dynamodb.Table(this, 'BudgetsTable', {
      tableName: 'ovaflus-budgets',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'budget_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Transactions table — PK: user_id, SK: transaction_id, GSI on budget_id
    const transactions = new dynamodb.Table(this, 'TransactionsTable', {
      tableName: 'ovaflus-transactions',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'transaction_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    transactions.addGlobalSecondaryIndex({
      indexName: 'budget_id-index',
      partitionKey: { name: 'budget_id', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Portfolio table — PK: user_id, SK: holding_id
    const portfolio = new dynamodb.Table(this, 'PortfolioTable', {
      tableName: 'ovaflus-portfolio',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'holding_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Watchlist table — PK: user_id, SK: symbol
    const watchlist = new dynamodb.Table(this, 'WatchlistTable', {
      tableName: 'ovaflus-watchlist',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'symbol', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Goals table — PK: user_id, SK: goal_id
    const goals = new dynamodb.Table(this, 'GoalsTable', {
      tableName: 'ovaflus-goals',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'goal_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Plaid items table — PK: user_id, SK: item_id
    const plaidItems = new dynamodb.Table(this, 'PlaidItemsTable', {
      tableName: 'ovaflus-plaid-items',
      partitionKey: { name: 'user_id', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'item_id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    this.tables = { users, budgets, transactions, portfolio, watchlist, goals, plaidItems };
  }
}

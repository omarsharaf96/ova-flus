# Flus Infrastructure (AWS CDK)

AWS CDK TypeScript project that provisions the Flus backend infrastructure: DynamoDB tables, Lambda function, API Gateway, SSM parameters, and S3 artifact bucket.

## Prerequisites

- Node.js 20+
- AWS CLI configured (`aws configure`)
- npm install in this directory

```bash
cd infrastructure
npm install
```

## Stacks

| Stack | Resources |
|-------|-----------|
| **FlusDatabaseStack** | 7 DynamoDB tables (users, budgets, transactions, portfolio, watchlist, goals, plaid-items) |
| **FlusBackendStack** | Lambda (ARM64, provided.al2023), HTTP API Gateway, S3 artifact bucket, SSM parameters |

## First Deploy

Bootstrap CDK (once per AWS account/region):

```bash
npx cdk bootstrap
```

Deploy all stacks with secrets passed via context:

```bash
npx cdk deploy --all \
  -c jwtSecret=xxx \
  -c plaidClientId=xxx \
  -c plaidSecret=xxx \
  -c finnhubApiKey=xxx
```

## Useful Commands

```bash
npx cdk diff          # Preview changes
npx cdk synth         # Emit CloudFormation template
npx cdk deploy --all  # Deploy all stacks
npx cdk destroy --all # Tear down all stacks
```

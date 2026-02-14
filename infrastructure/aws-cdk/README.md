# OvaFlus AWS CDK Infrastructure

Infrastructure as Code for the OvaFlus finance platform using AWS CDK (TypeScript).

## Architecture Overview

The infrastructure is organized into 7 stacks with explicit dependency ordering:

| Stack | Resources |
|-------|-----------|
| **VPC** | VPC (3 AZs), public/private/isolated subnets, NAT Gateway, flow logs |
| **Security** | Cognito User Pool + Identity Pool, KMS encryption key, WAF WebACL |
| **Database** | RDS PostgreSQL 15 (Multi-AZ), DynamoDB tables, ElastiCache Redis |
| **Storage** | S3 buckets (receipts, reports, backups, web assets), CloudFront CDN |
| **ECS** | Fargate cluster, 7 microservices, ALB with HTTPS, auto-scaling |
| **API** | API Gateway (REST), AppSync (GraphQL), Lambda (OCR), SNS, SQS |
| **Monitoring** | CloudWatch dashboard + alarms, X-Ray tracing, CloudTrail |

### Stack Dependencies

```
VPC --> Database --> ECS --> API
Security ----------> ECS
                     ECS --> Monitoring
```

## Prerequisites

1. **AWS CLI** configured with credentials (`aws configure`)
2. **Node.js** >= 18.x
3. **AWS CDK CLI** installed globally or via npx
4. **CDK Bootstrap** run once per account/region:

```bash
npx cdk bootstrap aws://ACCOUNT_ID/us-east-1
```

## Getting Started

```bash
# Install dependencies
npm install

# Synthesize CloudFormation templates
npm run synth

# Preview changes
npm run diff

# Deploy all stacks
npm run deploy

# Deploy a specific stack
npx cdk deploy OvaFlus-VPC
```

## Teardown

```bash
# Destroy all stacks (will prompt for confirmation)
npm run destroy
```

**Note:** Stacks with `removalPolicy: RETAIN` (RDS, Cognito, KMS, receipts/backups S3 buckets) will not be deleted automatically. You must manually delete these resources from the AWS Console.

## Microservices

All 7 services run on ECS Fargate (0.5 vCPU, 1 GB RAM each):

| Service | Port | Path |
|---------|------|------|
| auth-service | 3001 | /api/auth/* |
| budget-service | 3002 | /api/budgets/* |
| transaction-service | 3003 | /api/transactions/* |
| portfolio-service | 3004 | /api/portfolio/* |
| market-data-service | 3005 | /api/market/* |
| analytics-service | 3006 | /api/analytics/* |
| notification-service | 3007 | /api/notifications/* |

Auto-scaling is configured to scale out when CPU exceeds 70%.

## Cost Estimation (Development)

Approximate monthly costs for a dev environment (us-east-1):

- **ECS Fargate** (7 services, 0.5 vCPU / 1 GB): ~$150/month
- **RDS PostgreSQL** (db.t3.medium, Multi-AZ): ~$70/month
- **NAT Gateway**: ~$35/month
- **ALB**: ~$20/month
- **ElastiCache Redis** (cache.t3.micro): ~$15/month
- **CloudFront**: ~$5/month (low traffic)
- **DynamoDB** (on-demand): ~$5/month (low traffic)
- **S3 / CloudWatch / others**: ~$10/month

**Estimated total: ~$310/month** for development.

To reduce costs:
- Use single-AZ RDS for dev
- Reduce NAT gateways to 0 (use VPC endpoints instead)
- Scale ECS tasks to 0 when not in use

## Multi-Region Setup

To deploy to additional regions:

1. Bootstrap the target region: `npx cdk bootstrap aws://ACCOUNT_ID/eu-west-1`
2. Set the environment variable: `export CDK_DEFAULT_REGION=eu-west-1`
3. Deploy: `npm run deploy`

For production multi-region, consider:
- RDS read replicas in secondary regions
- DynamoDB global tables
- CloudFront with multi-origin failover
- Route 53 latency-based routing

## Project Structure

```
infrastructure/aws-cdk/
  bin/
    app.ts                    # CDK app entry point
  lib/
    stacks/
      vpc-stack.ts            # Networking
      security-stack.ts       # Auth & WAF
      database-stack.ts       # RDS, DynamoDB, Redis
      storage-stack.ts        # S3, CloudFront
      ecs-stack.ts            # ECS Fargate, ALB
      api-stack.ts            # API Gateway, AppSync, Lambda
      monitoring-stack.ts     # CloudWatch, X-Ray, CloudTrail
    constructs/
      microservice.ts         # Reusable Fargate service construct
  cdk.json
  tsconfig.json
  package.json
```

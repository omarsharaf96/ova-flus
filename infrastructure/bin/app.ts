#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { DatabaseStack } from '../lib/database-stack';
import { BackendStack } from '../lib/backend-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION ?? 'us-east-1',
};

const tags = {
  Project: 'flus',
  Environment: process.env.ENVIRONMENT ?? 'prod',
  ManagedBy: 'cdk',
};

const dbStack = new DatabaseStack(app, 'FlusDatabaseStack', { env, tags });

new BackendStack(app, 'FlusBackendStack', {
  env,
  tags,
  tables: dbStack.tables,
});

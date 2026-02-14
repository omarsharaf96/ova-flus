#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { VpcStack } from '../lib/stacks/vpc-stack';
import { SecurityStack } from '../lib/stacks/security-stack';
import { DatabaseStack } from '../lib/stacks/database-stack';
import { StorageStack } from '../lib/stacks/storage-stack';
import { EcsStack } from '../lib/stacks/ecs-stack';
import { ApiStack } from '../lib/stacks/api-stack';
import { MonitoringStack } from '../lib/stacks/monitoring-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

const vpcStack = new VpcStack(app, 'OvaFlus-VPC', { env });
const securityStack = new SecurityStack(app, 'OvaFlus-Security', { env });
const databaseStack = new DatabaseStack(app, 'OvaFlus-Database', { env, vpc: vpcStack.vpc });
const storageStack = new StorageStack(app, 'OvaFlus-Storage', { env });
const ecsStack = new EcsStack(app, 'OvaFlus-ECS', {
  env,
  vpc: vpcStack.vpc,
  dbSecret: databaseStack.dbSecret,
  userPool: securityStack.userPool,
});
const apiStack = new ApiStack(app, 'OvaFlus-API', { env, ecsCluster: ecsStack.cluster });
new MonitoringStack(app, 'OvaFlus-Monitoring', { env, ecsCluster: ecsStack.cluster });

// Stack dependencies
databaseStack.addDependency(vpcStack);
ecsStack.addDependency(databaseStack);
ecsStack.addDependency(securityStack);
apiStack.addDependency(ecsStack);

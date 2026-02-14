import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';
import { MicroserviceConstruct } from '../constructs/microservice';

export interface EcsStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  dbSecret: secretsmanager.ISecret;
  userPool: cognito.UserPool;
}

const SERVICES = [
  { name: 'auth-service', port: 3001, path: '/api/auth/*', priority: 1 },
  { name: 'budget-service', port: 3002, path: '/api/budgets/*', priority: 2 },
  { name: 'transaction-service', port: 3003, path: '/api/transactions/*', priority: 3 },
  { name: 'portfolio-service', port: 3004, path: '/api/portfolio/*', priority: 4 },
  { name: 'market-data-service', port: 3005, path: '/api/market/*', priority: 5 },
  { name: 'analytics-service', port: 3006, path: '/api/analytics/*', priority: 6 },
  { name: 'notification-service', port: 3007, path: '/api/notifications/*', priority: 7 },
  { name: 'plaid-service', port: 3008, path: '/api/plaid/*', priority: 8 },
];

export class EcsStack extends cdk.Stack {
  public readonly cluster: ecs.Cluster;
  public readonly alb: elbv2.ApplicationLoadBalancer;
  public readonly services: Map<string, MicroserviceConstruct> = new Map();

  constructor(scope: Construct, id: string, props: EcsStackProps) {
    super(scope, id, props);

    const { vpc, dbSecret, userPool } = props;

    // ECS Cluster
    this.cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: 'ovaflus-cluster',
      vpc,
      containerInsights: false,
    });

    // ECS Security Group
    const ecsSecurityGroup = new ec2.SecurityGroup(this, 'EcsSecurityGroup', {
      vpc,
      description: 'Security group for ECS services',
      allowAllOutbound: true,
    });

    // ALB Security Group
    const albSecurityGroup = new ec2.SecurityGroup(this, 'AlbSecurityGroup', {
      vpc,
      description: 'Security group for ALB',
      allowAllOutbound: true,
    });
    albSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'Allow HTTPS');
    albSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'Allow HTTP for redirect');

    // Allow ALB to reach ECS
    ecsSecurityGroup.addIngressRule(albSecurityGroup, ec2.Port.tcpRange(3001, 3008), 'Allow ALB to ECS');

    // Application Load Balancer
    this.alb = new elbv2.ApplicationLoadBalancer(this, 'Alb', {
      vpc,
      internetFacing: true,
      securityGroup: albSecurityGroup,
      loadBalancerName: 'ovaflus-alb',
    });

    // HTTP listener (redirect to HTTPS)
    this.alb.addListener('HttpListener', {
      port: 80,
      defaultAction: elbv2.ListenerAction.redirect({
        port: '443',
        protocol: 'HTTPS',
        statusCode: 'HTTP_301',
      }),
    });

    // HTTPS listener (using default cert for now)
    const httpsListener = this.alb.addListener('HttpsListener', {
      port: 443,
      protocol: elbv2.ApplicationProtocol.HTTPS,
      defaultAction: elbv2.ListenerAction.fixedResponse(404, {
        contentType: 'application/json',
        messageBody: JSON.stringify({ error: 'Not Found' }),
      }),
    });

    // Shared environment variables
    const sharedEnv: Record<string, string> = {
      AWS_REGION: this.region,
      COGNITO_USER_POOL_ID: userPool.userPoolId,
      DB_SECRET_ARN: dbSecret.secretArn,
    };

    // Create services
    for (const svc of SERVICES) {
      const microservice = new MicroserviceConstruct(this, svc.name, {
        cluster: this.cluster,
        serviceName: svc.name,
        port: svc.port,
        cpu: 256,
        memoryLimitMiB: 512,
        listener: httpsListener,
        priority: svc.priority,
        pathPattern: svc.path,
        securityGroup: ecsSecurityGroup,
        environment: sharedEnv,
      });

      // Grant DB secret read
      dbSecret.grantRead(microservice.service.taskDefinition.taskRole);

      this.services.set(svc.name, microservice);
    }

    // Inject Plaid secrets into plaid-service
    const plaidSecret = secretsmanager.Secret.fromSecretNameV2(this, 'PlaidSecret', 'ovaflus/plaid');
    const plaidMicroservice = this.services.get('plaid-service');
    if (plaidMicroservice) {
      plaidSecret.grantRead(plaidMicroservice.service.taskDefinition.taskRole);
    }

    // Outputs
    new cdk.CfnOutput(this, 'AlbDnsName', { value: this.alb.loadBalancerDnsName });
    new cdk.CfnOutput(this, 'ClusterName', { value: this.cluster.clusterName });
  }
}

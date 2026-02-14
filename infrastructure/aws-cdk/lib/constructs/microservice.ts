import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';

export interface MicroserviceProps {
  cluster: ecs.Cluster;
  serviceName: string;
  port: number;
  cpu?: number;
  memoryLimitMiB?: number;
  desiredCount?: number;
  environment?: Record<string, string>;
  listener: elbv2.ApplicationListener;
  priority: number;
  pathPattern: string;
  securityGroup: ec2.SecurityGroup;
}

export class MicroserviceConstruct extends Construct {
  public readonly service: ecs.FargateService;
  public readonly repository: ecr.Repository;
  public readonly logGroup: logs.LogGroup;
  public readonly targetGroup: elbv2.ApplicationTargetGroup;

  constructor(scope: Construct, id: string, props: MicroserviceProps) {
    super(scope, id);

    const {
      cluster,
      serviceName,
      port,
      cpu = 512,
      memoryLimitMiB = 1024,
      desiredCount = 1,
      environment = {},
      listener,
      priority,
      pathPattern,
      securityGroup,
    } = props;

    // ECR Repository
    this.repository = new ecr.Repository(this, 'Repository', {
      repositoryName: `ovaflus/${serviceName}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      lifecycleRules: [
        {
          maxImageCount: 10,
          description: 'Keep last 10 images',
        },
      ],
    });

    // Log Group
    this.logGroup = new logs.LogGroup(this, 'LogGroup', {
      logGroupName: `/ovaflus/${serviceName}`,
      retention: logs.RetentionDays.THREE_DAYS,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Task Definition
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDef', {
      cpu,
      memoryLimitMiB,
      family: `ovaflus-${serviceName}`,
    });

    taskDefinition.addContainer('Container', {
      image: ecs.ContainerImage.fromEcrRepository(this.repository, 'latest'),
      portMappings: [{ containerPort: port }],
      environment: {
        SERVICE_NAME: serviceName,
        PORT: port.toString(),
        NODE_ENV: 'production',
        ...environment,
      },
      logging: ecs.LogDrivers.awsLogs({
        logGroup: this.logGroup,
        streamPrefix: serviceName,
      }),
      healthCheck: {
        command: ['CMD-SHELL', `curl -f http://localhost:${port}/health || exit 1`],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    // Fargate Service
    this.service = new ecs.FargateService(this, 'Service', {
      cluster,
      taskDefinition,
      desiredCount,
      securityGroups: [securityGroup],
      assignPublicIp: true,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
    });

    // Target Group
    this.targetGroup = new elbv2.ApplicationTargetGroup(this, 'TargetGroup', {
      vpc: cluster.vpc,
      port,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      healthCheck: {
        path: '/health',
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
      },
      targets: [this.service],
    });

    // Listener Rule
    new elbv2.ApplicationListenerRule(this, 'ListenerRule', {
      listener,
      priority,
      conditions: [elbv2.ListenerCondition.pathPatterns([pathPattern])],
      targetGroups: [this.targetGroup],
    });

    // Auto-scaling
    const scaling = this.service.autoScaleTaskCount({
      minCapacity: 0,
      maxCapacity: 2,
    });

    scaling.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });
  }
}

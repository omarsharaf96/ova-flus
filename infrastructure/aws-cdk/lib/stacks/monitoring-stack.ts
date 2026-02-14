import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as xray from 'aws-cdk-lib/aws-xray';
import { Construct } from 'constructs';

export interface MonitoringStackProps extends cdk.StackProps {
  ecsCluster: ecs.Cluster;
}

export class MonitoringStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: MonitoringStackProps) {
    super(scope, id, props);

    const { ecsCluster } = props;

    // SNS Topic for alarms
    const alarmTopic = new sns.Topic(this, 'AlarmTopic', {
      topicName: 'ovaflus-alarms',
      displayName: 'OvaFlus Monitoring Alarms',
    });

    // CloudWatch Dashboard
    const dashboard = new cloudwatch.Dashboard(this, 'Dashboard', {
      dashboardName: 'OvaFlus-Dashboard',
    });

    // ECS CPU Utilization Widget
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS CPU Utilization',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'CPUUtilization',
            dimensionsMap: { ClusterName: ecsCluster.clusterName },
            statistic: 'Average',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      }),
      new cloudwatch.GraphWidget({
        title: 'ECS Memory Utilization',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ECS',
            metricName: 'MemoryUtilization',
            dimensionsMap: { ClusterName: ecsCluster.clusterName },
            statistic: 'Average',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      })
    );

    // ALB Metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ALB Request Count',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ApplicationELB',
            metricName: 'RequestCount',
            dimensionsMap: { LoadBalancer: 'ovaflus-alb' },
            statistic: 'Sum',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      }),
      new cloudwatch.GraphWidget({
        title: 'ALB Target Response Time',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ApplicationELB',
            metricName: 'TargetResponseTime',
            dimensionsMap: { LoadBalancer: 'ovaflus-alb' },
            statistic: 'Average',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      })
    );

    // RDS Metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'RDS Database Connections',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RDS',
            metricName: 'DatabaseConnections',
            dimensionsMap: { DBInstanceIdentifier: 'ovaflus' },
            statistic: 'Average',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      }),
      new cloudwatch.GraphWidget({
        title: 'Error Rates (5xx)',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/ApplicationELB',
            metricName: 'HTTPCode_Target_5XX_Count',
            dimensionsMap: { LoadBalancer: 'ovaflus-alb' },
            statistic: 'Sum',
            period: cdk.Duration.minutes(5),
          }),
        ],
        width: 12,
      })
    );

    // Alarm: CPU > 80%
    const cpuAlarm = new cloudwatch.Alarm(this, 'HighCpuAlarm', {
      alarmName: 'OvaFlus-HighCPU',
      alarmDescription: 'ECS cluster CPU utilization exceeds 80%',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ECS',
        metricName: 'CPUUtilization',
        dimensionsMap: { ClusterName: ecsCluster.clusterName },
        statistic: 'Average',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 80,
      evaluationPeriods: 3,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    cpuAlarm.addAlarmAction({ bind: () => ({ alarmActionArn: alarmTopic.topicArn }) });

    // Alarm: 5xx errors > 10/min
    const errorAlarm = new cloudwatch.Alarm(this, 'High5xxAlarm', {
      alarmName: 'OvaFlus-High5xxErrors',
      alarmDescription: '5xx error rate exceeds 10 per minute',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/ApplicationELB',
        metricName: 'HTTPCode_Target_5XX_Count',
        dimensionsMap: { LoadBalancer: 'ovaflus-alb' },
        statistic: 'Sum',
        period: cdk.Duration.minutes(1),
      }),
      threshold: 10,
      evaluationPeriods: 1,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    errorAlarm.addAlarmAction({ bind: () => ({ alarmActionArn: alarmTopic.topicArn }) });

    // Alarm: RDS Free Storage < 20%
    const storageAlarm = new cloudwatch.Alarm(this, 'LowStorageAlarm', {
      alarmName: 'OvaFlus-LowRDSStorage',
      alarmDescription: 'RDS free storage space below 20%',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/RDS',
        metricName: 'FreeStorageSpace',
        dimensionsMap: { DBInstanceIdentifier: 'ovaflus' },
        statistic: 'Average',
        period: cdk.Duration.minutes(5),
      }),
      threshold: 10737418240, // 10 GB (20% of 50 GB)
      evaluationPeriods: 1,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });
    storageAlarm.addAlarmAction({ bind: () => ({ alarmActionArn: alarmTopic.topicArn }) });

    // X-Ray Tracing - sampling rule
    new xray.CfnSamplingRule(this, 'SamplingRule', {
      samplingRule: {
        ruleName: 'OvaFlus-Default',
        priority: 1000,
        fixedRate: 0.05,
        reservoirSize: 1,
        serviceName: '*',
        serviceType: '*',
        host: '*',
        httpMethod: '*',
        urlPath: '*',
        resourceArn: '*',
        version: 1,
      },
    });

    // Outputs
    new cdk.CfnOutput(this, 'DashboardUrl', {
      value: `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=OvaFlus-Dashboard`,
    });
    new cdk.CfnOutput(this, 'AlarmTopicArn', { value: alarmTopic.topicArn });
  }
}

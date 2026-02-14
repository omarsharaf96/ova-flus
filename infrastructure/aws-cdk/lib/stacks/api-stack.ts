import * as cdk from 'aws-cdk-lib';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface ApiStackProps extends cdk.StackProps {
  ecsCluster: ecs.Cluster;
}

export class ApiStack extends cdk.Stack {
  public readonly restApi: apigateway.RestApi;
  public readonly graphqlApi: appsync.CfnGraphQLApi;
  public readonly notificationTopic: sns.Topic;
  public readonly taskQueue: sqs.Queue;

  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id, props);

    // API Gateway REST API
    this.restApi = new apigateway.RestApi(this, 'RestApi', {
      restApiName: 'OvaFlus API',
      description: 'OvaFlus Finance App REST API',
      deployOptions: {
        stageName: 'v1',
        tracingEnabled: true,
        metricsEnabled: true,
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization', 'X-Api-Key'],
      },
    });

    // Usage Plan with throttling
    const usagePlan = this.restApi.addUsagePlan('UsagePlan', {
      name: 'OvaFlus-Standard',
      throttle: {
        rateLimit: 1000,
        burstLimit: 10000,
      },
      quota: {
        limit: 1000000,
        period: apigateway.Period.MONTH,
      },
    });

    const apiKey = this.restApi.addApiKey('ApiKey', {
      apiKeyName: 'ovaflus-api-key',
    });
    usagePlan.addApiKey(apiKey);
    usagePlan.addApiStage({ stage: this.restApi.deploymentStage });

    // AppSync GraphQL API with Cognito auth
    this.graphqlApi = new appsync.CfnGraphQLApi(this, 'GraphqlApi', {
      name: 'OvaFlus-GraphQL',
      authenticationType: 'AMAZON_COGNITO_USER_POOLS',
      userPoolConfig: {
        userPoolId: cdk.Fn.importValue('UserPoolId'),
        awsRegion: this.region,
        defaultAction: 'ALLOW',
      },
      xrayEnabled: true,
    });

    // Lambda for Receipt OCR (Textract integration)
    const ocrFunction = new lambda.Function(this, 'ReceiptOcrFunction', {
      functionName: 'ovaflus-receipt-ocr',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const { TextractClient, AnalyzeExpenseCommand } = require('@aws-sdk/client-textract');

        exports.handler = async (event) => {
          const textract = new TextractClient({});
          const { bucket, key } = event;

          try {
            const command = new AnalyzeExpenseCommand({
              Document: {
                S3Object: { Bucket: bucket, Name: key },
              },
            });
            const result = await textract.send(command);
            return {
              statusCode: 200,
              body: JSON.stringify({ expenses: result.ExpenseDocuments }),
            };
          } catch (error) {
            return {
              statusCode: 500,
              body: JSON.stringify({ error: error.message }),
            };
          }
        };
      `),
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
    });

    // Grant Textract permissions
    ocrFunction.addToRolePolicy(
      new iam.PolicyStatement({
        actions: ['textract:AnalyzeExpense'],
        resources: ['*'],
      })
    );

    // SNS Topic for push notifications
    this.notificationTopic = new sns.Topic(this, 'NotificationTopic', {
      topicName: 'ovaflus-notifications',
      displayName: 'OvaFlus Push Notifications',
    });

    // SQS Queue for async task processing
    const deadLetterQueue = new sqs.Queue(this, 'TaskDLQ', {
      queueName: 'ovaflus-task-dlq',
      retentionPeriod: cdk.Duration.days(14),
    });

    this.taskQueue = new sqs.Queue(this, 'TaskQueue', {
      queueName: 'ovaflus-task-queue',
      visibilityTimeout: cdk.Duration.seconds(300),
      retentionPeriod: cdk.Duration.days(7),
      deadLetterQueue: {
        queue: deadLetterQueue,
        maxReceiveCount: 3,
      },
    });

    // Outputs
    new cdk.CfnOutput(this, 'RestApiUrl', { value: this.restApi.url });
    new cdk.CfnOutput(this, 'GraphqlApiId', { value: this.graphqlApi.attrApiId });
    new cdk.CfnOutput(this, 'NotificationTopicArn', { value: this.notificationTopic.topicArn });
    new cdk.CfnOutput(this, 'TaskQueueUrl', { value: this.taskQueue.queueUrl });
  }
}

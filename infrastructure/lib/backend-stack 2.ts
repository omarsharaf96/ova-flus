import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { DatabaseTables } from './database-stack';

interface BackendStackProps extends cdk.StackProps {
  tables: DatabaseTables;
}

export class BackendStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: BackendStackProps) {
    super(scope, id, props);

    const { tables } = props;

    // S3 bucket for Lambda deployment artifacts
    const artifactBucket = s3.Bucket.fromBucketName(this, 'LambdaArtifacts', 'ovaflus-lambda-artifacts');

    // SSM Parameters — values set via CDK context or replaced post-deploy
    new ssm.StringParameter(this, 'JwtSecret', {
      parameterName: '/ovaflus/prod/jwt-secret',
      stringValue: this.node.tryGetContext('jwtSecret') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'JWT signing secret',
    });

    new ssm.StringParameter(this, 'PlaidClientId', {
      parameterName: '/ovaflus/prod/plaid-client-id',
      stringValue: this.node.tryGetContext('plaidClientId') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid client ID',
    });

    new ssm.StringParameter(this, 'PlaidSecret', {
      parameterName: '/ovaflus/prod/plaid-secret',
      stringValue: this.node.tryGetContext('plaidSecret') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid secret key',
    });

    new ssm.StringParameter(this, 'PlaidEnv', {
      parameterName: '/ovaflus/prod/plaid-env',
      stringValue: this.node.tryGetContext('plaidEnv') ?? 'sandbox',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid environment',
    });

    new ssm.StringParameter(this, 'FinnhubApiKey', {
      parameterName: '/ovaflus/prod/finnhub-api-key',
      stringValue: this.node.tryGetContext('finnhubApiKey') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Finnhub API key',
    });

    // Lambda function
    const fn = new lambda.Function(this, 'BackendFunction', {
      functionName: 'ovaflus-backend',
      runtime: lambda.Runtime.PROVIDED_AL2023,
      architecture: lambda.Architecture.ARM_64,
      handler: 'bootstrap',
      code: lambda.Code.fromBucket(artifactBucket, 'ovaflus-backend.zip'),
      memorySize: 256,
      timeout: cdk.Duration.seconds(30),
      environment: {
        RUST_LOG: 'info',
      },
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    // Grant DynamoDB access
    Object.values(tables).forEach(table => table.grantReadWriteData(fn));

    // Grant SSM read access
    fn.addToRolePolicy(new iam.PolicyStatement({
      actions: ['ssm:GetParameter', 'ssm:GetParameters'],
      resources: [`arn:aws:ssm:${this.region}:${this.account}:parameter/ovaflus/*`],
    }));

    // API Gateway HTTP API
    const accessLogs = new logs.LogGroup(this, 'ApiGatewayLogs', {
      logGroupName: '/aws/apigateway/ovaflus-api',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const httpApi = new apigwv2.HttpApi(this, 'HttpApi', {
      apiName: 'ovaflus-api',
      corsPreflight: {
        allowOrigins: ['*'],
        allowMethods: [apigwv2.CorsHttpMethod.ANY],
        allowHeaders: ['Content-Type', 'Authorization'],
      },
      defaultIntegration: new integrations.HttpLambdaIntegration('LambdaIntegration', fn),
    });

    // Access logging on default stage
    const cfnStage = httpApi.defaultStage?.node.defaultChild as apigwv2.CfnStage;
    cfnStage.accessLogSettings = {
      destinationArn: accessLogs.logGroupArn,
      format: JSON.stringify({
        requestId: '$context.requestId',
        sourceIp: '$context.identity.sourceIp',
        requestTime: '$context.requestTime',
        httpMethod: '$context.httpMethod',
        routeKey: '$context.routeKey',
        status: '$context.status',
        responseLength: '$context.responseLength',
        integrationLatency: '$context.integrationLatency',
      }),
    };

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      description: 'API Gateway endpoint URL',
      exportName: 'FlusApiUrl',
    });

    new cdk.CfnOutput(this, 'LambdaArn', {
      value: fn.functionArn,
      description: 'Lambda function ARN',
    });
  }
}

import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as integrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
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
    new ssm.StringParameter(this, 'PlaidClientId', {
      parameterName: '/ovaflus/plaid_client_id',
      stringValue: this.node.tryGetContext('plaidClientId') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid client ID',
    });

    new ssm.StringParameter(this, 'PlaidSecret', {
      parameterName: '/ovaflus/plaid_secret',
      stringValue: this.node.tryGetContext('plaidSecret') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid secret key',
    });

    new ssm.StringParameter(this, 'PlaidEnv', {
      parameterName: '/ovaflus/plaid_env',
      stringValue: this.node.tryGetContext('plaidEnv') ?? 'sandbox',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Plaid environment',
    });

    new ssm.StringParameter(this, 'FinnhubApiKey', {
      parameterName: '/ovaflus/finnhub_api_key',
      stringValue: this.node.tryGetContext('finnhubApiKey') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Finnhub API key',
    });

    new ssm.StringParameter(this, 'NonceSecret', {
      parameterName: '/ovaflus/nonce_secret',
      stringValue: this.node.tryGetContext('nonceSecret') ?? 'REPLACE_ME_NONCE_SECRET',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Shared HMAC secret for Cognito custom auth challenge nonce',
    });

    new ssm.StringParameter(this, 'AppleTeamId', {
      parameterName: '/ovaflus/apple_team_id',
      stringValue: this.node.tryGetContext('appleTeamId') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Apple Developer Team ID',
    });

    new ssm.StringParameter(this, 'AppleKeyId', {
      parameterName: '/ovaflus/apple_key_id',
      stringValue: this.node.tryGetContext('appleKeyId') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Apple Sign In with Apple Key ID',
    });

    new ssm.StringParameter(this, 'ApplePrivateKey', {
      parameterName: '/ovaflus/apple_private_key',
      stringValue: this.node.tryGetContext('applePrivateKey') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Apple private key (.p8 contents) for Sign In with Apple',
    });

    new ssm.StringParameter(this, 'GoogleClientId', {
      parameterName: '/ovaflus/google_client_id',
      stringValue: this.node.tryGetContext('googleClientId') ?? 'REPLACE_ME',
      tier: ssm.ParameterTier.STANDARD,
      description: 'Google OAuth 2.0 Client ID for iOS',
    });

    // Cognito User Pool
    const userPool = new cognito.UserPool(this, 'UserPool', {
      userPoolName: 'ovaflus-users',
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      standardAttributes: {
        email: { required: true, mutable: true },
        fullname: { required: false, mutable: true },
      },
      passwordPolicy: {
        minLength: 8,
        requireUppercase: true,
        requireDigits: true,
        requireLowercase: false,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Custom Auth Challenge Lambdas (for native Apple/Google sign-in flow)
    const defineAuthChallengeFn = new lambda.Function(this, 'DefineAuthChallenge', {
      functionName: 'ovaflus-define-auth-challenge',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
exports.handler = async (event) => {
  const sessions = event.request.session || [];
  if (sessions.length === 0) {
    event.response.challengeName = 'CUSTOM_CHALLENGE';
    event.response.issueTokens = false;
    event.response.failAuthentication = false;
  } else if (sessions.length === 1 && sessions[0].challengeResult === true) {
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
  } else {
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
  }
  return event;
};
      `),
      timeout: cdk.Duration.seconds(5),
    });

    const createAuthChallengeFn = new lambda.Function(this, 'CreateAuthChallenge', {
      functionName: 'ovaflus-create-auth-challenge',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
exports.handler = async (event) => {
  event.response.publicChallengeParameters = {};
  event.response.privateChallengeParameters = {};
  event.response.challengeMetadata = 'CUSTOM_NONCE_CHALLENGE';
  return event;
};
      `),
      timeout: cdk.Duration.seconds(5),
    });

    const verifyAuthChallengeFn = new lambda.Function(this, 'VerifyAuthChallenge', {
      functionName: 'ovaflus-verify-auth-challenge',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
const crypto = require('crypto');
exports.handler = async (event) => {
  const answer = event.request.challengeAnswer;
  const secret = process.env.NONCE_SECRET;
  const username = event.request.userAttributes.email;
  // Answer format: "timestamp:hmac"
  const [ts, hmac] = (answer || '').split(':');
  const now = Math.floor(Date.now() / 1000);
  const tsNum = parseInt(ts, 10);
  if (isNaN(tsNum) || Math.abs(now - tsNum) > 120) {
    event.response.answerCorrect = false;
    return event;
  }
  const expected = crypto.createHmac('sha256', secret).update(username + ':' + ts).digest('hex');
  event.response.answerCorrect = crypto.timingSafeEqual(
    Buffer.from(hmac || '', 'hex'),
    Buffer.from(expected, 'hex')
  );
  return event;
};
      `),
      timeout: cdk.Duration.seconds(5),
      environment: {
        NONCE_SECRET: this.node.tryGetContext('nonceSecret') ?? 'REPLACE_ME_NONCE_SECRET',
      },
    });

    // Add Cognito triggers
    userPool.addTrigger(cognito.UserPoolOperation.DEFINE_AUTH_CHALLENGE, defineAuthChallengeFn);
    userPool.addTrigger(cognito.UserPoolOperation.CREATE_AUTH_CHALLENGE, createAuthChallengeFn);
    userPool.addTrigger(cognito.UserPoolOperation.VERIFY_AUTH_CHALLENGE_RESPONSE, verifyAuthChallengeFn);

    // iOS App Client
    const userPoolClient = userPool.addClient('iOSClient', {
      userPoolClientName: 'ovaflus-ios',
      authFlows: {
        userSrp: true,
        custom: true,
        adminUserPassword: true,
      },
      generateSecret: false,
      accessTokenValidity: cdk.Duration.hours(1),
      idTokenValidity: cdk.Duration.hours(1),
      refreshTokenValidity: cdk.Duration.days(30),
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
        COGNITO_USER_POOL_ID: userPool.userPoolId,
        COGNITO_APP_CLIENT_ID: userPoolClient.userPoolClientId,
        COGNITO_REGION: this.region,
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

    // Grant Cognito admin API access
    fn.addToRolePolicy(new iam.PolicyStatement({
      actions: [
        'cognito-idp:AdminCreateUser',
        'cognito-idp:AdminGetUser',
        'cognito-idp:AdminSetUserPassword',
        'cognito-idp:AdminInitiateAuth',
        'cognito-idp:AdminRespondToAuthChallenge',
      ],
      resources: [userPool.userPoolArn],
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

    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'Cognito User Pool ID',
      exportName: 'FlusUserPoolId',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'Cognito App Client ID',
      exportName: 'FlusUserPoolClientId',
    });
  }
}

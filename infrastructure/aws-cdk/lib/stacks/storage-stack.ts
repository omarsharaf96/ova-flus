import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export class StorageStack extends cdk.Stack {
  public readonly receiptsBucket: s3.Bucket;
  public readonly reportsBucket: s3.Bucket;
  public readonly backupsBucket: s3.Bucket;
  public readonly webAssetsBucket: s3.Bucket;
  public readonly distribution: cloudfront.Distribution;

  constructor(scope: Construct, id: string, props: cdk.StackProps) {
    super(scope, id, props);

    // Receipts bucket - versioned, lifecycle to Glacier after 1 year
    this.receiptsBucket = new s3.Bucket(this, 'ReceiptsBucket', {
      bucketName: `ovaflus-receipts-${this.account}`,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          transitions: [
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(365),
            },
          ],
        },
      ],
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Reports bucket - lifecycle delete after 90 days
    this.reportsBucket = new s3.Bucket(this, 'ReportsBucket', {
      bucketName: `ovaflus-reports-${this.account}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          expiration: cdk.Duration.days(90),
        },
      ],
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Backups bucket - lifecycle to Glacier after 30 days
    this.backupsBucket = new s3.Bucket(this, 'BackupsBucket', {
      bucketName: `ovaflus-backups-${this.account}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          transitions: [
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(30),
            },
          ],
        },
      ],
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Web assets bucket for static hosting via CloudFront
    this.webAssetsBucket = new s3.Bucket(this, 'WebAssetsBucket', {
      bucketName: `ovaflus-web-assets-${this.account}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // CloudFront distribution with OAC
    this.distribution = new cloudfront.Distribution(this, 'Distribution', {
      defaultBehavior: {
        origin: origins.S3BucketOrigin.withOriginAccessControl(this.webAssetsBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      additionalBehaviors: {
        '/receipts/*': {
          origin: origins.S3BucketOrigin.withOriginAccessControl(this.receiptsBucket),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
          cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        },
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
          ttl: cdk.Duration.seconds(0),
        },
      ],
    });

    // Outputs
    new cdk.CfnOutput(this, 'ReceiptsBucketName', { value: this.receiptsBucket.bucketName });
    new cdk.CfnOutput(this, 'ReportsBucketName', { value: this.reportsBucket.bucketName });
    new cdk.CfnOutput(this, 'BackupsBucketName', { value: this.backupsBucket.bucketName });
    new cdk.CfnOutput(this, 'WebAssetsBucketName', { value: this.webAssetsBucket.bucketName });
    new cdk.CfnOutput(this, 'DistributionDomainName', { value: this.distribution.distributionDomainName });
  }
}

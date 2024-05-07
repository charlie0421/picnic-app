import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as route53 from "aws-cdk-lib/aws-route53";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as origins from "aws-cdk-lib/aws-cloudfront-origins";
import { Certificate } from "aws-cdk-lib/aws-certificatemanager";
import { CfnOriginAccessControl } from "aws-cdk-lib/aws-cloudfront";
import { Bucket } from "aws-cdk-lib/aws-s3";
import { aws_iam } from "aws-cdk-lib";
import { Lambda } from "aws-sdk";

export class ImageResizeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, {
      env: {
        account: process.env.CDK_DEFAULT_ACCOUNT,
        region: process.env.CDK_DEFAULT_REGION,
      },
      ...props,
    });

    const bucket = Bucket.fromBucketName(this, 'bucket', this.node.tryGetContext("BUCKET_NAME"));

    // // Lambda@Edge 함수 생성
    // const resizingFunction = new lambda.Function(
    //   this,
    //   "ImageResizingFunction",
    //   {
    //     runtime: lambda.Runtime.NODEJS_18_X, // 런타임 지정
    //     handler: "index.handler", // 핸들러 함수
    //     code: lambda.Code.fromAsset("./lambdas.zip"),
    //     currentVersionOptions: {
    //       removalPolicy: cdk.RemovalPolicy.DESTROY,
    //     },
    //   },
    // );

    // CloudFront 배포 생성
    const distribution = new cloudfront.Distribution(this, "MyDistribution", {
      defaultBehavior: {
        origin: new origins.S3Origin(bucket),
        // edgeLambdas: [
        //   {
        //     functionVersion: resizingFunction.currentVersion,
        //     eventType: cloudfront.LambdaEdgeEventType.VIEWER_REQUEST, // 람다 실행 타이밍
        //   },
        // ],
      },
      domainNames: [this.node.tryGetContext("CLOUDFRONT_DOMAIN_NAME")],
      certificate: Certificate.fromCertificateArn(
        this,
        "Certificate",
        this.node.tryGetContext("CLOUDFRONT_CERTIFICATE_ARN"),
      ),
    });

    const aRecord = new route53.CnameRecord(this, "CnameRecord", {

      zone: route53.HostedZone.fromLookup(this, "HostedZone", {
        domainName: this.node.tryGetContext("HOSTED_DOMAIN_NAME"),
        privateZone: false,

      }),
      recordName: this.node.tryGetContext("CLOUDFRONT_DOMAIN_NAME"),
      domainName: distribution.domainName,
    });
  }
}

const app = new cdk.App();
new ImageResizeStack(app, "ImageResizingStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});

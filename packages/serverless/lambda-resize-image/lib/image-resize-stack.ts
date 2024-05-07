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

export class LambdaResizeImage extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, {
      env: {
        account: process.env.CDK_DEFAULT_ACCOUNT,
        region: process.env.CDK_DEFAULT_REGION,
      },
      ...props,
    });

    // Lambda@Edge 함수 생성
    const resizingFunction = new lambda.Function(
      this,
      "ImageResizingFunction",
      {
        runtime: lambda.Runtime.NODEJS_18_X, // 런타임 지정
        handler: "index.handler", // 핸들러 함수
        code: lambda.Code.fromAsset("./lambda"),
        currentVersionOptions: {
          removalPolicy: cdk.RemovalPolicy.DESTROY,
        },
      },
    );
  }
}
const app = new cdk.App();
new LambdaResizeImage(app, "LambdaResizeImage", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});

import * as cdk from "aws-cdk-lib";
import {Construct} from "constructs";
import * as iam from "aws-cdk-lib/aws-iam";
import * as elbv2 from "aws-cdk-lib/aws-elasticloadbalancingv2";
import {
    ApplicationProtocol,
    ApplicationProtocolVersion,
    IApplicationListener,
    TargetType
} from "aws-cdk-lib/aws-elasticloadbalancingv2";
import {ICluster} from "aws-cdk-lib/aws-ecs";
import ec2 = require("aws-cdk-lib/aws-ec2");
import ecs = require("aws-cdk-lib/aws-ecs");

export class EcsStack extends cdk.Stack {
    private stack: cdk.Stack;
    private vpc: ec2.IVpc;
    private listener: IApplicationListener;
    private cluster: ICluster;

    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        const app = new cdk.App();
        this.createStack();
        this.lookupVPC();
        this.lookupListener();
        this.lookupCluster();

        const paths = [
            {name: "user", path: "/user/", database: 'picnic'},
            {name: "auth", path: "/auth/", database: 'picnic'},
        ];

        const targetGroups = this.createTargetGroups(paths);
        this.addListenerToTargetGroups(paths, targetGroups);
        this.createTasksAndServices(paths, targetGroups);
    };

    private createStack() {
        this.stack = new cdk.Stack(new cdk.App(), "picnic-ecs-dev-stack", {
            env: {
                account: "851725635868",
                region: "ap-northeast-2",
            },
        });
    }

    private lookupVPC() {
        this.vpc = ec2.Vpc.fromLookup(this.stack, "vpc-0bb0bb777c7afbd7c", {
            isDefault: false,
        });
    }

    private lookupListener() {
        this.listener = elbv2.ApplicationListener.fromLookup(this.stack, "dev-alb-listener", {
            listenerArn: "arn:aws:elasticloadbalancing:ap-northeast-2:851725635868:listener/app/picnic-dev-alb/15b5a4b48d0365f7/28a99a191be7ca7b",
        });
    }

    private lookupCluster() {
        this.cluster = ecs.Cluster.fromClusterAttributes(this.stack, "dev-cluster", {
            clusterName: "picnic-dev-cluster",
            vpc: this.vpc,
        });
    }

    private createTargetGroups(paths: any[]) {
        return paths.map((path) => {
            return new elbv2.ApplicationTargetGroup(this.stack, `${path.name}-targetgroup`, {
                vpc: this.vpc,
                targetGroupName: `picnic-dev-api-${path.name}-tg`,
                protocol: ApplicationProtocol.HTTP,
                port: 80,
                protocolVersion: ApplicationProtocolVersion.HTTP1,
                targetType: TargetType.INSTANCE,
                healthCheck: {
                    path: path.path,
                    healthyHttpCodes: "200,301",
                },
            });
        });
    }

    private addListenerToTargetGroups(paths: any[], targetGroups: any[]) {
        paths.forEach((path, index) => {
            this.listener.addTargetGroups(`${path.name}-target-group`, {
                targetGroups: [targetGroups[index]],
                conditions: [
                    elbv2.ListenerCondition.hostHeaders(["api-dev.picnic.fan"]),
                    elbv2.ListenerCondition.pathPatterns([`${path.path}*`]),
                ],
                priority: index + 1,
            });
        });
    }

    private createTasksAndServices(paths: any[], targetGroups: any[]) {
        paths.forEach((path, index) => {

            const taskDefinition = new ecs.Ec2TaskDefinition(
                this.stack,
                `picnic-dev-api-${path.name}-td`,
                {
                    family: `picnic-dev-api-${path.name}-td`,
                    taskRole: iam.Role.fromRoleArn(
                        this.stack,
                        `ecs${path.name}TaskExecutionRole-1`,
                        "arn:aws:iam::851725635868:role/ecsTaskExecutionRole",
                    ),
                    executionRole: iam.Role.fromRoleArn(
                        this.stack,
                        `ecs${path.name}TaskExecutionRole-2`,
                        "arn:aws:iam::851725635868:role/ecsTaskExecutionRole",
                    ),
                },
            );

            taskDefinition.addContainer(`picnic-dev-api-${path.name}-container`, {
                image: ecs.ContainerImage.fromRegistry(
                    `851725635868.dkr.ecr.ap-northeast-2.amazonaws.com/picnic-dev-api-${path.name}-service:latest`,
                ),

                healthCheck: {
                    command: ["CMD-SHELL", `curl -f http://localhost:${7100 + index}/${path.name} || exit 1`],
                    interval: cdk.Duration.seconds(30),
                    timeout: cdk.Duration.seconds(5),
                    retries: 3,
                    startPeriod: cdk.Duration.seconds(60),
                },
                memoryReservationMiB: 300,
                portMappings: [
                    {
                        hostPort: 0,
                        containerPort: 7100 + index,
                        protocol: ecs.Protocol.TCP,
                    },
                ],
                environment: commonEnvironment,
                disableNetworking: false,
                entryPoint: ["sh", "-c", `pwd; node ${path.name}/dist/${path.name}/src/main`],
                workingDirectory: `/usr/src/app`,
                logging: ecs.LogDrivers.awsLogs({
                    streamPrefix: "picnic-dev-api",
                }),
            });

            const service = new ecs.Ec2Service(this.stack, `${path.name}-service`, {
                cluster: this.cluster,
                taskDefinition: taskDefinition,
                desiredCount: 1,
                serviceName: `picnic-dev-api-${path.name}-service`,
                enableExecuteCommand: true,
            });
            service.attachToApplicationTargetGroup(targetGroups[index]);
        });
    }

};

const commonEnvironment = {
    ACCESS_TOKEN_EXPIRES_IN: "1M",
    API_AUTH_ROOT: "https://api-dev.picnic.fan/auth",
    API_USER_ROOT: "https://api-dev.picnic.fan/user",
    AWS_ACCESS_KEY: "AKIA4MTWN2EOHQLM2CVX",
    AWS_REGION: "ap-northeast-2",
    AWS_SECRET_ACCESS_KEY: "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",
    CDN_URL: "https://cdn-dev.picnic.fan",
    DATABASE_BIG_NUMBER_STRINGS: "true",
    DATABASE_CONNECTION_LIMIT: "2",
    DATABASE_DATABASE_NAME: "picnic",
    DATABASE_HOST_RO: "dev-db.picnic.fan",
    DATABASE_HOST_RW: "dev-db.picnic.fan",
    DATABASE_ADMIN_PASSWORD: 'tkffudigksek1!',
    DATABASE_ADMIN_USER: 'admin',
    DATABASE_LOGGING: "true",
    DATABASE_PORT: "3306",
    DATABASE_SUPPORT_BIG_NUMBERS: "true",
    DATABASE_SYNCHRONIZE: "true",
    ENVIRONMENT: "dev",
    ISSUER: "picnic",
    JWT_SECRET: "47cdf605af23fa0daaf4f85a19452ed9378522ab586452d7cda002387bc050c48b43467790102c1865ad07325fa018867baafc7540298a388ae64c8ed94ca282",
    REFRESH_TOKEN_EXPIRES_IN: "31536000s",
    RESET_PASSWORD_TOKEN_EXPIRES_IN: "3600s",
    S3_BUCKET_NAME: "picnic-dev",
};

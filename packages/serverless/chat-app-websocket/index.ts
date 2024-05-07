#!/usr/bin/env node
import {AssetCode, Function, Runtime} from "aws-cdk-lib/aws-lambda";
import {CfnApi, CfnDeployment, CfnIntegration, CfnRoute, CfnStage} from "aws-cdk-lib/aws-apigatewayv2";
import {App, Duration, RemovalPolicy, Stack, StackProps} from 'aws-cdk-lib';
import {Effect, PolicyStatement, Role, ServicePrincipal} from "aws-cdk-lib/aws-iam";
import {AttributeType, Table} from "aws-cdk-lib/aws-dynamodb";
import {Construct} from 'constructs';

const config = {
    "stage": "dev",
    "region": "ap-northeast-2",
    "account_id": "355508260517"
}
class ChatAppStack extends Stack {
    constructor(scope: Construct, id: string, props?: StackProps) {
        super(scope, id, props);
        const connectionsTableName = "chat_connections";
        const membersTableName = "chat_members";
        const messagesTableName = "chat_messages";

        // initialise api
        const name = id + "-api"
        const api = new CfnApi(this, name, {
            name: "chat-app-websocket",
            protocolType: "WEBSOCKET",
            routeSelectionExpression: "$request.body.action",
        });

        //////////////////////////////////////////
        // TABLES
        //////////////////////////////////////////
        const connectionsTable = new Table(this, `${name}-table-connections`, {
            tableName: connectionsTableName,
            partitionKey: {
                name: "connectionId",
                type: AttributeType.STRING,
            },
            readCapacity: 5,
            writeCapacity: 5,
            removalPolicy: RemovalPolicy.DESTROY
        });

        connectionsTable.addGlobalSecondaryIndex({
            indexName: "connections-roodId-index",
            partitionKey: {
                name: "roomId",
                type: AttributeType.STRING,
            },
            readCapacity: 5,
            writeCapacity: 5,
        });

        const messagesTable = new Table(this, `${name}-table-messages`, {
            tableName: messagesTableName,
            partitionKey: {
                name: "roomId",
                type: AttributeType.STRING,
            },
            sortKey: {
                name: "createdAt",
                type: AttributeType.NUMBER,
            },
            readCapacity: 5,
            writeCapacity: 5,
            removalPolicy: RemovalPolicy.DESTROY
        });

        //////////////////////////////////////////
        // LAMBDA FUNCTIONS
        //////////////////////////////////////////

        const connectFunc = new Function(this, 'connect-lambda', {
            code: new AssetCode('./onconnect'),
            handler: 'connect.handler',
            runtime: Runtime.NODEJS_18_X,
            timeout: Duration.seconds(300),
            memorySize: 256,
            environment: {
                "TABLE_NAME": connectionsTableName,
            }
        });

        connectionsTable.grantReadWriteData(connectFunc)


        const disconnectFunc = new Function(this, 'disconnect-lambda', {
            code: new AssetCode('./ondisconnect'),
            handler: 'disconnect.handler',
            runtime: Runtime.NODEJS_18_X,
            timeout: Duration.seconds(300),
            memorySize: 256,
            environment: {
                "TABLE_NAME": connectionsTableName,
            }
        });

        connectionsTable.grantReadWriteData(disconnectFunc)

        const messageFunc = new Function(this, 'message-lambda', {
            code: new AssetCode('./sendmessage'),
            handler: 'sendmessage.handler',
            runtime: Runtime.NODEJS_18_X,
            timeout: Duration.seconds(300),
            memorySize: 256,
            initialPolicy: [
                new PolicyStatement({
                    actions: [
                        'execute-api:ManageConnections'
                    ],
                    resources: [
                        "arn:aws:execute-api:" + config["region"] + ":" + config["account_id"] + ":" + api.ref + "/*"
                    ],
                    effect: Effect.ALLOW,
                })
            ],
            environment: {
                "MEMBERS_TABLE_NAME": membersTableName,
                "MESSAGES_TABLE_NAME": messagesTableName,
                "CONNECTIONS_TABLE_NAME": connectionsTableName,
            }
        });

        messagesTable.grantReadWriteData(messageFunc)
        connectionsTable.grantReadWriteData(messageFunc)

        // access role for the socket api to access the socket lambda
        const policy = new PolicyStatement({
            effect: Effect.ALLOW,
            resources: [
                connectFunc.functionArn,
                disconnectFunc.functionArn,
                messageFunc.functionArn
            ],
            actions: ["lambda:InvokeFunction"]
        });

        const role = new Role(this, `${name}-iam-role`, {
            assumedBy: new ServicePrincipal("apigateway.amazonaws.com")
        });
        role.addToPolicy(policy);

        //////////////////////////////////////////
        // LAMBDA INTEGRATIONS
        //////////////////////////////////////////
        const connectIntegration = new CfnIntegration(this, "connect-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + connectFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn,
        })
        const disconnectIntegration = new CfnIntegration(this, "disconnect-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + disconnectFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn
        })
        const messageIntegration = new CfnIntegration(this, "message-lambda-integration", {
            apiId: api.ref,
            integrationType: "AWS_PROXY",
            integrationUri: "arn:aws:apigateway:" + config["region"] + ":lambda:path/2015-03-31/functions/" + messageFunc.functionArn + "/invocations",
            credentialsArn: role.roleArn
        })

        //////////////////////////////////////////
        // CONNECTIONS ROUTES
        //////////////////////////////////////////
        const connectRoute = new CfnRoute(this, "connect-route", {
            apiId: api.ref,
            routeKey: "$connect",
            authorizationType: "NONE",
            target: "integrations/" + connectIntegration.ref,
        });

        const disconnectRoute = new CfnRoute(this, "disconnect-route", {
            apiId: api.ref,
            routeKey: "$disconnect",
            authorizationType: "NONE",
            target: "integrations/" + disconnectIntegration.ref,
        });

        const messageRoute = new CfnRoute(this, "message-route", {
            apiId: api.ref,
            routeKey: "sendmessage",
            authorizationType: "NONE",
            target: "integrations/" + messageIntegration.ref,
        });
        //////////////////////////////////////////
        // DEPLOYMENT
        //////////////////////////////////////////

        const deployment = new CfnDeployment(this, `${name}-deployment`, {
            apiId: api.ref
        });

        new CfnStage(this, `${name}-stage`, {
            apiId: api.ref,
            autoDeploy: true,
            deploymentId: deployment.ref,
            stageName: "dev",
        });

        deployment.node.addDependency(connectRoute)
        deployment.node.addDependency(disconnectRoute)
        deployment.node.addDependency(messageRoute)

    }
}

const app = new App();
new ChatAppStack(app, `chat-app-websocket-stack`);
app.synth();
